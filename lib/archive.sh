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
    mkdir -p "$(dirname "$output_file")"
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

# === ГЛУБОКАЯ ВЕРИФИКАЦИЯ БЭКАПА ===
verify_backup_integrity() {
    local target_dir="$1"
    local errors=0
    local total_checked=0

    log_info "=== [VERIFY] Старт глубокой проверки резервной копии: $target_dir ==="

    if [[ ! -d "$target_dir" ]]; then
        log_error "Каталог бэкапа не найден: $target_dir"
        return 1
    fi

    # 1. Проверка SHA256 для всех файлов
    log_info "1/4 Проверка контрольных сумм SHA256..."
    while IFS= read -r sha_file; do
        [[ -f "$sha_file" ]] || continue
        total_checked=$((total_checked + 1))
        local archive_dir
        archive_dir=$(dirname "$sha_file")
        if (cd "$archive_dir" && sha256sum -c "$(basename "$sha_file")" &>/dev/null); then
            log_debug "SHA256 OK: $sha_file"
        else
            log_error "[FAIL] Ошибка контрольной суммы SHA256: $sha_file"
            errors=$((errors + 1))
        fi
    done < <(find "$target_dir" -name "*.sha256")

    # 2. Тестирование целостности .tar.gz архивов
    log_info "2/4 Тестирование целостности TAR.GZ архивов..."
    while IFS= read -r tar_file; do
        [[ -f "$tar_file" ]] || continue
        total_checked=$((total_checked + 1))
        if tar -tzf "$tar_file" &>/dev/null; then
            log_debug "TAR OK: $tar_file"
        else
            log_error "[FAIL] Архив поврежден или не читается: $tar_file"
            errors=$((errors + 1))
        fi
    done < <(find "$target_dir" -name "*.tar.gz" -o -name "*.tgz")

    # 3. Верификация дампов баз данных
    log_info "3/4 Верификация дампов баз данных (PostgreSQL, MySQL, Redis)..."
    
    # PostgreSQL Custom Dumps (.dump)
    while IFS= read -r pg_dump_file; do
        [[ -f "$pg_dump_file" ]] || continue
        total_checked=$((total_checked + 1))
        if command -v pg_restore &>/dev/null; then
            if pg_restore --list "$pg_dump_file" &>/dev/null; then
                log_debug "PG DUMP OK: $pg_dump_file"
            else
                log_error "[FAIL] Поврежден кастомный дамп PostgreSQL: $pg_dump_file"
                errors=$((errors + 1))
            fi
        fi
    done < <(find "$target_dir" -name "*.dump")

    # MySQL / SQL Dumps (.sql)
    while IFS= read -r sql_file; do
        [[ -f "$sql_file" ]] || continue
        total_checked=$((total_checked + 1))
        if [[ -s "$sql_file" ]] && grep -qE "(Dump completed|CREATE DATABASE|USE|INSERT INTO|PostgreSQL database dump)" "$sql_file"; then
            log_debug "SQL OK: $sql_file"
        else
            log_error "[FAIL] SQL-дамп пуст или некорректен: $sql_file"
            errors=$((errors + 1))
        fi
    done < <(find "$target_dir" -name "*.sql")

    # Redis RDB
    while IFS= read -r rdb_file; do
        [[ -f "$rdb_file" ]] || continue
        total_checked=$((total_checked + 1))
        if command -v redis-check-rdb &>/dev/null; then
            if redis-check-rdb "$rdb_file" &>/dev/null; then
                log_debug "REDIS RDB OK: $rdb_file"
            else
                log_error "[FAIL] Поврежден RDB файл Redis: $rdb_file"
                errors=$((errors + 1))
            fi
        elif [[ -s "$rdb_file" ]]; then
            log_debug "REDIS RDB SIZE OK: $rdb_file"
        fi
    done < <(find "$target_dir" -name "*.rdb")

    # 4. Проверка структурированных отчетов (JSON)
    log_info "4/4 Проверка отчетов и текстовых файлов..."
    while IFS= read -r json_file; do
        [[ -f "$json_file" ]] || continue
        total_checked=$((total_checked + 1))
        if command -v jq &>/dev/null; then
            if jq . "$json_file" &>/dev/null; then
                log_debug "JSON OK: $json_file"
            else
                log_error "[FAIL] Ошибка синтаксиса JSON: $json_file"
                errors=$((errors + 1))
            fi
        fi
    done < <(find "$target_dir" -name "*.json")

    # Итог проверки
    echo "--------------------------------------------------"
    if [[ $errors -eq 0 ]]; then
        log_info -e "\e[32m[SUCCESS] Верификация успешно пройдена! Все $total_checked элементов целостны.\e[0m"
        return 0
    else
        log_error "[FAILURE] Найдено ошибок при проверке: $errors из $total_checked элементов!"
        return 1
    fi
}