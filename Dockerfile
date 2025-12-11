# ============================
# Stage 1 – Builder Stage
# ============================
FROM python:3.12-slim AS builder

# Set working directory
WORKDIR /app

# Install OS-level dependencies (required for building Python packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage caching
COPY requirements.txt .

# Install dependencies into a clean folder
RUN pip install --upgrade pip \
    && pip install --prefix=/install -r requirements.txt

# Copy application code
COPY . .

# ============================
# Stage 2 – Final Runtime Image
# ============================
FROM python:3.12-slim

WORKDIR /app

# Copy only installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy application code
COPY . .

# Set Python to run in production mode
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=8000

# Expose service port
EXPOSE 8000

# Healthcheck for production
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start the application
ENTRYPOINT ["python", "app.py"]
