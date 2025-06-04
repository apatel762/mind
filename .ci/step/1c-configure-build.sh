#!/usr/bin/env bash
# Build configuration

# ---------------------------------------------------------------------------
# Java/Maven
Environment::set JAVA_HOME "${JAVA_HOME:-"/usr/lib/jvm/java-21"}"

MVN_ARGS=("-Drevision=${BUILD_VERSION}")
if is_ci; then
    # Use batch mode in CI to prevent interactive prompts, and also to stop
    # progress bars from spamming the raw stdout stream (which makes it
    # very difficult to see what's going on in the CI server logs).
    MVN_ARGS+=("-B")
fi
Environment::set MVN_ARGS "${MVN_ARGS[@]}"

# ---------------------------------------------------------------------------
# Quality gates
Environment::set MAXIMUM_ALLOWED_BUGS 0
Environment::set MAXIMUM_ALLOWED_VULNERABILITIES 0