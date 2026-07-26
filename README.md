# Ubuntu Migration Toolkit (UMT) v0.1.0

Профессиональный инструментарий для миграции пользовательского окружения, конфигураций, баз данных, Docker-контейнеров и проектов разработки при чистой установке Ubuntu (с 24.04 LTS на 26.04 LTS).

## Быстрый старт

### Резервное копирование (Backup)
```bash
# Полный бэкап в директорию по умолчанию (/var/backups/umt)
sudo ./umt.sh backup

# Бэкап на внешний SSD
sudo ./umt.sh backup --target /media/user/ExternalSSD/umt-backup

# Запуск в сухом режиме (без копирования файлов)
sudo ./umt.sh backup --dry-run --verbose

# Бэкап только конкретных модулей
sudo ./umt.sh backup --only home,docker,security
```

### Проверка целостности (Verify)
```bash
sudo ./umt.sh verify --target /media/user/ExternalSSD/umt-backup
```

### Восстановление (Restore)
```bash
sudo ./umt.sh restore --target /media/user/ExternalSSD/umt-backup
```
