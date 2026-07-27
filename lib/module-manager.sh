#!/usr/bin/env bash

ALL_MODULES=("mail" "system" "packages" "home" "docker" "databases" "jetbrains" "python" "node" "security")

is_module_selected() {
    local mod="$1"
    local only="$2"
    local skip="$3"

    if [[ -n "$skip" ]]; then
        IFS=',' read -ra SKIP_ARR <<< "$skip"
        for s in "${SKIP_ARR[@]}"; do
            if [[ "$s" == "$mod" ]]; then return 1; fi
        done
    fi

    if [[ -n "$only" ]]; then
        IFS=',' read -ra ONLY_ARR <<< "$only"
        for o in "${ONLY_ARR[@]}"; do
            if [[ "$o" == "$mod" ]]; then return 0; fi
        done
        return 1
    fi

    return 0
}

run_module_action() {
    local base_dir="$1"
    local action="$2" # backup / restore
    local mod="$3"
    local target_dir="$4"
    local dry_run="$5"

    local mod_script="${base_dir}/modules/${mod}/module.sh"
    if [[ -f "$mod_script" ]]; then
        source "$mod_script"
        log_info "=== Модуль [$mod]: Запуск $action ==="
        if [[ "$action" == "backup" ]]; then
            "module_${mod}_backup" "$target_dir" "$dry_run"
        elif [[ "$action" == "restore" ]]; then
            "module_${mod}_restore" "$target_dir" "$dry_run"
        fi
    else
        log_warn "Скрипт модуля $mod не найден: $mod_script"
    fi
}
