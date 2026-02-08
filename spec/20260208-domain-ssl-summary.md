# Итоговый отчёт: Настройка домена и SSL для Medusa

## ✅ Созданные файлы для настройки домена и SSL

### 1. NGINX_SETUP.md
**Файл**: [`medusa-storefront/NGINX_SETUP.md`](medusa-storefront/NGINX_SETUP.md)

Подробная инструкция по настройке Nginx reverse proxy:
- Установка Nginx и Certbot
- Получение SSL сертификата (Let's Encrypt)
- Создание конфигурации Nginx
- Настройка маршрутизации:
  - `example.com` → Frontend (порт 8000)
  - `example.com/admin` → Admin панель (порт 9000)
  - `example.com/api` → Backend API (порт 9000)
- Обновление переменных окружения
- Проверка работоспособности
- Troubleshooting

### 2. DOMAIN_SETUP.md
**Файл**: [`medusa-storefront/DOMAIN_SETUP.md`](medusa-storefront/DOMAIN_SETUP.md)

Быстрая инструкция по настройке домена и SSL:
- Покупка и настройка домена
- Проверка DNS
- Установка Nginx и SSL
- Обновление переменных окружения
- Перезапуск контейнеров
- Проверка работоспособности

### 3. Обновлён .env.production
**Файл**: [`medusa-storefront/.env.production`](medusa-storefront/.env.production)

Добавлены комментарии для настройки домена:
```env
# После настройки Nginx: https://example.com
# До настройки Nginx: http://88.218.67.164:8000
NEXT_PUBLIC_BASE_URL=http://88.218.67.164:8000

# После настройки Nginx: https://example.com/api
# До настройки Nginx: http://88.218.67.164:9000
MEDUSA_BACKEND_URL=http://88.218.67.164:9000
```

### 4. Обновлён DOCKER_README.md
**Файл**: [`medusa-storefront/DOCKER_README.md`](medusa-storefront/DOCKER_README.md)

Добавлен раздел "Следующие шаги" с двумя вариантами:
- Базовый деплой (без домена)
- Production деплой (с доменом и HTTPS)

### 5. NGINX_DOCKER.md
**Файл**: [`medusa-storefront/NGINX_DOCKER.md`](medusa-storefront/NGINX_DOCKER.md)

Инструкция по использованию Nginx в Docker контейнере:
- Когда использовать Nginx в Docker
- Получение SSL сертификатов
- Обновление конфигурации
- Запуск контейнеров
- Автоматическое обновление SSL
- Сравнение подходов (Nginx на хосте vs в Docker)

### 6. docker-compose-nginx.yml
**Файл**: [`medusa-storefront/docker-compose-nginx.yml`](medusa-storefront/docker-compose-nginx.yml)

Docker Compose конфигурация с Nginx reverse proxy:
- Frontend сервис
- Nginx сервис
- SSL сертификаты через volume
- Логи Nginx через volume
- Health checks

### 7. nginx/nginx.conf
**Файл**: [`medusa-storefront/nginx/nginx.conf`](medusa-storefront/nginx/nginx.conf)

Основная конфигурация Nginx для Docker:
- Worker processes
- Логирование
- Gzip сжатие
- Оптимизация

### 8. nginx/conf.d/medusa.conf
**Файл**: [`medusa-storefront/nginx/conf.d/medusa.conf`](medusa-storefront/nginx/conf.d/medusa.conf)

Конфигурация сайта для Nginx в Docker:
- HTTP → HTTPS перенаправление
- SSL настройки
- Frontend проксирование
- Health check endpoint
- Заголовки безопасности

## 🎯 Архитектура после настройки

```
Internet → Nginx (443/80) → Docker контейнеры
                              ├─ Frontend (8000)  → https://example.com
                              ├─ Admin (9000)      → https://example.com/admin
                              └─ Backend API (9000) → https://example.com/api (внутренний)
```

## 📋 Пошаговая инструкция

### Вариант 1: Nginx на хосте (рекомендуется)

#### Шаг 1: Настройка домена

1. Купите домен (например, example.com)
2. Добавьте A запись в DNS:
   - Host: `@` (или пусто)
   - Value: `88.218.67.164`
3. Добавьте A запись для www (опционально):
   - Host: `www`
   - Value: `88.218.67.164`
4. Подождите распространения DNS (1-24 часа)

#### Шаг 2: Установка Nginx и SSL

```bash
# Установка Nginx
sudo apt update
sudo apt install nginx -y

# Установка Certbot
sudo apt install certbot python3-certbot-nginx -y

# Получение SSL сертификата
sudo certbot --nginx -d example.com -d www.example.com
```

#### Шаг 3: Создание конфигурации Nginx

Создайте файл `/etc/nginx/sites-available/medusa` с конфигурацией из [`NGINX_SETUP.md`](medusa-storefront/NGINX_SETUP.md).

#### Шаг 4: Активация конфигурации

```bash
# Создание символической ссылки
sudo ln -s /etc/nginx/sites-available/medusa /etc/nginx/sites-enabled/

# Проверка конфигурации
sudo nginx -t

# Перезагрузка Nginx
sudo systemctl reload nginx
```

#### Шаг 5: Обновление переменных окружения

##### Frontend (`.env.production`)

```env
NEXT_PUBLIC_BASE_URL=https://example.com
MEDUSA_BACKEND_URL=https://example.com/api
```

##### Backend (`.env`)

```env
STORE_CORS=https://example.com,https://www.example.com
ADMIN_CORS=https://example.com,https://www.example.com
AUTH_CORS=https://example.com,https://www.example.com
```

#### Шаг 6: Перезапуск контейнеров

```bash
# Frontend
cd /path/to/medusa-storefront
./deploy.sh

# Backend
cd /path/to/medusa-store
docker-compose down
docker-compose up -d
```

#### Шаг 7: Проверка

Откройте в браузере:
- ✅ `https://example.com` - Frontend
- ✅ `https://example.com/admin` - Admin панель
- ✅ `https://www.example.com` - Frontend (с www)

### Вариант 2: Nginx в Docker

#### Шаг 1: Настройка домена

1. Купите домен (например, example.com)
2. Добавьте A запись в DNS:
   - Host: `@` (или пусто)
   - Value: `88.218.67.164`
3. Добавьте A запись для www (опционально):
   - Host: `www`
   - Value: `88.218.67.164`
4. Подождите распространения DNS (1-24 часа)

#### Шаг 2: Получение SSL сертификатов

См. [`NGINX_DOCKER.md`](medusa-storefront/NGINX_DOCKER.md) для подробной инструкции.

#### Шаг 3: Настройка конфигурации

Отредактируйте `nginx/conf.d/medusa.conf`, заменив `example.com` на ваш домен.

#### Шаг 4: Обновление переменных окружения

##### Frontend (`.env.production`)

```env
NEXT_PUBLIC_BASE_URL=https://example.com
MEDUSA_BACKEND_URL=https://example.com/api
```

##### Backend (`.env`)

```env
STORE_CORS=https://example.com,https://www.example.com
ADMIN_CORS=https://example.com,https://www.example.com
AUTH_CORS=https://example.com,https://www.example.com
```

#### Шаг 5: Запуск контейнеров

```bash
# Запуск с Nginx в Docker
docker-compose -f docker-compose-nginx.yml up -d

# Проверка статуса
docker-compose -f docker-compose-nginx.yml ps
```

#### Шаг 6: Проверка

Откройте в браузере:
- ✅ `https://example.com` - Frontend
- ✅ `https://www.example.com` - Frontend (с www)

## 🔒 Преимущества Nginx Reverse Proxy

1. **SSL/TLS терминирование** - Nginx обрабатывает HTTPS сертификаты
2. **Маршрутизация** - Единая точка входа для всех сервисов
3. **Безопасность** - Скрытие внутренних портов от внешнего доступа
4. **Производительность** - Кэширование, сжатие, оптимизация
5. **Гибкость** - Легко добавлять новые сервисы

## 📚 Документация

- [`NGINX_SETUP.md`](medusa-storefront/NGINX_SETUP.md) - Подробная инструкция по Nginx
- [`DOMAIN_SETUP.md`](medusa-storefront/DOMAIN_SETUP.md) - Быстрая инструкция по домену и SSL
- [`DOCKER_README.md`](medusa-storefront/DOCKER_README.md) - Docker документация
- [`DEPLOYMENT.md`](medusa-storefront/DEPLOYMENT.md) - Инструкция по деплою

## 🔧 Полезные команды

```bash
# Проверка статуса Nginx
sudo systemctl status nginx

# Проверка конфигурации Nginx
sudo nginx -t

# Перезагрузка Nginx
sudo systemctl reload nginx

# Проверка SSL сертификата
sudo certbot certificates

# Тестовое обновление сертификата
sudo certbot renew --dry-run

# Просмотр логов Nginx
sudo tail -f /var/log/nginx/medusa_access.log
sudo tail -f /var/log/nginx/medusa_error.log
```

## ⚠️ Важные замечания

1. **DNS распространение** - Может занять до 24 часов
2. **SSL сертификат** - Действителен 90 дней, обновляется автоматически
3. **Firewall** - Убедитесь, что порты 80 и 443 открыты
4. **CORS** - Обновите CORS настройки после смены домена
5. **Backend извне не нужен** - Доступ к backend только через Nginx

## 🆘 Troubleshooting

### DNS не распространяется

- Подождите до 24 часов
- Проверьте правильность A записи
- Очистите кэш DNS: `sudo systemd-resolve --flush-caches`

### SSL сертификат не получается

- Убедитесь, что DNS настроен правильно
- Проверьте, что порт 80 открыт: `sudo ufw status`
- Попробуйте standalone режим: `sudo certbot certonly --standalone -d example.com`

### Сайт не открывается

- Проверьте статус Nginx: `sudo systemctl status nginx`
- Проверьте логи: `sudo tail -f /var/log/nginx/medusa_error.log`
- Проверьте статус контейнеров: `docker ps`

## ✅ Готово!

После выполнения этих шагов ваш проект будет доступен по домену с HTTPS сертификатом!

## 📝 Сводка всех созданных файлов

### Docker контейнеризация (предыдущий этап)
1. [`Dockerfile`](medusa-storefront/Dockerfile) - Multi-stage build
2. [`.dockerignore`](medusa-storefront/.dockerignore) - Исключения для Docker
3. [`docker-compose.yml`](medusa-storefront/docker-compose.yml) - Конфигурация контейнера
4. [`.env.production`](medusa-storefront/.env.production) - Production переменные
5. [`deploy.sh`](medusa-storefront/deploy.sh) - Скрипт деплоя
6. [`DEPLOYMENT.md`](medusa-storefront/DEPLOYMENT.md) - Инструкция по деплою
7. [`DOCKER.md`](medusa-storefront/DOCKER.md) - Docker документация
8. [`DOCKER_README.md`](medusa-storefront/DOCKER_README.md) - Быстрый старт

### Настройка домена и SSL (текущий этап)
9. [`NGINX_SETUP.md`](medusa-storefront/NGINX_SETUP.md) - Инструкция по Nginx
10. [`DOMAIN_SETUP.md`](medusa-storefront/DOMAIN_SETUP.md) - Быстрая инструкция по домену

### Обновлённые файлы
1. [`next.config.js`](medusa-storefront/next.config.js) - Добавлен `output: 'standalone'`
2. [`.gitignore`](medusa-storefront/.gitignore) - Добавлен `.env.production`
3. [`medusa-store/.env`](medusa-store/.env) - Обновлены CORS настройки

## 🎉 Итог

Проект полностью подготовлен для:
- ✅ Работы в Docker контейнерах
- ✅ Деплоя на VPS через GitHub
- ✅ Настройки домена и SSL сертификата
- ✅ Доступа к frontend по домену
- ✅ Доступа к admin панели по домену/admin
- ✅ Безопасного HTTPS соединения

Все комментарии в коде и документация на русском языке.
