#!/usr/bin/env bash
# Isolate a script, only allowing access to the allowed env vars.

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# These are the only variables that we will inject into the
# isolated environment. Anything with a default value should
# be in the format VAR=VALUE.
# And anything that will be passed in externally can simply
# be VAR, and VAR will be added to the isolated environment
# if it has a value.
ALLOWLIST=(
  "PATH=/usr/local/bin:/usr/bin:/bin"
  "TERM=${TERM:-}"
  "HOME=${HOME:-}"
  "CI_ENVIRONMENT"
  "GITHUB_TOKEN"
  "JAVA_HOME"
)

# If we're not in an isolated environment already...
if [[ -z "${ISOLATED_ENV:-}" ]]; then

  # Create an empty array. This will hold the environment variables that we want
  # to pass to the isolated environment.
  ENV_ARGS=()

  for var in "${ALLOWLIST[@]}"; do

    if [[ "$var" == *"="* ]]; then
      # For anything in our allowlist which contains an = sign, we will add the
      # variable to our environment as-is, with whatever hardcoded value was
      # provided.
      ENV_ARGS+=("$var")

    else
      # `var` contains an environment variable name, without an = sign after it.
      # Here, we will expand the value of `var` into the variable with the contained
      # name, and then check if that variable is non-empty. If so, we will put the
      # variable, and it's non-empty value into our new environment.
      var_name="$var"
      if [[ -n "${!var_name:-}" ]]; then
        ENV_ARGS+=("$var_name=${!var_name}")
      fi
    fi
  done

  ENV_ARGS+=("ISOLATED_ENV=1")

  # Validate the script path exists
  if [[ ! -f "$1" ]]; then
    echo "Error: Script '$1' not found" >&2
    exit 1
  fi

  SCRIPT_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  shift
  # Re-execute the target script with isolation
  exec env -i "${ENV_ARGS[@]}" bash "$SCRIPT_PATH" "$@"
fi

# If we get here, we're already isolated, so just run the script

if [[ -z "${1:-}" ]]; then
  echo "Error: No script specified" >&2
  exit 1
fi
if [[ ! -f "$1" ]]; then
  echo "Error: Script '$1' not found" >&2
  exit 1
fi

SCRIPT_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
shift
exec bash "$SCRIPT_PATH" "$@"
