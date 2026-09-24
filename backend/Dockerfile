# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

# Prevent Python from writing .pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Install system dependencies (curl for container healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY backend/requirements.txt /app/backend/requirements.txt
COPY ml/requirements.txt /app/ml/requirements.txt

RUN pip install --no-cache-dir -r /app/backend/requirements.txt \
    && pip install --no-cache-dir -r /app/ml/requirements.txt

# Copy backend application and ML model artifacts
COPY backend /app/backend
COPY ml /app/ml

# Create non-privileged service user
RUN useradd -m -u 1000 tiyrasense && \
    mkdir -p /app/backend/app/static/uploads && \
    chown -R tiyrasense:tiyrasense /app

USER tiyrasense

EXPOSE 8000

# Health check probing the public status endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/api/v1/health || exit 1

# Start Uvicorn bound to 0.0.0.0 and dynamic Render PORT
CMD ["sh", "-c", "uvicorn backend.app.main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips='*'"]
