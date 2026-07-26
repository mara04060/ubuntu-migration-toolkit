#!/usr/bin/env bash

module_databases_backup() {
    local target="$1/databases"
    local dry_run="$2"
    mkdir -p "$target" 2>/dev/null || true

    log_info "Запуск резервного копирования баз данных..."

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Сбор данных PostgreSQL, MySQL/MariaDB и Redis..."
        return 0
    fi

    # === PostgreSQL ===
    if command -v pg_dumpall &>/dev/null || command -v pg_dump &>/dev/null; then
        log_info "Резервное копирование PostgreSQL..."
        local pg_dir="$target/postgresql"
        mkdir -p "$pg_dir"

        # Сохранение ролей и глобальных настроек
        sudo -u postgres pg_dumpall --globals-only > "$pg_dir/pg_globals.sql" 2>/dev/null || true

        # Сбор списка пользовательских БД и создание кастомных дампов (.dump)
        for db in $(sudo -u postgres psql -At -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';"); do
            log_info "Создание дампа PostgreSQL БД: $db"
            sudo -u postgres pg_dump -F c -b -v "$db" > "$pg_dir/${db}.dump" 2>/dev/null || true
        done
    fi

    # === MySQL / MariaDB ===
    if command -v mysqldump &>/dev/null || command -v mariadb-dump &>/dev/null; then
        log_info "Резервное копирование MySQL / MariaDB..."
        local mysql_dir="$target/mysql"
        mkdir -p "$mysql_dir"

        local dump_cmd="mysqldump"
        command -v mariadb-dump &>/dev/null && dump_cmd="mariadb-dump"

        # Безопасный дамп без блокировки InnoDB таблиц с процедурами и триггерами
        $dump_cmd --all-databases \
                  --single-transaction \
                  --quick \
                  --routines \
                  --triggers \
                  --events > "$mysql_dir/all_databases.sql" 2>/dev/null || true
    fi

    # === Redis ===
    if command -v redis-cli &>/dev/null; then
        log_info "Резервное копирование Redis (RDB Snapshots)..."
        local redis_dir="$target/redis"
        mkdir -p "$redis_dir"

        # Фоновое сохранение снапшота
        redis-cli BGSAVE 2>/dev/null || true
        sleep 2
        
        # Поиск и копирование файла dump.rdb
        local rdb_file
        rdb_file=$(redis-cli config get dir 2>/dev/null | tail -n 1)"/dump.rdb"
        if [[ -f "$rdb_file" ]]; then
            cp "$rdb_file" "$redis_dir/dump.rdb" 2>/dev/null || true
        elif [[ -f "/var/lib/redis/dump.rdb" ]]; then
            cp "/var/lib/redis/dump.rdb" "$redis_dir/dump.rdb" 2>/dev/null || true
        fi
    fi
}

module_databases_restore() {
    local target="$1/databases"
    local dry_run="$2"

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "[DRY-RUN] Восстановление баз данных из $target..."
        return 0
    fi

    # Восстановление PostgreSQL
    if [[ -d "$target/postgresql" ]] && command -v pg_restore &>/dev/null; then
        log_info "Восстановление глобальных настроек PostgreSQL..."
        [[ -f "$target/postgresql/pg_globals.sql" ]] && sudo -u postgres psql -f "$target/postgresql/pg_globals.sql" || true

        for dump_file in "$target/postgresql"/*.dump; do
            [[ -e "$dump_file" ]] || continue
            local db_name
            db_name=$(basename "$dump_file" .dump)
            log_info "Восстановление PostgreSQL БД: $db_name"
            sudo -u postgres createdb "$db_name" 2>/dev/null || true
            sudo -u postgres pg_restore -d "$db_name" --clean --if-exists "$dump_file" 2>/dev/null || true
        done
    fi

    # Восстановление MySQL
    if [[ -f "$target/mysql/all_databases.sql" ]] && command -v mysql &>/dev/null; then
        log_info "Восстановление MySQL/MariaDB баз..."
        mysql < "$target/mysql/all_databases.sql" 2>/dev/null || true
    fi

    # Восстановление Redis
    if [[ -f "$target/redis/dump.rdb" ]]; then
        log_info "Восстановление снапшота Redis..."
        systemctl stop redis-server 2>/dev/null || true
        cp "$target/redis/dump.rdb" /var/lib/redis/dump.rdb 2>/dev/null || true
        chown redis:redis /var/lib/redis/dump.rdb 2>/dev/null || true
        systemctl start redis-server 2>/dev/null || true
    fi
}