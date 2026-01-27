# Medusa E-commerce Platform

Этот проект представляет собой полнофункциональную e-commerce платформу, состоящую из бэкенд-сервера Medusa и Next.js storefront фронтенда. Архитектура построена с использованием современных технологий и рекомендаций от команды Medusa.

## Требования к системе

- **Node.js** >= 20.x
- **Yarn** >= 1.22.x (рекомендуется использовать Yarn Berry)
- **Docker** и **Docker Compose** (для запуска бэкенда в контейнерах)
- **Git** >= 2.x

## Структура проекта

Проект состоит из двух основных компонентов:

### 1. medusa-store (бэкенд)
- **Фреймворк**: MedusaJS v2.12.6
- **База данных**: PostgreSQL (в Docker контейнере)
- **Кэширование**: Redis (в Docker контейнере)
- **Админ панель**: Встроенная в Medusa
- **Конфигурация**: Docker Compose для локального запуска

### 2. medusa-storefront (фронтенд)
- **Фреймворк**: Next.js 15.3.8 (App Router)
- **Стили**: Tailwind CSS
- **UI Компоненты**: @medusajs/ui
- **SDK**: @medusajs/js-sdk

## Установка и запуск

### 1. Клонирование репозитория

```sh
git clone <URL_РЕПОЗИТОРИЯ>
cd medusa-init
```

### 2. Установка зависимостей для бэкенда

Перейдите в директорию `medusa-store` и установите зависимости:

```sh
cd medusa-store
yarn install
```

### 3. Запуск бэкенда в Docker

Сделайте копию конфигурационного файла:
```sh
cp .env.template .env
```
В .env файле нужно закомментировать (удалить) строки с переменными среды:
```sh
# REDIS_URL=
# DATABASE_URL=
# DB_NAME=
```
т.к. эти переменные определены в docker-compose.yml

Выполните следующую команду для запуска всех необходимых сервисов (PostgreSQL, Redis и Medusa сервер):

```sh
yarn docker:up
```

Для просмотра логов выполните:

```sh
docker compose logs -f
```

Когда вы увидите сообщение:

```
✔ Server is ready on port: 9000 - 3ms
info:    Admin URL → http://localhost:9000/app
```

значит, сервер успешно запущен.

### 4. Создание администратора

Если все контейнеры запущены (PostgreSQL, Redis и Medusa), можно создать администратора, если нет - запустите контейнеры:

```sh
yarn docker:up
```

Затем создайте пользователя с правами администратора:

```sh
docker compose exec medusa yarn medusa user -e admin@example.com -p supersecret
```

Замените `admin@example.com` и `supersecret` на желаемый email и пароль.

### 5. Получение публичного ключа

1. Войдите в панель администратора Medusa по адресу [http://localhost:9000/app](http://localhost:9000/app) с использованием созданных учетных данных.
2. Перейдите в раздел `Настройки` → `Общедоступные ключи API`.
3. Нажмите `Создать ключ`, дайте ему имя (например, "Storefront Key") и скопируйте сгенерированный публичный ключ.

### 6. Настройка storefront

#### Установка зависимостей

Перейдите в директорию `medusa-storefront` и установите зависимости:

```sh
cd ../medusa-storefront
yarn install
```

#### Конфигурация переменных окружения

Скопируйте шаблон файла конфигурации:

```sh
cp .env.template .env.local
```

Откройте файл `.env.local` и обновите следующие переменные:

```env
# URL вашего Medusa бэкенда
MEDUSA_BACKEND_URL=http://localhost:9000

# Публичный ключ, полученный из админ панели
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=скопированный_публичный_ключ

# Базовый URL для вашего storefront
NEXT_PUBLIC_BASE_URL=http://localhost:8000

# Регион по умолчанию (ISO-2 lowercase format)
NEXT_PUBLIC_DEFAULT_REGION=us
```

### 7. Запуск storefront

Запустите storefront в режиме разработки:

```sh
yarn dev
```

После запуска storefront будет доступен по адресу [http://localhost:8000](http://localhost:8000).

## Переменные окружения

### medusa-store

Файл `.env` содержит переменные для конфигурации Medusa сервера. Основные переменные:

- `DATABASE_URL` - строка подключения к базе данных
- `REDIS_URL` - строка подключения к Redis
- `JWT_SECRET` - секрет для JWT токенов
- `COOKIE_SECRET` - секрет для cookies
- `STORE_CORS` - разрешенные CORS для storefront
- `ADMIN_CORS` - разрешенные CORS для админ панели

### medusa-storefront

Файл `.env.local` содержит переменные для конфигурации Next.js приложения:

- `MEDUSA_BACKEND_URL` - URL Medusa бэкенда
- `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY` - публичный ключ для API
- `NEXT_PUBLIC_BASE_URL` - базовый URL storefront
- `NEXT_PUBLIC_DEFAULT_REGION` - регион по умолчанию
- `NEXT_PUBLIC_STRIPE_KEY` - публичный ключ Stripe (если используется)

## Возможные проблемы и решения

### Проблемы с CORS

Если возникают ошибки CORS при взаимодействии между storefront и бэкендом, убедитесь, что:

1. В файле `.env` в `medusa-store` переменные `STORE_CORS` и `ADMIN_CORS` содержат соответствующие URL
2. `STORE_CORS` должен включать URL вашего storefront (по умолчанию `http://localhost:8000`)
3. `ADMIN_CORS` должен включать URL админ панели (по умолчанию `http://localhost:9000`)

### Проблемы с подключением к базе данных

Если Medusa сервер не может подключиться к базе данных:

1. Убедитесь, что Docker контейнеры запущены: `docker compose ps`
2. Проверьте логи контейнера: `docker compose logs medusa`
3. Убедитесь, что строка подключения `DATABASE_URL` в `.env` совпадает с настройками в `docker-compose.yml`

### Проблемы с публичным ключом

Если storefront не может получить данные из бэкенда:

1. Убедитесь, что публичный ключ правильно скопирован в `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`
2. Проверьте, что ключ активен и не был удален в админ панели
3. Убедитесь, что ключ связан с правильным каналом продаж (sales channel)

## Остановка сервисов

Для остановки всех Docker контейнеров выполните:

```sh
cd medusa-store
yarn docker:down
```

Для остановки storefront используйте `Ctrl+C` в терминале, где он запущен.

## Дополнительная информация

- Документация Medusa: [https://docs.medusajs.com/](https://docs.medusajs.com/)
- Документация Next.js: [https://nextjs.org/docs](https://nextjs.org/docs)
- GitHub репозиторий Medusa: [https://github.com/medusajs/medusa](https://github.com/medusajs/medusa)



