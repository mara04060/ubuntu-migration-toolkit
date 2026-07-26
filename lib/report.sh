#!/usr/bin/env bash

generate_reports() {
    local target_dir="$1"
    local report_json="${target_dir}/migration-report.json"
    local report_html="${target_dir}/restore-report.html"

    log_info "Генерация итоговых отчетов..."

    echo "{" > "$report_json"
    echo "  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"," >> "$report_json"
    echo "  "hostname": "$(hostname)"," >> "$report_json"
    echo "  "ubuntu_version": "$(lsb_release -ds 2>/dev/null || echo 'Ubuntu')"," >> "$report_json"
    echo "  "kernel": "$(uname -r)"," >> "$report_json"
    echo "  "status": "COMPLETED"" >> "$report_json"
    echo "}" >> "$report_json"

    echo "<!DOCTYPE html><html lang="ru"><head><meta charset="UTF-8"><title>UMT Migration Report</title></head><body><h1>Ubuntu Migration Toolkit Report</h1></body></html>" > "$report_html"
    log_info "Отчеты сохранены в $target_dir"
}
