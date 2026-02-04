#!/bin/bash

# Скрипт для диагностики переменных окружения в контейнере Medusa

echo "=== Проверка переменных окружения в контейнере medusa_backend ==="
echo ""

docker exec medusa_backend env | grep -E "(REDIS_URL|DATABASE_URL|JWT_SECRET|COOKIE_SECRET|ADMIN_CORS|AUTH_CORS|STORE_CORS)" | sort

echo ""
echo "=== Проверка подключения к Redis ==="
docker exec medusa_backend sh -c 'if [ -n "$REDIS_URL" ]; then echo "REDIS_URL=$REDIS_URL"; else echo "REDIS_URL не установлен"; fi'

echo ""
echo "=== Проверка подключения к PostgreSQL ==="
docker exec medusa_backend sh -c 'if [ -n "$DATABASE_URL" ]; then echo "DATABASE_URL=$DATABASE_URL"; else echo "DATABASE_URL не установлен"; fi'

echo ""
echo "=== Проверка сетевого соединения с Redis ==="
docker exec medusa_backend sh -c 'nc -zv redis 6379 2>&1 || echo "Не удалось подключиться к redis:6379"'

echo ""
echo "=== Проверка сетевого соединения с PostgreSQL ==="
docker exec medusa_backend sh -c 'nc -zv postgres 5432 2>&1 || echo "Не удалось подключиться к postgres:5432"'
