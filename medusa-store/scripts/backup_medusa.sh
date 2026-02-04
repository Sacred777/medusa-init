#!/bin/bash
# ============================================================================
# Полный бэкап Medusa (PostgreSQL + файлы)
# Ротация: хранит не более 3 последних бэкапов
# 
# ВАЖНО: Настройки под вашу конфигурацию (правьте при изменении):
#   • Имя БД: medusa-store (с дефисом!) → см. строку 28
#   • Пользователь PostgreSQL: postgres → см. строку 29
#   • Имя контейнера PostgreSQL: medusa_postgres → см. строку 30
#   • Путь к uploads: ../uploads → см. строку 33
#   • Директория бэкапов: /opt/medusa-backups → см. строку 26
# ============================================================================

set -e

# === НАСТРОЙКИ (ПРАВИТЬ ПРИ ИЗМЕНЕНИИ КОНФИГУРАЦИИ) ===
BACKUP_DIR="/opt/medusa-backups"           # ← Куда сохранять бэкапы (системная директория)
RETENTION_COUNT=3                           # ← Сколько бэкапов хранить
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # Автоопределение пути проекта
UPLOADS_PATH="$PROJECT_DIR/uploads"         # ← Путь к папке с изображениями (если используется локальное хранилище)

# Параметры PostgreSQL (из вашего docker-compose.yml)
PG_DB="medusa-store"                        # ← Имя БД (с дефисом!)
PG_USER="postgres"                          # ← Пользователь PostgreSQL
POSTGRES_CONTAINER="medusa_postgres"        # ← Имя контейнера PostgreSQL

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TMP_DIR="$BACKUP_DIR/backup_$TIMESTAMP"

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
error() { echo "❌ [ERROR] $1" >&2; exit 1; }

# === ПРОВЕРКА ЗАПУСКА КОНТЕЙНЕРА ===
if ! docker ps | grep -q "$POSTGRES_CONTAINER"; then
    error "Контейнер $POSTGRES_CONTAINER не запущен! Запустите: cd $PROJECT_DIR && docker compose up -d"
fi

# === СОЗДАНИЕ ДИРЕКТОРИЙ ===
log "Подготовка директорий..."
mkdir -p "$BACKUP_DIR" || error "Не удалось создать $BACKUP_DIR"
mkdir -p "$BACKUP_TMP_DIR" || error "Не удалось создать $BACKUP_TMP_DIR"

# === 1. БЭКАП POSTGRESQL ===
log "1. Создание дампа БД '$PG_DB'..."
docker exec "$POSTGRES_CONTAINER" pg_dump -U "$PG_USER" "$PG_DB" \
  --format=custom \
  --compress=5 \
  --file="/tmp/medusa_dump_$TIMESTAMP.dump" || error "Ошибка создания дампа БД"

docker cp "$POSTGRES_CONTAINER:/tmp/medusa_dump_$TIMESTAMP.dump" \
  "$BACKUP_TMP_DIR/medusa_db.dump" || error "Ошибка копирования дампа на хост"

docker exec "$POSTGRES_CONTAINER" rm -f "/tmp/medusa_dump_$TIMESTAMP.dump"
log "✓ Дамп БД сохранён: $(du -h "$BACKUP_TMP_DIR/medusa_db.dump" | cut -f1)"

# === 2. БЭКАП ФАЙЛОВ ИЗОБРАЖЕНИЙ ===
if [ -d "$UPLOADS_PATH" ] && [ -n "$(ls -A "$UPLOADS_PATH" 2>/dev/null)" ]; then
    log "2. Копирование uploads..."
    cp -r "$UPLOADS_PATH" "$BACKUP_TMP_DIR/" || error "Ошибка копирования uploads"
    FILE_COUNT=$(find "$BACKUP_TMP_DIR/uploads" -type f 2>/dev/null | wc -l)
    log "✓ Uploads сохранены: $FILE_COUNT файлов ($(du -sh "$BACKUP_TMP_DIR/uploads" 2>/dev/null | cut -f1 || echo 'N/A'))"
else
    log "⚠️  Uploads не найдены или пусты: $UPLOADS_PATH"
    log "    Совет: если изображения хранятся в облаке (S3, Yandex Object Storage), бэкап файлов не требуется"
fi

# === 3. МЕТАДАННЫЕ БЭКАПА ===
cat > "$BACKUP_TMP_DIR/backup_info.txt" <<EOF
Дата создания: $(date '+%Y-%m-%d %H:%M:%S')
Проект: $PROJECT_DIR
БД: $PG_DB
Пользователь БД: $PG_USER
Контейнер PostgreSQL: $POSTGRES_CONTAINER
EOF

# === 4. РОТАЦИЯ СТАРЫХ БЭКАПОВ ===
BACKUP_COUNT=$(ls -d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$RETENTION_COUNT" ]; then
    TO_DELETE=$((BACKUP_COUNT - RETENTION_COUNT))
    log "Ротация: удаление $TO_DELETE старых бэкапов..."
    for backup in $(ls -td "$BACKUP_DIR"/backup_* | tail -n "$TO_DELETE"); do
        rm -rf "$backup"
        log "  🗑️  Удалён: $(basename "$backup")"
    done
fi

# === ЗАВЕРШЕНИЕ ===
log "=========================================="
log "✓ Бэкап успешно создан: $BACKUP_TMP_DIR"
log "Текущие бэкапы:"
ls -lh "$BACKUP_DIR"/backup_*/backup_info.txt 2>/dev/null | awk '{print "  " $6, $7, $8, $9}'
log "=========================================="
exit 0