#!/usr/bin/env bash
# Pipeline configuration

# ---------------------------------------------------------------------------
Environment::set APP_NAME "vagabond"

# ---------------------------------------------------------------------------
# Detect the environment that we are running in.
# "local" = we are running on a local machine, take care to only affect local machine
# "ci"    = we are running in CI; it's ok to modify deployments, push artifacts, etc
Environment::set CI_ENVIRONMENT "${CI_ENVIRONMENT:-local}"

if [[ "${CI_ENVIRONMENT}" != "ci" && "${CI_ENVIRONMENT}" != "local" ]]; then
  echo "ERROR: CI_ENVIRONMENT must be either 'ci' or 'local', got '${CI_ENVIRONMENT}'" >&2
  return 1
fi

# Helper functions for environment detection
# Usage examples:
#   if is_ci; then
#     echo "Running in CI environment"
#   fi
#   is_local && echo "Running locally"
is_ci() {
  [[ "${CI_ENVIRONMENT}" == "ci" ]]
}

is_local() {
  [[ "${CI_ENVIRONMENT}" == "local" ]]
}
