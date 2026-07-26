#!/usr/bin/env bash

parse_yaml_key() {
    local file="$1"
    local key="$2"
    local default="$3"
    
    if [[ ! -f "$file" ]]; then
        echo "$default"
        return
    fi
    
    local val
    val=$(grep -E "^${key}:" "$file" | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")
    if [[ -z "$val" ]]; then
        echo "$default"
    else
        echo "$val"
    fi
}

load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        log_warn "Конфигурационный файл $config_file не найден. Используются значения по умолчанию."
        TARGET_DIR="/var/backups/umt"
        COMPRESSION="gzip"
    else
        TARGET_DIR=$(parse_yaml_key "$config_file" "target_dir" "/var/backups/umt")
        COMPRESSION=$(parse_yaml_key "$config_file" "compression" "gzip")
    fi
}
