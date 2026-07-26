#!/usr/bin/env bash

create_archive() {
    local src_dir="$1"
    local output_file="$2"
    local dry_run="${3:-0}"

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Архивация $src_dir -> $output_file"
        return 0
    fi

    log_info "Создание архива: $output_file"
    tar -czf "$output_file" -C "$(dirname "$src_dir")" "$(basename "$src_dir")" 2>/dev/null
    
    if [[ -f "$output_file" ]]; then
        sha256sum "$output_file" > "${output_file}.sha256"
        log_info "Архив создан, SHA256 подсчитан."
    else
        log_error "Ошибка при создании архива $output_file"
    fi
}

extract_archive() {
    local archive_file="$1"
    local dest_dir="$2"
    local dry_run="${3:-0}"

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Распаковка $archive_file -> $dest_dir"
        return 0
    fi

    if [[ -f "${archive_file}.sha256" ]]; then
        log_info "Проверка контрольной суммы SHA256..."
        sha256sum -c "${archive_file}.sha256" || { log_error "Сбой проверки SHA256!"; return 1; }
    fi

    log_info "Распаковка $archive_file в $dest_dir"
    mkdir -p "$dest_dir"
    tar -xzf "$archive_file" -C "$dest_dir"
}
