#!/usr/bin/env bash
# Logging utilities

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

# Define color codes
if [ -t 1 ] && [ -t 2 ] && command -v tput >/dev/null 2>&1; then
    # Terminal supports colors
    RESET=$(tput sgr0)
    BOLD=$(tput bold)
    INFO_COLOR=$(tput setaf 4)    # Blue
    ERROR_COLOR=$(tput setaf 1)   # Red
    WARNING_COLOR=$(tput setaf 3) # Yellow
    STAGE_COLOR=$(tput setaf 2)   # Green
else
    # No color support
    RESET=""
    BOLD=""
    INFO_COLOR=""
    ERROR_COLOR=""
    WARNING_COLOR=""
    STAGE_COLOR=""
fi

log_info() {
    echo "${INFO_COLOR}[INFO]${RESET} $(date -u +"%Y-%m-%d %H:%M:%S UTC") - $1"
}

log_error() {
    echo "${ERROR_COLOR}${BOLD}[ERROR]${RESET} $(date -u +"%Y-%m-%d %H:%M:%S UTC") - $1" >&2
}

log_warning() {
    echo "${WARNING_COLOR}[WARNING]${RESET} $(date -u +"%Y-%m-%d %H:%M:%S UTC") - $1"
}

log_stage_start() {
    echo "${STAGE_COLOR}${BOLD}=== Starting '${1:-"pipeline"}' stage ===${RESET}"
}
