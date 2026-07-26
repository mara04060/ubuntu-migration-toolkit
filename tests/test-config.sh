#!/usr/bin/env bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/config.sh"

echo "=== [TEST] Чтение конфигурации ==="
load_config "$BASE_DIR/config.yaml"

echo "Целевой каталог: $TARGET_DIR"
echo "Алгоритм сжатия: $COMPRESSION"

if [[ -n "$TARGET_DIR" ]]; then
    echo -e "\e[32m[PASS] Конфигурация успешно загружена!\e[0m"
else
    echo -e "\e[31m[FAIL] Ошибка чтения config.yaml!\e[0m"
fi
