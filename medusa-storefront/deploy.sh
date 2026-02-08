#!/bin/bash

# ============================================
# Скрипт деплоя Medusa Frontend на VPS
# ============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка наличия .env.production
if [ ! -f .env.production ]; then
    log_error "Файл .env.production не найден!"
    log_info "Создайте .env.production на основе .env.template"
    exit 1
fi

log_info "Начинаем деплой Medusa Frontend..."

# Остановка существующих контейнеров
log_info "Остановка существующих контейнеров..."
docker compose down

# Pull изменений из GitHub
log_info "Получение изменений из GitHub..."
git pull origin main

# Проверка успешности git pull
if [ $? -ne 0 ]; then
    log_error "Не удалось получить изменения из GitHub"
    exit 1
fi

# Сборка нового образа
log_info "Сборка Docker образа..."
docker compose build --no-cache

# Проверка успешности сборки
if [ $? -ne 0 ]; then
    log_error "Не удалось собрать Docker образ"
    exit 1
fi

# Запуск контейнеров
log_info "Запуск контейнеров..."
docker compose up -d

# Проверка успешности запуска
if [ $? -ne 0 ]; then
    log_error "Не удалось запустить контейнеры"
    exit 1
fi

# Очистка старых образов (опционально)
log_info "Очистка старых Docker образов..."
docker image prune -f

# Проверка статуса контейнера
log_info "Проверка статуса контейнера..."
sleep 5
docker compose ps

# Вывод логов для проверки
log_info "Последние логи контейнера:"
docker compose logs --tail=20

log_info "=========================================="
log_info "Деплой завершён успешно!"
log_info "Frontend доступен по адресу: http://88.218.67.164:8000"
log_info "=========================================="
log_info ""
log_info "Полезные команды:"
log_info "  Просмотр логов: docker compose logs -f"
log_info "  Остановка: docker compose down"
log_info "  Перезапуск: docker compose restart"
log_info "  Статус: docker compose ps"
