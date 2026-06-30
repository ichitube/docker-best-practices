# --- ЭТАП СБОРКИ (Stage 1: Builder) ---
FROM python:3.11-slim AS builder

WORKDIR /app

# Устанавливаем системные зависимости, необходимые только для компиляции (если есть)
RUN apt-get update && apt-get install -y --no-install-recommends gcc g++ \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Собираем зависимости в wheel-архивы для оптимизации веса финального образа
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# --- ЭТАП ЗАПУСКА (Stage 2: Production) ---
FROM python:3.11-slim

WORKDIR /app

# Безопасность: Создаем непривилегированного пользователя
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Кэширование: копируем только собранные пакеты из первого этапа
COPY --from=builder /app/wheels /app/wheels
COPY requirements.txt .

# Устанавливаем пакеты из готовых архивов и удаляем кэш
RUN pip install --no-cache-dir /app/wheels/* && rm -rf /app/wheels

# Копируем исходный код приложения (в самом конце, так как он меняется чаще всего)
COPY main.py .

# Передаем права на выполнение приложения безопасному пользователю
USER appuser

EXPOSE 8000

# Точка входа
CMD ["python", "main.py"]
