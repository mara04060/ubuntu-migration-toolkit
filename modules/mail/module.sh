#!/usr/bin/env bash

module_mail_backup() {
    local target="$1/mail"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)
    mkdir -p "$target" 2>/dev/null || true

    log_info "Запуск резервного копирования почтовых клиентов..."

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Поиск и архивация профилей Thunderbird, Betterbird и Evolution..."
        return 0
    fi

    # 1. Mozilla Thunderbird (~/.thunderbird)
    if [[ -d "$user_home/.thunderbird" ]]; then
        log_info "Архивация профилей и паролей Thunderbird (~/.thunderbird)..."
        tar --exclude="$user_home/.thunderbird/*/Cache" \
            --exclude="$user_home/.thunderbird/*/ImapMail/*/ImapData" \
            -czf "$target/thunderbird_profile.tar.gz" \
            -C "$user_home" .thunderbird 2>/dev/null || true
    elif [[ -d "$user_home/snap/thunderbird/common/.thunderbird" ]]; then
        log_info "Архивация Thunderbird Snap (~/snap/thunderbird/...)..."
        tar -czf "$target/thunderbird_snap_profile.tar.gz" \
            -C "$user_home/snap/thunderbird/common" .thunderbird 2>/dev/null || true
    fi

    # 2. Betterbird (~/.betterbird)
    if [[ -d "$user_home/.betterbird" ]]; then
        log_info "Архивация профилей Betterbird..."
        tar -czf "$target/betterbird_profile.tar.gz" -C "$user_home" .betterbird 2>/dev/null || true
    fi

    # 3. Evolution Mail (~/.local/share/evolution & ~/.config/evolution)
    if [[ -d "$user_home/.local/share/evolution" ]]; then
        log_info "Архивация данных Evolution Mail..."
        tar -czf "$target/evolution_data.tar.gz" \
            -C "$user_home/.local/share" evolution \
            -C "$user_home/.config" evolution 2>/dev/null || true
    fi

    log_info "Резервное копирование почтовых данных успешно завершено!"
}

module_mail_restore() {
    local target="$1/mail"
    local dry_run="$2"
    local user_home
    local target_user
    user_home=$(get_target_home)
    target_user=$(get_target_user)

    log_info "Запуск восстановления почтовых клиентов..."

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Распаковка профилей Thunderbird/Evolution в $user_home..."
        return 0
    fi

    # 1. Восстановление Thunderbird (Classis APT / Flatpak / Direct)
    if [[ -f "$target/thunderbird_profile.tar.gz" ]]; then
        log_info "Восстановление профилей Thunderbird..."
        tar -xzf "$target/thunderbird_profile.tar.gz" -C "$user_home"
        chown -R "${target_user}:" "$user_home/.thunderbird"
    fi

    # 2. Восстановление Thunderbird Snap
    if [[ -f "$target/thunderbird_snap_profile.tar.gz" ]]; then
        log_info "Восстановление Snap-профиля Thunderbird..."
        mkdir -p "$user_home/snap/thunderbird/common"
        tar -xzf "$target/thunderbird_snap_profile.tar.gz" -C "$user_home/snap/thunderbird/common"
        chown -R "${target_user}:" "$user_home/snap"
    fi

    # 3. Восстановление Betterbird
    if [[ -f "$target/betterbird_profile.tar.gz" ]]; then
        log_info "Восстановление профилей Betterbird..."
        tar -xzf "$target/betterbird_profile.tar.gz" -C "$user_home"
        chown -R "${target_user}:" "$user_home/.betterbird"
    fi

    # 4. Восстановление Evolution
    if [[ -f "$target/evolution_data.tar.gz" ]]; then
        log_info "Восстановление данных Evolution Mail..."
        mkdir -p "$user_home/.local/share" "$user_home/.config"
        tar -xzf "$target/evolution_data.tar.gz" -C "$user_home/.local/share"
        chown -R "${target_user}:" "$user_home/.local/share/evolution" "$user_home/.config/evolution"
    fi

    log_info "Восстановление почтовых данных завершено!"
}