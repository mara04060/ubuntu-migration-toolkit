#!/usr/bin/env bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/module-manager.sh"

echo "=== [TEST] Проверка менеджера модулей ==="
echo "Доступные модули в системе: ${ALL_MODULES[*]}"

if is_module_selected "docker" "home,docker" ""; then
    echo -e "\e[32m[PASS] Модуль 'docker' корректно выбран через --only\e[0m"
else
    echo -e "\e[31m[FAIL] Ошибка фильтрации модулей!\e[0m"
fi
