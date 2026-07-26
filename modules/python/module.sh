#!/usr/bin/env bash

module_python_backup() {
    local target="$1/python"
    local dry_run="$2"
    local user_home
    user_home=$(get_target_home)
    mkdir -p "$target" 2>/dev/null || true

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Экспорт глобальных pip пакетов, pyenv, poetry..."
        return 0
    fi

    if command -v pip &>/dev/null; then
        pip freeze > "$target/pip-global-requirements.txt" 2>/dev/null || true
    fi

    if [[ -d "$user_home/.pyenv" ]]; then
        cp -r "$user_home/.pyenv/version" "$target/pyenv-version" 2>/dev/null || true
    fi
}

module_python_restore() {
    local target="$1/python"
    local dry_run="$2"

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Установка глобальных Python пакетов..."
        return 0
    fi

    if [[ -f "$target/pip-global-requirements.txt" ]] && command -v pip &>/dev/null; then
        pip install -r "$target/pip-global-requirements.txt" || true
    fi
}
