#!/usr/bin/env bash
# CI/CD pipeline

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Establish the project root directory
if [ -z "${PROJECT_ROOT:-}" ]; then
    PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
    export PROJECT_ROOT
fi

source "$PROJECT_ROOT/.ci/lib/environment.sh"

# Ensure that the pipeline runs with an isolated environment, only containing
# the allowed env vars.
Environment::isolate "$@"

source "$PROJECT_ROOT/.ci/lib/semver.sh"
source "$PROJECT_ROOT/.ci/lib/logging.sh"
source "$PROJECT_ROOT/.ci/lib/notifications.sh"

log_stage_start "Configure pipeline"
if ! source "$PROJECT_ROOT/.ci/step/1a-configure-pipeline.sh"; then
    notify_failure "Pipeline configuration stage failed"
    exit 1
fi

log_stage_start "Semantic versioning"
if ! source "$PROJECT_ROOT/.ci/step/1b-versioning.sh"; then
    notify_failure "Versioning stage failed"
    exit 1
fi

log_stage_start "Configure build"
if ! source "$PROJECT_ROOT/.ci/step/1c-configure-build.sh"; then
    notify_failure "Build configuration stage failed"
    exit 1
fi

log_stage_start "Configure deployment"
if ! source "$PROJECT_ROOT/.ci/step/1d-configure-deployment.sh"; then
    notify_failure "Deployment configuration stage failed"
    exit 1
fi

# Execute pipeline stages

log_stage_start "Build"
if ! source "$PROJECT_ROOT/.ci/step/2-build.sh"; then
    notify_failure "Build stage failed"
    exit 1
fi

log_stage_start "Test"
if ! source "$PROJECT_ROOT/.ci/step/3-test.sh"; then
    notify_failure "Test stage failed"
    exit 1
fi

log_stage_start "Static analysis"
if ! source "$PROJECT_ROOT/.ci/step/4-static-analysis.sh"; then
    notify_failure "Static analysis failed"
    exit 1
fi

log_stage_start "Package"
if ! source "$PROJECT_ROOT/.ci/step/5-package.sh"; then
    notify_failure "Package stage failed"
    exit 1
fi

log_stage_start "Deploy to staging"
if ! source "$PROJECT_ROOT/.ci/step/6-deploy-to-staging.sh"; then
    notify_failure "Deploy to staging environment failed"
    exit 1
fi

log_stage_start "Integration testing"
if ! source "$PROJECT_ROOT/.ci/step/7-integration-test.sh"; then
    notify_failure "Integration testing failed"
    exit 1
fi

log_stage_start "Deploy to production"
if [ "${AUTO_DEPLOY_PRODUCTION}" = "true" ]; then
    if ! source "$PROJECT_ROOT/.ci/step/8-deploy-to-production.sh"; then
        notify_failure "Deploy to production failed"
        exit 1
    fi
else
    log_info "Skipping deploy to production for $APP_NAME $BUILD_VERSION."
    log_info "Must use 'AUTO_DEPLOY_PRODUCTION=true' for this deployment to happen."
fi

log_info "CD pipeline completed successfully"
notify_success
