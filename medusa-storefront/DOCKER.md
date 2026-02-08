# Docker для Medusa Frontend

## Обзор

Этот документ описывает использование Docker для локальной разработки и production деплоя Medusa Next.js Frontend.

## Структура Docker

### Multi-stage Build

Dockerfile использует multi-stage build для оптимизации размера образа:

1. **Dependencies Stage** - Установка зависимостей
2. **Builder Stage** - Сборка Next.js приложения
3. **Runner Stage** - Production runtime

Это позволяет:
- Минимизировать размер финального образа
- Отделять зависимости от исходного кода
- Использовать разные базовые образы для разных этапов

## Локальная разработка

### Запуск в Docker

```bash
# Сборка и запуск
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

### Переменные окружения для разработки

Создайте `.env.local` для локальной разработки:

```env
MEDUSA_BACKEND_URL=http://localhost:9000
NEXT_PUBLIC_BASE_URL=http://localhost:8000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_test
NEXT_PUBLIC_DEFAULT_REGION=eu
REVALIDATE_SECRET=dev-secret
```

### Горячая перезагрузка

Для горячей перезагрузки в Docker можно использовать volume mounts:

```yaml
volumes:
  - .:/app
  - /app/node_modules
  - /app/.next
```

Однако для production это не рекомендуется.

## Production

### Сборка образа

```bash
# Сборка с кэшем
docker-compose build

# Сборка без кэша
docker-compose build --no-cache
```

### Запуск в production

```bash
# Запуск
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f
```

### Health Check

Контейнер включает health check для проверки работоспособности:

```bash
# Проверка health status
docker inspect medusa_frontend | grep -A 10 Health
```

Health check проверяет HTTP ответ на `http://localhost:8000`.

## Управление образами

### Просмотр образов

```bash
docker images | grep medusa
```

### Удаление старых образов

```bash
# Удаление неиспользуемых образов
docker image prune -f

# Удаление всех неиспользуемых образов
docker image prune -a -f
```

### Тегирование образов

```bash
# Тегирование для production
docker tag medusa-storefront-frontend:latest medusa-storefront-frontend:v1.0.0

# Пуш в registry (если используется)
docker push ваш-registry/medusa-storefront-frontend:v1.0.0
```

## Управление контейнерами

### Просмотр контейнеров

```bash
# Все контейнеры
docker ps -a

# Только запущенные
docker ps

# Фильтр по имени
docker ps -f name=medusa_frontend
```

### Вход в контейнер

```bash
# Вход в shell
docker-compose exec frontend sh

# Вход в Node.js REPL
docker-compose exec frontend node
```

### Перезапуск контейнера

```bash
# Перезапуск
docker-compose restart

# Перезапуск с пересборкой
docker-compose up -d --force-recreate
```

### Очистка

```bash
# Остановка и удаление контейнеров
docker-compose down

# Остановка с удалением volumes
docker-compose down -v

# Полная очистка (осторожно!)
docker-compose down -v --rmi all
```

## Логирование

### Просмотр логов

```bash
# Все логи
docker-compose logs

# Логи в реальном времени
docker-compose logs -f

# Последние N строк
docker-compose logs --tail=100

# Логи конкретного сервиса
docker-compose logs frontend
```

### Конфигурация логирования

Логи настроены в `docker-compose.yml`:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

Это ограничивает размер логов до 10MB на файл, максимум 3 файла.

## Сети

### Просмотр сетей

```bash
docker network ls
docker network inspect medusa_network
```

### Подключение к сети

Frontend подключается к сети `medusa_network` для связи с backend:

```yaml
networks:
  medusa_network:
    external: true
    name: medusa_network
```

## Производительность

### Оптимизация размера образа

Multi-stage build уже оптимизирует размер. Дополнительные советы:

1. Используйте Alpine Linux (уже используется)
2. Минимизируйте количество слоёв
3. Используйте `.dockerignore`
4. Кэшируйте зависимости

### Ресурсы контейнера

Можно ограничить ресурсы в `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

## Безопасность

### Запуск от имени не-root пользователя

Контейнер запускается от пользователя `nextjs` (UID 1001):

```dockerfile
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs
```

### Переменные окружения

Не храните секреты в коде. Используйте `.env.production`:

```bash
# Генерация случайного секрета
openssl rand -base64 32
```

### Сканирование уязвимостей

```bash
# Сканирование образа
docker scan medusa-storefront-frontend:latest
```

## Troubleshooting

### Контейнер не запускается

1. Проверьте логи:
   ```bash
   docker-compose logs
   ```

2. Проверьте конфигурацию:
   ```bash
   docker-compose config
   ```

3. Проверьте наличие `.env.production`:
   ```bash
   ls -la .env.production
   ```

### Ошибки сборки

1. Очистите кэш:
   ```bash
   docker system prune -a
   ```

2. Пересоберите без кэша:
   ```bash
   docker-compose build --no-cache
   ```

### Проблемы с сетью

1. Проверьте сеть:
   ```bash
   docker network inspect medusa_network
   ```

2. Проверьте подключение к backend:
   ```bash
   docker-compose exec frontend ping medusa_backend
   ```

## Полезные команды

```bash
# Статистика контейнера
docker stats medusa_frontend

# Использование диска
docker system df

# Информация о контейнере
docker inspect medusa_frontend

# Копирование файлов из контейнера
docker cp medusa_frontend:/app/package.json ./

# Копирование файлов в контейнер
docker cp ./file.txt medusa_frontend:/app/
```

## Дополнительные ресурсы

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Medusa Documentation](https://docs.medusajs.com/)

## Связанная документация

- [DEPLOYMENT.md](DEPLOYMENT.md) - Инструкция по деплою на VPS
- [README.md](README.md) - Общая документация проекта
