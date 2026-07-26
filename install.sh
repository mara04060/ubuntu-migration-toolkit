#!/usr/bin/env bash
set -e

echo "=== Установка Ubuntu Migration Toolkit v0.1.0 ==="

REQUIRED_UTILS=("tar" "gzip" "lsb_release" "sha256sum")

for util in "${REQUIRED_UTILS[@]}"; do
    if ! command -v "$util" &>/dev/null; then
        echo "Установка отсутствующей утилиты: $util"
        sudo apt-get update && sudo apt-get install -y "$util"
    fi
done

echo "Установка завершена! Запустите ./umt.sh --help для получения справки."
