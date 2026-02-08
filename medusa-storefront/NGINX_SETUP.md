# Настройка Nginx Reverse Proxy для Medusa

## Обзор

Эта инструкция описывает настройку Nginx reverse proxy для Medusa проекта после покупки домена и установки SSL сертификата.

## Архитектура

```
Internet → Nginx (443/80) → Docker контейнеры
                              ├─ Frontend (8000)  → example.com
                              ├─ Admin (9000)      → example.com/admin
                              └─ Backend API (9000) → example.com/api
```

## Предварительные требования

1. **Домен** - Купленный и настроенный на ваш VPS IP (88.218.67.164)
2. **Docker и Docker Compose** - Установлены на VPS
3. **Nginx** - Установлен на VPS
4. **SSL сертификат** - Let's Encrypt (бесплатный) или другой

## Шаг 1: Установка Nginx

```bash
# Обновление пакетов
sudo apt update

# Установка Nginx
sudo apt install nginx -y

# Проверка статуса
sudo systemctl status nginx

# Разрешение Nginx в firewall
sudo ufw allow 'Nginx Full'
```

## Шаг 2: Установка Certbot для SSL

```bash
# Установка Certbot
sudo apt install certbot python3-certbot-nginx -y

# Проверка установки
certbot --version
```

## Шаг 3: Получение SSL сертификата

### Вариант A: Если домен уже настроен на VPS

```bash
# Получение сертификата (замените example.com на ваш домен)
sudo certbot --nginx -d example.com -d www.example.com

# Следуйте инструкциям:
# - Введите email для уведомлений
# - Согласитесь с условиями использования
# - Выберите перенаправление HTTP на HTTPS
```

### Вариант B: Если домен ещё не настроен

```bash
# Получение сертификата в standalone режиме
sudo certbot certonly --standalone -d example.com -d www.example.com

# После настройки DNS запустите:
sudo certbot --nginx -d example.com -d www.example.com
```

### Проверка сертификата

```bash
# Проверка статуса сертификата
sudo certbot certificates

# Автоматическое обновление (уже настроено)
sudo systemctl status certbot.timer
```

## Шаг 4: Создание конфигурации Nginx

Создайте файл конфигурации:

```bash
sudo nano /etc/nginx/sites-available/medusa
```

Вставьте следующую конфигурацию (замените `example.com` на ваш домен):

```nginx
# Upstream для Docker контейнеров
upstream frontend {
    server 127.0.0.1:8000;
}

upstream backend {
    server 127.0.0.1:9000;
}

# HTTP → HTTPS перенаправление
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;

    # Перенаправление на HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;

    # SSL сертификаты (Certbot автоматически обновит пути)
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # SSL настройки
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Логи
    access_log /var/log/nginx/medusa_access.log;
    error_log /var/log/nginx/medusa_error.log;

    # Frontend (Next.js)
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Admin панель (Medusa)
    location /admin {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Backend API
    location /api {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check (опционально)
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

## Шаг 5: Активация конфигурации

```bash
# Создание символической ссылки
sudo ln -s /etc/nginx/sites-available/medusa /etc/nginx/sites-enabled/

# Удаление стандартной конфигурации (опционально)
sudo rm /etc/nginx/sites-enabled/default

# Проверка конфигурации
sudo nginx -t

# Перезагрузка Nginx
sudo systemctl reload nginx
```

## Шаг 6: Обновление переменных окружения

### Обновление .env.production в Frontend

```bash
cd /path/to/medusa-storefront
nano .env.production
```

Измените:

```env
# Frontend URL
NEXT_PUBLIC_BASE_URL=https://example.com

# Backend URL (через Nginx)
MEDUSA_BACKEND_URL=https://example.com/api
```

### Обновление .env в Backend

```bash
cd /path/to/medusa-store
nano .env
```

Измените CORS настройки:

```env
STORE_CORS=https://example.com,https://www.example.com
ADMIN_CORS=https://example.com,https://www.example.com
AUTH_CORS=https://example.com,https://www.example.com
```

## Шаг 7: Перезапуск контейнеров

```bash
# Перезапуск frontend
cd /path/to/medusa-storefront
docker-compose down
docker-compose up -d

