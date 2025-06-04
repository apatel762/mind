#!/usr/bin/env bash

# This snippet helps us find out who our actual $SELF is.
# Also it ensures that the script is sourced and never run directly.
(return 0 2>/dev/null)
SOURCED=$?
if [ $SOURCED -ne 0 ]; then
    echo "This script is intended to be sourced, not executed directly."
    exit 1
elif [ -n "${BASH_SOURCE[*]}" ]; then
    SOURCE_RELATIVE="${BASH_SOURCE[1]}"
else
    SOURCE_RELATIVE=$(caller 0 | awk '{print $2}')
fi
SELF=$(cd "$(dirname "$SOURCE_RELATIVE")" && pwd)/$(basename "$SOURCE_RELATIVE")
export SELF

# Set and export a variable as readonly and echo its value
# Environment::set FEATURE_FLAG 1
Environment::set() {
    local var_name="$1"
    local var_value="$2"

    export "$var_name"="$var_value"
    readonly "$var_name"
    echo "$var_name=$var_value"
}

# Set and export a secret variable as readonly and echo masked value
# Environment::secret API_KEY "my-secret-api-key"
Environment::secret() {
    local var_name="$1"
    local var_value="$2"

    export "$var_name"="$var_value"
    readonly "$var_name"
    echo "$var_name=*****"
}

# Run the script which sourced this file in an isolated environment.
# Environment::isolate "$@"
Environment::isolate() {
    if [[ -n "${ISOLATED_ENV:-}" ]]; then
        # If we're already in an isolated environment, do nothing
        return 0
    fi
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        echo "You must set PROJECT_ROOT before sourcing $0."
        return 1
    fi

    local script_path="$SELF"
    local isolate_path="$PROJECT_ROOT/.ci/lib/isolate.sh"

    # Check if isolate.sh exists and is executable
    if [[ ! -f "$isolate_path" ]]; then
        echo "Error: isolate.sh not found at $isolate_path" >&2
        exit 1
    fi
    if [[ ! -x "$isolate_path" ]]; then
        echo "Error: isolate.sh is not executable" >&2
        exit 1
    fi

    # Execute the isolate script with the current script as argument
    # This will not return - isolate.sh will re-execute the script
    # with the isolated environment
    exec "$isolate_path" "$script_path" "$@"
}
