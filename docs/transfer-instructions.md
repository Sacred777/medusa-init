# Инструкция по переносу данных Medusa

## Общие сведения

Данный документ описывает процесс переноса данных из локальной базы PostgreSQL в базу на сервере в домашней сети. 
Medusa запускается из каталога `@medusa-store/**` командой `yarn docker:up`.

## Подготовка

### Требования
- Удаленный сервер с IP-адресом `192.168.31.85`
- SSH-доступ к серверу
- Установленный Docker на сервере
- Работающая система (Red OS + Zsh)

### Каталог на сервере
- `/home/sacred/medusa-init/medusa-store`

## Шаги по переносу данных

### 1. Создание дампа локальной базы данных

1. Перейдите в каталог с Medusa:
   ```bash
   cd /home/oleg/investigation/medusa-init/medusa-store
   ```

2. Убедитесь, что локальный контейнер с PostgreSQL запущен:
   ```bash
   docker compose ps
   ```

3. Создайте дамп базы данных:
   ```bash
   docker compose exec postgres pg_dump -U postgres -d medusa-store > medusa_backup.sql
   ```

### 2. Передача дампа на сервер

1. Скопируйте файл дампа на сервер:
   ```bash
   scp medusa_backup.sql sacred@192.168.31.85:/home/sacred/medusa-init/medusa-store/
   ```

### 3. Восстановление данных на сервере

1. Подключитесь к серверу по SSH:
   ```bash
   ssh sacred@192.168.31.85
   ```

2. Перейдите в каталог с Medusa на сервере:
   ```bash
   cd /home/sacred/medusa-init/medusa-store
   ```

3. Убедитесь, что контейнер с PostgreSQL запущен:
   ```bash
   docker compose ps
   ```

4. Если контейнеры не запущены, запустите их:
   ```bash
   docker compose up -d
   ```

5. Дождитесь полного запуска PostgreSQL и выполните удаление существующей базы данных:
   ```bash
   docker compose exec postgres dropdb -U postgres medusa-store
   ```

6. Создайте новую базу данных:
   ```bash
   docker compose exec postgres createdb -U postgres medusa-store
   ```

7. Остановите контейнеры:
   ```bash
   docker compose down
   ```

8. Запустите контейнеры:
   ```bash
   docker compose up -d
   ```

9. Дождитесь запуска PostgreSQL и выполните восстановление:
   ```bash
   docker compose exec -T postgres psql -U postgres -d medusa-store < medusa_backup.sql
   ```

### 4. Обновление конфигурации (при необходимости)

1. Обновите `DATABASE_URL` в файле `.env` на сервере, если адреса базы данных различаются.

2. Перезапустите приложение:
   ```bash
   docker compose down && docker compose up -d
   ```

## Важные замечания

- **Существующие записи в контейнере на сервере будут полностью перезаписаны** содержимым из дампа.
- Учетная запись администратора из локального контейнера будет перенесена вместе с дампом.
- Убедитесь, что вы создали резервную копию данных на сервере перед восстановлением, если они важны.
- После восстановления дампа все данные из локальной базы будут доступны на сервере.
- Учетная запись администратора из локального контейнера будет работать на сервере без необходимости создания новой.