#!/bin/sh
set -e

echo "[SakuKeluarga Backend] Starting container initialization..."

# Run database migrations
echo "[SakuKeluarga Backend] Running database migrations (Alembic)..."
alembic upgrade head

# Seed default financial categories and dev account
echo "[SakuKeluarga Backend] Seeding default categories and dev account..."
python -m app.seeds.default_categories || true
python -m app.seeds.dev_user || true

echo "[SakuKeluarga Backend] Initialization complete. Starting FastAPI server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
