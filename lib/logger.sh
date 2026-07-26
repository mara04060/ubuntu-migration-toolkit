#!/usr/bin/env bash

LOG_FILE=""
VERBOSE=${VERBOSE:-0}

init_logger() {
    local log_dir="$1"
    mkdir -p "$log_dir" 2>/dev/null || true
    LOG_FILE="${log_dir}/migration_$(date +%Y%m%d_%H%M%S).log"
    touch "$LOG_FILE" 2>/dev/null || true
}

log_info() {
    local msg="[INFO] [$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "\e[32m$msg\e[0m"
    [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[WARN] [$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "\e[33m$msg\e[0m"
    [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] [$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "\e[31m$msg\e[0m" >&2
    [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE"
}

log_debug() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        local msg="[DEBUG] [$(date +'%Y-%m-%d %H:%M:%S')] $1"
        echo -e "\e[36m$msg\e[0m"
        [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]] && echo "$msg" >> "$LOG_FILE"
    fi
}
