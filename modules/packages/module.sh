#!/usr/bin/env bash

module_packages_backup() {
    local target="$1/packages"
    local dry_run="$2"
    mkdir -p "$target" 2>/dev/null || true

    log_info "Резервное копирование списков пакетов (APT, Snap, Flatpak)..."

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Экспорт PPA, списков APT, Snap и Flatpak пакетов..."
        return 0
    fi

    # 1. APT: Выгрузка ТОЛЬКО явно установленных пользователем пакетов (без системных зависимостей)
    if command -v apt-mark &>/dev/null; then
        apt-mark showmanual > "$target/apt-manual-packages.txt" 2>/dev/null || true
    else
        dpkg-query -f='${binary:Package}\n' -W > "$target/apt-all-packages.txt" 2>/dev/null || true
    fi

    # 2. APT: Сохранение PPA-репозиториев и ключей
    mkdir -p "$target/apt-sources" 2>/dev/null || true
    cp -r /etc/apt/sources.list* "$target/apt-sources/" 2>/dev/null || true
    cp -r /etc/apt/trusted.gpg.d "$target/apt-sources/" 2>/dev/null || true

    # 3. Snap пакеты
    if command -v snap &>/dev/null; then
        snap list | awk 'NR>1 {print $1}' > "$target/snap-packages.txt" 2>/dev/null || true
    fi

    # 4. Flatpak пакеты
    if command -v flatpak &>/dev/null; then
        flatpak list --app --columns=application > "$target/flatpak-packages.txt" 2>/dev/null || true
    fi

    log_info "Списки пакетов успешно сохранены в $target"
}

module_packages_restore() {
    local target="$1/packages"
    local dry_run="$2"

    log_info "Запуск восстановления пакетов..."

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Восстановление PPA, APT, Snap и Flatpak пакетов из $target..."
        return 0
    fi

    # 1. Восстановление PPA и списков APT-репозиториев
    if [[ -d "$target/apt-sources" ]]; then
        log_info "Восстановление конфигураций APT и PPA..."
        cp -rn "$target/apt-sources/sources.list"* /etc/apt/ 2>/dev/null || true
        if [[ -d "$target/apt-sources/trusted.gpg.d" ]]; then
            cp -rn "$target/apt-sources/trusted.gpg.d/"* /etc/apt/trusted.gpg.d/ 2>/dev/null || true
        fi
        apt-get update -y || true
    fi

    # 2. Восстановление APT-пакетов
    if [[ -f "$target/apt-manual-packages.txt" ]]; then
        log_info "Установка APT-пакетов из apt-manual-packages.txt..."
        xargs -a "$target/apt-manual-packages.txt" apt-get install -y --ignore-missing || true
    elif [[ -f "$target/apt-all-packages.txt" ]]; then
        log_info "Установка APT-пакетов из apt-all-packages.txt..."
        xargs -a "$target/apt-all-packages.txt" apt-get install -y --ignore-missing || true
    fi

    # 3. Восстановление Snap-пакетов
    if [[ -f "$target/snap-packages.txt" ]] && command -v snap &>/dev/null; then
        log_info "Установка Snap-пакетов..."
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            snap install "$pkg" 2>/dev/null || snap install "$pkg" --classic 2>/dev/null || true
        done < "$target/snap-packages.txt"
    fi

    # 4. Восстановление Flatpak-пакетов
    if [[ -f "$target/flatpak-packages.txt" ]] && command -v flatpak &>/dev/null; then
        log_info "Установка Flatpak-пакетов..."
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            flatpak install -y flathub "$pkg" 2>/dev/null || true
        done < "$target/flatpak-packages.txt"
    fi

    log_info "Восстановление пакетов завершено!"
}