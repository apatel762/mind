#!/usr/bin/env bash
# Notification utilities

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

# ARGS: $1 = summary
#       $2 = message
notify() {
    if command -v notify-send > /dev/null
    then
        notify-send --app-name="CI" "$1" "$2"
    else
        echo "CI: [$1] $2"
    fi
}

notify_failure() {
    local stage="$1"
    notify \
      "CD pipeline failed for $APP_NAME" \
      "Pipeline failed at $stage stage for branch $CURRENT_GIT_BRANCH (commit $CURRENT_GIT_COMMIT)"
}

notify_success() {
    notify \
      "CD pipeline succeeded for $APP_NAME" \
      "Pipeline completed successfully on branch $CURRENT_GIT_BRANCH (commit $CURRENT_GIT_COMMIT)"
}
