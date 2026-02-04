#!/bin/bash
# ============================================================================
# Восстановление Medusa из бэкапа
# 
# ВАЖНО: Настройки под вашу конфигурацию (правьте при изменении):
#   • Имя БД: medusa-store → см. строку 24
#   • Пользователь PostgreSQL: postgres → см. строку 25
#   • Имя контейнера PostgreSQL: medusa_postgres → см. строку 26
#   • Путь к uploads: ../uploads → см. строку 29
#   • Директория бэкапов: /opt/medusa-backups → см. строку 22
# ============================================================================

set -e

# === НАСТРОЙКИ (ПРАВИТЬ ПРИ ИЗМЕНЕНИИ КОНФИГУРАЦИИ) ===
BACKUP_DIR="/opt/medusa-backups"           # ← Директория с бэкапами
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPLOADS_PATH="$PROJECT_DIR/uploads"         # ← Куда восстанавливать изображения

# Параметры PostgreSQL (из вашего docker-compose.yml)
PG_DB="medusa-store"                        # ← Имя БД (с дефисом!)
PG_USER="postgres"                          # ← Пользователь PostgreSQL
POSTGRES_CONTAINER="medusa_postgres"        # ← Имя контейнера PostgreSQL

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
error() { echo "❌ [ERROR] $1" >&2; exit 1; }
confirm() { read -p "⚠️  $1 Продолжить? (y/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]]; }

# === ПРОВЕРКА НАЛИЧИЯ БЭКАПОВ ===
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    error "Директория $BACKUP_DIR пуста или не существует. Сначала создайте бэкап: ./scripts/backup_medusa.sh"
fi

# === ВЫБОР БЭКАПА ===
log "Доступные бэкапы:"
BACKUPS=($(ls -td "$BACKUP_DIR"/backup_* 2>/dev/null))
for i in "${!BACKUPS[@]}"; do
    BACKUP="${BACKUPS[$i]}"
    SIZE=$(du -h "$BACKUP/medusa_db.dump" 2>/dev/null | cut -f1 || echo "N/A")
    echo "[$i] $(basename "$BACKUP") — $SIZE"
done

read -p "Выберите номер бэкапа для восстановления: " CHOICE
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -ge "${#BACKUPS[@]}" ]; then
    error "Неверный выбор"
fi
SELECTED_BACKUP="${BACKUPS[$CHOICE]}"

echo; cat "$SELECTED_BACKUP/backup_info.txt" 2>/dev/null; echo

# === ПОДТВЕРЖДЕНИЕ ===
if ! confirm "❗ ВНИМАНИЕ: Восстановление ПЕРЕЗАПИШЕТ текущие данные в БД '$PG_DB'!"; then
    log "Отменено пользователем"
    exit 0
fi

# === АВТОРЕЗЕРВНАЯ КОПИЯ ТЕКУЩИХ ДАННЫХ ===
if confirm "Создать резервную копию текущих данных перед восстановлением? (РЕКОМЕНДУЕТСЯ)"; then
    log "Создание резервной копии..."
    "$PROJECT_DIR/scripts/backup_medusa.sh" || error "Не удалось создать резервную копию!"
    log "✓ Резервная копия создана"
fi

# === ВОССТАНОВЛЕНИЕ БД ===
log "Восстановление БД '$PG_DB' из $SELECTED_BACKUP..."

# Принудительно завершаем все подключения к БД
docker exec "$POSTGRES_CONTAINER" psql -U "$PG_USER" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$PG_DB';" 2>/dev/null || true

# Удаляем старую БД и создаём новую
docker exec "$POSTGRES_CONTAINER" psql -U "$PG_USER" -c "DROP DATABASE IF EXISTS \"$PG_DB\";" 2>/dev/null || true
docker exec "$POSTGRES_CONTAINER" psql -U "$PG_USER" -c "CREATE DATABASE \"$PG_DB\";" || error "Не удалось создать БД"

# Восстанавливаем данные
docker cp "$SELECTED_BACKUP/medusa_db.dump" "$POSTGRES_CONTAINER:/tmp/restore.dump"
docker exec "$POSTGRES_CONTAINER" pg_restore -U "$PG_USER" -d "$PG_DB" /tmp/restore.dump || error "Ошибка восстановления дампа"
docker exec "$POSTGRES_CONTAINER" rm -f /tmp/restore.dump

log "✓ БД '$PG_DB' восстановлена"

# === ВОССТАНОВЛЕНИЕ ФАЙЛОВ (если есть) ===
if [ -d "$SELECTED_BACKUP/uploads" ]; then
    if confirm "Восстановить файлы изображений в $UPLOADS_PATH?"; then
        # Резервная копия текущих файлов
        if [ -d "$UPLOADS_PATH" ] && [ -n "$(ls -A "$UPLOADS_PATH" 2>/dev/null)" ]; then
            BACKUP_OLD="${UPLOADS_PATH}.bak_$(date +%Y%m%d_%H%M%S)"
            mv "$UPLOADS_PATH" "$BACKUP_OLD"
            log "  Текущие файлы перемещены в: $BACKUP_OLD"
        fi
        
        cp -r "$SELECTED_BACKUP/uploads" "$UPLOADS_PATH"
        FILE_COUNT=$(find "$UPLOADS_PATH" -type f 2>/dev/null | wc -l)
        log "✓ Uploads восстановлены: $FILE_COUNT файлов"
    fi
fi

# === ПЕРЕЗАПУСК КОНТЕЙНЕРА MEDUSA ===
if confirm "Перезапустить контейнер medusa_backend для применения изменений?"; then
    cd "$PROJECT_DIR"
    docker compose restart medusa_backend || docker compose up -d medusa_backend
    sleep 5
    log "✓ Контейнер перезапущен"
    
    # Проверка работоспособности
    if curl -s http://localhost:9000/store/health >/dev/null 2>&1; then
        log "✓ Medusa backend работает (статус: healthy)"
    else
        log "⚠️  Medusa backend не отвечает на /store/health — проверьте логи: docker compose logs medusa_backend"
    fi
fi

log "=========================================="
log "✓ Восстановление завершено!"
log "Проверьте данные:"
log "  • Продукты: docker exec $POSTGRES_CONTAINER psql -U $PG_USER \"$PG_DB\" -c 'SELECT COUNT(*) FROM product;'"
log "  • Администраторы: docker exec $POSTGRES_CONTAINER psql -U $PG_USER \"$PG_DB\" -c 'SELECT email FROM user WHERE role = \\\"admin\\\";'"
log "=========================================="
exit 0