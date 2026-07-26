#!/usr/bin/env bash

module_docker_backup() {
    local target="$1/docker"
    local dry_run="$2"
    mkdir -p "$target" 2>/dev/null || true

    if ! command -v docker &>/dev/null; then
        log_warn "Docker не установлен, пропуск модуля."
        return 0
    fi

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Экспорт Docker images, volumes и конфигураций..."
        return 0
    fi

    docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" > "$target/images-list.txt" 2>/dev/null || true
    docker volume ls -q > "$target/volumes-list.txt" 2>/dev/null || true

    mkdir -p "$target/volumes" 2>/dev/null || true
    for vol in $(cat "$target/volumes-list.txt" 2>/dev/null); do
        log_info "Сохранение Docker Volume: $vol"
        docker run --rm -v "$vol":/v -v "$target/volumes":/out alpine tar -czf "/out/${vol}.tar.gz" -C /v . 2>/dev/null || true
    done
}

module_docker_restore() {
    local target="$1/docker"
    local dry_run="$2"

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Восстановление Docker volumes..."
        return 0
    fi

    if [[ -d "$target/volumes" ]]; then
        for archive in "$target/volumes"/*.tar.gz; do
            [[ -e "$archive" ]] || continue
            local vol_name
            vol_name=$(basename "$archive" .tar.gz)
            docker volume create "$vol_name"
            docker run --rm -v "$vol_name":/v -v "$target/volumes":/in alpine tar -xzf "/in/${vol_name}.tar.gz" -C /v
        done
    fi
}
