#!/usr/bin/env bash

module_node_backup() {
    local target="$1/node"
    local dry_run="$2"
    mkdir -p "$target" 2>/dev/null || true

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Экспорт списка npm, yarn, pnpm глобальных модулей..."
        return 0
    fi

    if command -v npm &>/dev/null; then
        npm list -g --depth=0 --json > "$target/npm-global-packages.json" 2>/dev/null || true
    fi
}

module_node_restore() {
    local target="$1/node"
    local dry_run="$2"
    
    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Восстановление Node пакетов..."
        return 0
    fi
}
