# Использование Nginx в Docker для Medusa

## Обзор

Эта инструкция описывает использование Nginx reverse proxy в Docker контейнере вместо установки на хост.

## Когда использовать Nginx в Docker?

### Преимущества:
- ✅ Все сервисы в одном месте (Docker)
- ✅ Единое управление через docker-compose
- ✅ Простота деплоя - один `docker-compose up`
- ✅ Изоляция сервисов

### Недостатки:
- ❌ Сложнее настройка SSL сертификатов
- ❌ Требуется копирование сертификатов в volume
- ❌ Certbot не работает внутри контейнера

## Рекомендация

**Используйте Nginx на хосте** (см. [`NGINX_SETUP.md`](NGINX_SETUP.md)) если:
- У вас нет домена или SSL сертификата
- Вы хотите использовать Certbot для автоматического получения сертификатов
- Вам нужна простая настройка

**Используйте Nginx в Docker** если:
- У вас уже есть SSL сертификаты
- Вы хотите все сервисы в Docker
- Вы используете внешний сервис для SSL (Cloudflare, AWS ACM, etc.)

## Структура файлов

```
medusa-storefront/
├── docker-compose-nginx.yml    # Docker Compose с Nginx
├── nginx/
│   ├── nginx.conf             # Основная конфигурация Nginx
│   ├── conf.d/
│   │   └── medusa.conf      # Конфигурация сайта
│   └── ssl/                 # SSL сертификаты (создайте вручную)
│       ├── fullchain.pem       # SSL сертификат
│       └── privkey.pem        # Приватный ключ
└── .env.production           # Переменные окружения
```

## Шаг 1: Получение SSL сертификатов

### Вариант A: Certbot на хосте (рекомендуется)

```bash
# Установка Certbot
sudo apt install certbot -y

# Получение сертификата
sudo certbot certonly --standalone -d example.com -d www.example.com

# Копирование сертификатов в проект
sudo cp /etc/letsencrypt/live/example.com/fullchain.pem /path/to/medusa-storefront/nginx/ssl/
sudo cp /etc/letsencrypt/live/example.com/privkey.pem /path/to/medusa-storefront/nginx/ssl/

# Установка прав доступа
sudo chown -R $USER:$USER /path/to/medusa-storefront/nginx/ssl/
chmod 600 /path/to/medusa-storefront/nginx/ssl/privkey.pem
```

### Вариант B: Самоподписанные сертификаты (для тестирования)

```bash
# Создание директории
mkdir -p nginx/ssl

# Генерация самоподписанного сертификата
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/privkey.pem \
  -out nginx/ssl/fullchain.pem \
  -subj "/C=RU/ST=State/L=City/O=Organization/CN=example.com"
```

### Вариант C: Внешний SSL (Cloudflare, AWS ACM, etc.)

Если вы используете Cloudflare или другой сервис:
1. Получите сертификаты от сервиса
2. Сохраните в `nginx/ssl/`
3. Настройте DNS на IP VPS

## Шаг 2: Обновление конфигурации

Отредактируйте `nginx/conf.d/medusa.conf`:

```bash
nano nginx/conf.d/medusa.conf
```

Замените `example.com` на ваш домен:

```nginx
server_name ваш-домен.com www.ваш-домен.com;
```

## Шаг 3: Обновление переменных окружения

Отредактируйте `.env.production`:

```bash
nano .env.production
```

Измените:

```env
NEXT_PUBLIC_BASE_URL=https://ваш-домен.com
MEDUSA_BACKEND_URL=https://ваш-домен.com/api
```

## Шаг 4: Запуск контейнеров

```bash
# Запуск с Nginx
docker-compose -f docker-compose-nginx.yml up -d

# Просмотр логов
docker-compose -f docker-compose-nginx.yml logs -f

# Проверка статуса
docker-compose -f docker-compose-nginx.yml ps
```

## Шаг 5: Проверка работоспособности

