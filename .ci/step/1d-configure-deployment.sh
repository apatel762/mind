#!/usr/bin/env bash
# Deployment configuration

# ---------------------------------------------------------------------------
# Automatic production deployment
if is_ci; then
  Environment::set AUTO_DEPLOY_PRODUCTION "true"
else
  Environment::set AUTO_DEPLOY_PRODUCTION "false"
fi

# ---------------------------------------------------------------------------
# Servers
Environment::set STAGING_SERVER "staging.example.com"
Environment::set PRODUCTION_SERVER "production.example.com"
Environment::set DEPLOY_USER "deployer"
