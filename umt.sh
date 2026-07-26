#!/usr/bin/env bash
# Ubuntu Migration Toolkit (UMT) v0.1.0 - CLI Entrypoint

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключение библиотек по абсолютному пути
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/archive.sh"
source "$SCRIPT_DIR/lib/module-manager.sh"
source "$SCRIPT_DIR/lib/report.sh"

ACTION=""
DRY_RUN=0
VERBOSE=0
MODULE=""
ONLY_MODS=""
SKIP_MODS=""
CUSTOM_TARGET=""

usage() {
    echo "Ubuntu Migration Toolkit (UMT) v0.1.0"
    echo ""
    echo "Использование:"
    echo "  sudo ./umt.sh <action> [параметры]"
    echo ""
    echo "Действия (Actions):"
    echo "  backup        Выполнить резервное копирование данных"
    echo "  restore       Восстановить данные из бэкапа"
    echo "  verify        Проверить целостность бэкапа"
    echo ""
    echo "Параметры:"
    echo "  --dry-run         Тестовый прогон без фактической записи файлов"
    echo "  --verbose         Расширенный вывод логов"
    echo "  --module <mod>    Запустить только указанный модуль (напр. docker)"
    echo "  --only <mod,mod>  Запустить только переданный список модулей через запятую"
    echo "  --skip <mod,mod>  Пропустить указанные модули"
    echo "  --target <path>   Указать кастомный путь для хранения бэкапа (SSD/NFS)"
    echo "  -h, --help        Показать данное справочное сообщение"
    exit 0
}

if [[ $# -eq 0 ]]; then usage; fi

ACTION="$1"
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --verbose)
            VERBOSE=1
            export VERBOSE=1
            shift
            ;;
        --module)
            MODULE="$2"
            shift 2
            ;;
        --only)
            ONLY_MODS="$2"
            shift 2
            ;;
        --skip)
            SKIP_MODS="$2"
            shift 2
            ;;
        --target)
            CUSTOM_TARGET="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Неизвестный параметр: $1"
            usage
            ;;
    esac
done

check_root
load_config "$SCRIPT_DIR/config.yaml"

if [[ -n "$CUSTOM_TARGET" ]]; then
    TARGET_DIR="$CUSTOM_TARGET"
fi

if [[ -n "$MODULE" ]]; then
    ONLY_MODS="$MODULE"
fi

init_logger "$TARGET_DIR/logs"

log_info "=== Ubuntu Migration Toolkit v0.1.0 ==="
log_info "Действие: $ACTION | Dry-Run: $DRY_RUN | Target: $TARGET_DIR"

check_ubuntu_version

case "$ACTION" in
    backup)
        check_disk_space "$TARGET_DIR" 10
        for mod in "${ALL_MODULES[@]}"; do
            if is_module_selected "$mod" "$ONLY_MODS" "$SKIP_MODS"; then
                run_module_action "$SCRIPT_DIR" "backup" "$mod" "$TARGET_DIR" "$DRY_RUN"
            fi
        done
        if [[ "$DRY_RUN" -eq 0 ]]; then
            generate_reports "$TARGET_DIR"
        fi
        log_info "Резервное копирование успешно завершено!"
        ;;

    restore)
        for mod in "${ALL_MODULES[@]}"; do
            if is_module_selected "$mod" "$ONLY_MODS" "$SKIP_MODS"; then
                run_module_action "$SCRIPT_DIR" "restore" "$mod" "$TARGET_DIR" "$DRY_RUN"
            fi
        done
        log_info "Восстановление успешно завершено!"
        ;;

    verify)
        log_info "Проверка целостности архивов и манифестов..."
        find "$TARGET_DIR" -name "*.sha256" -exec sha256sum -c {} \;
        log_info "Проверка целостности успешно завершена!"
        ;;

    *)
        log_error "Неизвестное действие: $ACTION"
        usage
        ;;
esac