# Перезапуск backend
cd /path/to/medusa-store
docker-compose down
docker-compose up -d
```

## Шаг 8: Проверка работоспособности

### Проверка Nginx

```bash
# Проверка статуса
sudo systemctl status nginx

# Проверка конфигурации
sudo nginx -t

# Просмотр логов
sudo tail -f /var/log/nginx/medusa_access.log
sudo tail -f /var/log/nginx/medusa_error.log
```

### Проверка доступа

Откройте в браузере:

- `https://example.com` - Frontend
- `https://example.com/admin` - Admin панель
- `https://example.com/api/health` - Backend API health check

### Проверка SSL

```bash
# Проверка сертификата
curl -I https://example.com

# Проверка SSL рейтинга
# https://www.ssllabs.com/ssltest/analyze.html?d=example.com
```

## Шаг 9: Настройка автоматического обновления SSL

Certbot автоматически настраивает cron задачу для обновления сертификатов. Проверьте:

```bash
# Проверка таймера
sudo systemctl status certbot.timer

# Проверка cron задачи
sudo crontab -l | grep certbot

# Тестовое обновление
sudo certbot renew --dry-run
```

## Шаг 10: Настройка firewall

```bash
# Разрешение HTTP и HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Блокировка прямого доступа к портам контейнеров (опционально)
sudo ufw deny 8000/tcp
sudo ufw deny 9000/tcp

# Проверка статуса
sudo ufw status
```

## Troubleshooting

### Nginx не запускается

```bash
# Проверка конфигурации
sudo nginx -t

# Просмотр логов ошибок
sudo tail -f /var/log/nginx/error.log

# Проверка занятости портов
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### SSL сертификат не работает

```bash
# Проверка сертификата
sudo certbot certificates

# Получение нового сертификата
sudo certbot --nginx -d example.com -d www.example.com --force-renewal

# Проверка прав доступа
sudo ls -la /etc/letsencrypt/live/example.com/
```

### Контейнеры недоступны

```bash
# Проверка статуса контейнеров
docker ps

# Проверка логов контейнеров
docker logs medusa_frontend
docker logs medusa_backend

# Проверка сети
docker network inspect medusa_network
```

### CORS ошибки

```bash
# Проверьте CORS настройки в backend .env
cat /path/to/medusa-store/.env | grep CORS

# Проверьте заголовки в браузере (F12 → Network)
# Должен быть заголовок Access-Control-Allow-Origin
```

## Мониторинг

### Логи Nginx

```bash
# Access логи
sudo tail -f /var/log/nginx/medusa_access.log

# Error логи
sudo tail -f /var/log/nginx/medusa_error.log
```

### Статистика Nginx

```bash
# Установка утилиты
sudo apt install nginx-common -y

# Просмотр статистики
sudo nginx -V 2>&1 | grep -o with-http_stub_status_module

# Добавьте в конфигурацию для детальной статистики
```

## Безопасность

### Регулярное обновление

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Обновление Nginx
sudo apt install nginx --only-upgrade -y
```

### Резервное копирование

```bash
# Резервное копирование конфигурации Nginx
sudo cp /etc/nginx/sites-available/medusa ~/medusa-nginx-backup.conf

# Резервное копирование SSL сертификатов
sudo tar -czf ~/letsencrypt-backup.tar.gz /etc/letsencrypt/
```

## Полезные команды

```bash
# Перезагрузка Nginx (без разрыва соединений)
sudo systemctl reload nginx

# Перезапуск Nginx
sudo systemctl restart nginx

# Проверка статуса
sudo systemctl status nginx

# Просмотр конфигурации
sudo nginx -T

# Тестирование конфигурации
sudo nginx -t
```

## Дополнительные ресурсы

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Medusa Documentation](https://docs.medusajs.com/)

## Следующие шаги

1. ✅ Установить Nginx
2. ✅ Получить SSL сертификат
3. ✅ Настроить конфигурацию Nginx
4. ✅ Обновить переменные окружения
5. ✅ Перезапустить контейнеры
6. ✅ Проверить работоспособность
7. ✅ Настроить мониторинг

После выполнения этих шагов ваш проект будет доступен по домену с HTTPS!
