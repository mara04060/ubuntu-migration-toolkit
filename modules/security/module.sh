#!/usr/bin/env bash

module_security_backup() {
    local target="$1/security"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)
    mkdir -p "$target" 2>/dev/null || true

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Сохранение SSH, GPG, VPN ключей..."
        return 0
    fi

    if [[ -d "$user_home/.ssh" ]]; then
        cp -r "$user_home/.ssh" "$target/ssh_backup"
    fi

    if [[ -d "$user_home/.gnupg" ]]; then
        cp -r "$user_home/.gnupg" "$target/gnupg_backup"
    fi

    if [[ -d /etc/netplan ]]; then
        cp -r /etc/netplan "$target/netplan_backup" 2>/dev/null || true
    fi
}

module_security_restore() {
    local target="$1/security"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Восстановление SSH и security ключей..."
        return 0
    fi

    if [[ -d "$target/ssh_backup" ]]; then
        cp -r "$target/ssh_backup" "$user_home/.ssh"
        chmod 700 "$user_home/.ssh"
        chmod 600 "$user_home/.ssh"/* 2>/dev/null || true
        chown -R "$(get_target_user):" "$user_home/.ssh"
    fi
}
