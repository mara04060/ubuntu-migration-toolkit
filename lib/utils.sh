#!/usr/bin/env bash

check_root() {
    if [[ $EUID -ne 0 ]]; then
       log_error "Скрипт должен быть запущен с правами root (sudo)."
       exit 1
    fi
}

check_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log_info "Обнаружена ОС: $NAME $VERSION_ID"
        if [[ "$ID" != "ubuntu" ]]; then
            log_warn "Внимание: Операционная система не является Ubuntu!"
        fi
    else
        log_error "Не удалось определить версию ОС."
        exit 1
    fi
}

check_disk_space() {
    local path="$1"
    local required_gb="${2:-10}"
    mkdir -p "$path" 2>/dev/null || true
    local available_kb
    available_kb=$(df -k "$path" | tail -n1 | awk '{print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    log_info "Доступно места в $path: ${available_gb} GB (Требуется: ${required_gb} GB)"
    if [[ $available_gb -lt $required_gb ]]; then
        log_error "Недостаточно свободного места на диске!"
        exit 1
    fi
}

get_target_user() {
    if [[ -n "$SUDO_USER" ]]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

get_target_home() {
    local user
    user=$(get_target_user)
    eval echo "~$user"
}
