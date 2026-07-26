#!/usr/bin/env bash

module_jetbrains_backup() {
    local target="$1/jetbrains"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)
    mkdir -p "$target" 2>/dev/null || true

    log_info "Резервное копирование настроек и плагинов JetBrains IDE..."

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Архивирование ~/.config/JetBrains и ~/.local/share/JetBrains..."
        return 0
    fi

    # 1. Основные конфигурации (настройки, хоткеи, подключения к БД, проекты)
    if [[ -d "$user_home/.config/JetBrains" ]]; then
        log_info "Архивация конфигураций (~/.config/JetBrains)..."
        tar -czf "$target/jetbrains_configs.tar.gz" -C "$user_home/.config" JetBrains 2>/dev/null || true
    fi

    # 2. Установленные плагины и данные JetBrains Toolbox
    if [[ -d "$user_home/.local/share/JetBrains" ]]; then
        log_info "Архивация плагинов и Toolbox (~/.local/share/JetBrains)..."
        tar -czf "$target/jetbrains_plugins.tar.gz" -C "$user_home/.local/share" JetBrains 2>/dev/null || true
    fi
}

module_jetbrains_restore() {
    local target="$1/jetbrains"
    local dry_run="$2"
    local user_home
    local target_user
    user_home=$(get_target_home)
    target_user=$(get_target_user)

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Распаковка конфигураций и плагинов JetBrains в $user_home..."
        return 0
    fi

    # Восстановление конфигураций
    if [[ -f "$target/jetbrains_configs.tar.gz" ]]; then
        log_info "Восстановление конфигураций IDE..."
        mkdir -p "$user_home/.config"
        tar -xzf "$target/jetbrains_configs.tar.gz" -C "$user_home/.config"
        chown -R "${target_user}:" "$user_home/.config/JetBrains"
    fi

    # Восстановление плагинов
    if [[ -f "$target/jetbrains_plugins.tar.gz" ]]; then
        log_info "Восстановление плагинов IDE..."
        mkdir -p "$user_home/.local/share"
        tar -xzf "$target/jetbrains_plugins.tar.gz" -C "$user_home/.local/share"
        chown -R "${target_user}:" "$user_home/.local/share/JetBrains"
    fi

    log_info "Восстановление настроек JetBrains успешно завершено!"
}