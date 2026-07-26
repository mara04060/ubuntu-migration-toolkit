#!/usr/bin/env bash

module_system_backup() {
    local target="$1/system"
    local dry_run="$2"
    mkdir -p "$target" 2>/dev/null || true

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Сбор данных ОС, ядер, UID/GID, пользователей..."
        return 0
    fi

    lsb_release -a > "$target/ubuntu-version.txt" 2>/dev/null || true
    uname -a > "$target/kernel-info.txt" 2>/dev/null || true
    lshw -short > "$target/hardware-inventory.txt" 2>/dev/null || true
    
    cp /etc/passwd "$target/passwd.bak" 2>/dev/null || true
    cp /etc/group "$target/group.bak" 2>/dev/null || true
    cp /etc/shadow "$target/shadow.bak" 2>/dev/null || true
    cp /etc/sudoers "$target/sudoers.bak" 2>/dev/null || true
}

module_system_restore() {
    local target="$1/system"
    local dry_run="$2"
    log_info "Восстановление системных пользователей требует ручной проверки файлов $target/*.bak"
}
