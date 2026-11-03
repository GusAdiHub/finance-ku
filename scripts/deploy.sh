#!/bin/bash
set -eo pipefail

echo "=========================================================="
echo "      SakuKeluarga Production Deployment Script           "
echo "=========================================================="

# 1. Check if .env.production exists
if [ ! -f .env.production ]; then
  echo "Error: .env.production file is missing!"
  echo "Please copy .env.production.example to .env.production and configure production secrets."
  exit 1
fi

# 2. Pull latest git code if in a git repo
if [ -d .git ]; then
  echo "--> Pulling latest commits from git..."
  git pull origin main || echo "Git pull skipped or failed, proceeding with local files..."
fi

# 3. Create SSL directory and dummy self-signed certificate if none exists
mkdir -p deployment/ssl
if [ ! -f deployment/ssl/fullchain.pem ] || [ ! -f deployment/ssl/privkey.pem ]; then
  echo "--> SSL certificates not found. Generating temporary self-signed SSL certificates..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout deployment/ssl/privkey.pem \
    -out deployment/ssl/fullchain.pem \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=SakuKeluarga/CN=localhost"
fi

# 4. Backup database before deploying
if [ -f scripts/backup_db.sh ] && docker ps | grep -q sakukeluarga_db; then
  echo "--> Running safety database backup before new deployment..."
  bash scripts/backup_db.sh || echo "Pre-deploy backup failed, check logs."
fi

# 5. Build and deploy docker containers
echo "--> Building production containers..."
docker compose -f docker-compose.prod.yml --env-file .env.production build

echo "--> Launching updated services..."
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --remove-orphans

echo "--> Verifying running services..."
docker compose -f docker-compose.prod.yml ps

echo "=========================================================="
echo "   SakuKeluarga successfully deployed to Production!      "
echo "=========================================================="