```bash
# Проверка Nginx
curl http://localhost/health

# Проверка SSL
curl -I https://ваш-домен.com

# Проверка Frontend
curl https://ваш-домен.com
```

Откройте в браузере:
- ✅ `https://ваш-домен.com` - Frontend
- ✅ `https://www.ваш-домен.com` - Frontend (с www)

## Управление контейнерами

```bash
# Остановка
docker-compose -f docker-compose-nginx.yml down

# Перезапуск
docker-compose -f docker-compose-nginx.yml restart

# Просмотр логов
docker-compose -f docker-compose-nginx.yml logs -f nginx

# Просмотр логов Frontend
docker-compose -f docker-compose-nginx.yml logs -f frontend

# Вход в контейнер Nginx
docker-compose -f docker-compose-nginx.yml exec nginx sh
```

## Обновление SSL сертификатов

### Автоматическое обновление (Certbot на хосте)

```bash
# Создайте скрипт обновления
nano /path/to/medusa-storefront/update-ssl.sh
```

```bash
#!/bin/bash
# Скрипт обновления SSL сертификатов

# Обновление сертификата
sudo certbot renew --quiet

# Копирование новых сертификатов
sudo cp /etc/letsencrypt/live/example.com/fullchain.pem /path/to/medusa-storefront/nginx/ssl/
sudo cp /etc/letsencrypt/live/example.com/privkey.pem /path/to/medusa-storefront/nginx/ssl/

# Перезагрузка Nginx в контейнере
docker-compose -f /path/to/medusa-storefront/docker-compose-nginx.yml restart nginx
```

```bash
# Сделайте исполняемым
chmod +x /path/to/medusa-storefront/update-ssl.sh

# Добавьте в cron для автоматического обновления
sudo crontab -e
```

Добавьте строку:

```
0 0 * * * /path/to/medusa-storefront/update-ssl.sh >> /var/log/ssl-update.log 2>&1
```

## Troubleshooting

### Nginx не запускается

```bash
# Проверьте логи
docker-compose -f docker-compose-nginx.yml logs nginx

# Проверьте конфигурацию
docker-compose -f docker-compose-nginx.yml exec nginx nginx -t

# Проверьте наличие сертификатов
ls -la nginx/ssl/
```

### SSL ошибки

```bash
# Проверьте права доступа
ls -la nginx/ssl/

# Проверьте содержимое сертификатов
openssl x509 -in nginx/ssl/fullchain.pem -text -noout

# Проверьте приватный ключ
openssl rsa -in nginx/ssl/privkey.pem -check
```

### Контейнеры не видят друг друга

```bash
# Проверьте сеть
docker network inspect medusa_network

# Проверьте, что контейнеры в одной сети
docker ps --format "table {{.Names}}\t{{.Networks}}"
```

## Сравнение подходов

| Характеристика | Nginx на хосте | Nginx в Docker |
|----------------|------------------|----------------|
| Простота настройки | ✅ Высокая | ⚠️ Средняя |
| SSL с Certbot | ✅ Автоматический | ❌ Ручной |
| Управление | ⚠️ Отдельно | ✅ Единое |
| Изоляция | ⚠️ Частичная | ✅ Полная |
| Ресурсы | ⚠️ На хосте | ✅ В контейнере |

## Рекомендация

Для production с доменом и SSL:
1. **Используйте Nginx на хосте** (см. [`NGINX_SETUP.md`](NGINX_SETUP.md))
   - Проще настройка
   - Автоматическое обновление SSL
   - Проверенное решение

Для тестирования или без домена:
1. **Используйте docker-compose.yml** (без Nginx)
   - Прямой доступ к портам
   - Без SSL
   - Для разработки

## Дополнительная документация

- [`NGINX_SETUP.md`](NGINX_SETUP.md) - Nginx на хосте (рекомендуется)
- [`DOCKER_README.md`](DOCKER_README.md) - Docker документация
- [`DOMAIN_SETUP.md`](DOMAIN_SETUP.md) - Настройка домена и SSL
