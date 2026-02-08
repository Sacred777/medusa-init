# Инструкция по деплою Medusa Frontend на VPS

## Обзор

Этот документ описывает процесс деплоя Medusa Next.js Frontend на VPS с использованием Docker и Docker Compose.

## Предварительные требования

На VPS должны быть установлены:

- **Docker** (версия 20.10 или выше)
- **Docker Compose** (версия 2.0 или выше)
- **Git**
- **SSH доступ**

### Проверка установки

```bash
# Проверка Docker
docker --version

# Проверка Docker Compose
docker-compose --version

# Проверка Git
git --version
```

## Настройка на VPS

### 1. Клонирование репозитория

```bash
# Клонируйте репозиторий
git clone https://github.com/ваш-username/ваш-репозиторий.git
cd ваш-репозиторий/medusa-storefront
```

### 2. Создание .env.production

Создайте файл `.env.production` на основе `.env.template`:

```bash
cp .env.template .env.production
```

Отредактируйте `.env.production`:

```bash
nano .env.production
```

Обязательно установите следующие переменные:

```env
# Backend URL
MEDUSA_BACKEND_URL=http://88.218.67.164:9000

# Frontend URL
NEXT_PUBLIC_BASE_URL=http://88.218.67.164:8000

# Publishable API ключ
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=ваш-ключ

# Секрет для revalidation (измените на случайную строку!)
REVALIDATE_SECRET=ваш-случайный-секрет
```

**Важно**: Файл `.env.production` не должен коммититься в Git!

### 3. Создание Docker сети

Если сеть `medusa_network` ещё не создана (должна быть создана backend):

```bash
docker network create medusa_network
```

### 4. Проверка CORS настроек в Backend

Убедитесь, что backend разрешает запросы с frontend URL.

В файле `medusa-store/medusa-config.ts` добавьте:

```typescript
http: {
  storeCors: ["http://88.218.67.164:8000", "http://localhost:8000"],
  adminCors: ["http://88.218.67.164:8000", "http://localhost:8000"],
  // ... остальные настройки
}
```

## Деплой

### Автоматический деплой

Используйте скрипт `deploy.sh` для автоматического деплоя:

```bash
./deploy.sh
```

Скрипт выполнит следующие действия:
1. Проверит наличие `.env.production`
2. Остановит существующие контейнеры
3. Получит изменения из GitHub
4. Соберёт новый Docker образ
5. Запустит контейнеры
6. Очистит старые образы
7. Покажет статус и логи

### Ручной деплой

Если вы предпочитаете ручной деплой:

```bash
# 1. Получите изменения из GitHub
git pull origin main

# 2. Остановите существующие контейнеры
docker-compose down

# 3. Соберите новый образ
docker-compose build --no-cache

# 4. Запустите контейнеры
docker-compose up -d

# 5. Проверьте статус
docker-compose ps

# 6. Посмотрите логи
docker-compose logs -f
```

## Управление контейнерами

### Просмотр статуса

```bash
docker-compose ps
```

### Просмотр логов

```bash
# Все логи
docker-compose logs

# Логи в реальном времени
docker-compose logs -f

# Последние 50 строк
docker-compose logs --tail=50
```

### Остановка контейнеров

```bash
# Остановка
docker-compose down

# Остановка с удалением volumes
docker-compose down -v
```

### Перезапуск контейнеров

```bash
docker-compose restart
```

### Обновление контейнера

```bash
# Получить изменения
git pull origin main

# Пересобрать и перезапустить
docker-compose up -d --build
```

## Проверка работоспособности

### 1. Проверка контейнера

```bash
docker-compose ps
```

Контейнер должен быть в статусе `Up`.

### 2. Проверка логов

```bash
docker-compose logs
```

Не должно быть ошибок.

### 3. Проверка HTTP ответа

```bash
curl http://localhost:8000
```

Должен вернуться HTML код страницы.

### 4. Проверка Health Check

```bash
docker inspect medusa_frontend | grep -A 10 Health
```

Статус должен быть `healthy`.

## Troubleshooting

### Контейнер не запускается

1. Проверьте логи:
   ```bash
   docker-compose logs
   ```

2. Проверьте наличие `.env.production`:
   ```bash
   ls -la .env.production
   ```

3. Проверьте переменные окружения:
   ```bash
   docker-compose config
   ```

### Ошибки подключения к Backend

1. Проверьте, что backend запущен:
   ```bash
   docker ps | grep medusa_backend
   ```

2. Проверьте сеть:
   ```bash
   docker network inspect medusa_network
   ```

3. Проверьте CORS настройки в backend.

### Ошибки сборки

1. Очистите кэш Docker:
   ```bash
   docker system prune -a
   ```

2. Пересоберите без кэша:
   ```bash
   docker-compose build --no-cache
   ```

### Проблемы с портами

1. Проверьте, что порт 8000 не занят:
   ```bash
   netstat -tlnp | grep 8000
   ```

2. Если занят, остановите процесс или измените порт в `docker-compose.yml`.

## Безопасность

### Изменение REVALIDATE_SECRET

Всегда используйте случайный секрет для production:

```bash
# Генерация случайного секрета
openssl rand -base64 32
```

### Ограничение доступа

Рассмотрите использование:
- Firewall для ограничения доступа к портам
- HTTPS с SSL сертификатом (например, Let's Encrypt)
- Nginx как reverse proxy

### Обновления

Регулярно обновляйте:
- Docker образы
- Зависимости npm/yarn
- Операционную систему VPS

## Мониторинг

### Просмотр использования ресурсов

```bash
# Статистика контейнера
docker stats medusa_frontend

# Использование диска
docker system df
```

### Логи

Логи хранятся в Docker и ограничены по размеру (10MB, 3 файла).

Для постоянного логирования рассмотрите использование:
- Docker logging drivers
- Внешние системы логирования (ELK, Loki, etc.)

## Полезные команды

```bash
# Войти в контейнер
docker-compose exec frontend sh

# Перезапустить только frontend
docker-compose restart frontend

# Удалить старые образы
docker image prune -f

# Полная очистка Docker (осторожно!)
docker system prune -a --volumes
```

## Поддержка

При возникновении проблем:

1. Проверьте логи: `docker-compose logs`
2. Проверьте статус: `docker-compose ps`
3. Проверьте документацию Medusa: https://docs.medusajs.com
4. Проверьте документацию Next.js: https://nextjs.org/docs
