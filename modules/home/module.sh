#!/usr/bin/env bash

module_home_backup() {
    local target="$1/home"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)
    mkdir -p "$target" 2>/dev/null || true

    log_info "Сохранение dotfiles и настроек из $user_home..."
    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Копирование .config, .local, dotfiles..."
        return 0
    fi

    tar --exclude="$user_home/.cache" \
        --exclude="$user_home/Downloads" \
        --exclude="$user_home/.local/share/Trash" \
        -czf "$target/user_home_config.tar.gz" \
        -C "$user_home" .config .local .bashrc .zshrc 2>/dev/null || true
}

module_home_restore() {
    local target="$1/home"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Распаковка настроек в $user_home..."
        return 0
    fi

    if [[ -f "$target/user_home_config.tar.gz" ]]; then
        tar -xzf "$target/user_home_config.tar.gz" -C "$user_home"
        chown -R "$(get_target_user):" "$user_home"
    fi
}
