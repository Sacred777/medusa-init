# Multi-stage Dockerfile для Medusa Next.js Frontend
# Оптимизирован для production окружения

# ============================================
# Stage 1: Dependencies
# Установка зависимостей
# ============================================
FROM node:20-alpine AS dependencies

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файлы управления зависимостями
COPY package.json yarn.lock .yarnrc.yml ./

# Копируем yarn releases если есть
COPY .yarn/releases ./.yarn/releases

# Устанавливаем зависимости
RUN yarn install --frozen-lockfile --production=false

# ============================================
# Stage 2: Builder
# Сборка Next.js приложения
# ============================================
FROM node:20-alpine AS builder

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем зависимости из предыдущего stage
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/.yarn ./.yarn

# Копируем исходный код
COPY . .

# Устанавливаем переменные окружения для сборки
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Собираем приложение
RUN yarn build

# ============================================
# Stage 3: Runner
# Production runtime
# ============================================
FROM node:20-alpine AS runner

# Устанавливаем рабочую директорию
WORKDIR /app

# Создаём пользователя для безопасности (не root)
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Устанавливаем переменные окружения для production
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=8000
ENV HOSTNAME="0.0.0.0"

# Копируем необходимые файлы из builder stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Устанавливаем права доступа
RUN chown -R nextjs:nodejs /app

# Переключаемся на пользователя nextjs
USER nextjs

# Экспонируем порт
EXPOSE 8000

# Health check для проверки работоспособности
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Запускаем Next.js в production режиме
CMD ["node", "server.js"]
