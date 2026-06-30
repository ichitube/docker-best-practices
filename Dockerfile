# --- ЭТАП СБОРКИ (Stage 1) ---
FROM python:3.11-slim AS builder

WORKDIR /app

# Устанавливаем зависимости для сборки C-библиотек (если пригодятся)
RUN apt-get update && apt-get install -y --no-install-recommends gcc g++ \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Собираем зависимости в изолированную папку (wheels)
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# --- ЭТАП ЗАПУСКА (Stage 2) ---
FROM python:3.11-slim

WORKDIR /app

# Безопасность: Создаем непривилегированного пользователя appuser
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Копируем только готовые пакеты из предыдущего слоя (Кэширование)
COPY --from=builder /app/wheels /app/wheels
COPY requirements.txt .
RUN pip install --no-cache-dir /app/wheels/* && rm -rf /app/wheels

# Копируем исходный код бэкенда ESS (ставим вниз, так как код меняется чаще всего)
COPY main.py .

# Переключаемся на безопасного пользователя
USER appuser

EXPOSE 8000

CMD ["python", "main.py"]
