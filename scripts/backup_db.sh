#!/bin/bash
set -eo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups/sakukeluarga}"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/sakukeluarga_db_${DATE}.sql.gz"
RETENTION_DAYS=14

# Database credentials
DB_CONTAINER="${DB_CONTAINER:-sakukeluarga_db}"
DB_NAME="${DB_NAME:-finance_tracker}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_ROOT_PASSWORD:-RootSecurePass2026!}"

echo "[$(date)] Starting automated database backup for ${DB_NAME}..."
mkdir -p "${BACKUP_DIR}"

# Execute mysqldump inside the container and compress with gzip
docker exec "${DB_CONTAINER}" mysqldump \
  -u"${DB_USER}" \
  -p"${DB_PASS}" \
  --single-transaction \
  --quick \
  --routines \
  --triggers \
  "${DB_NAME}" | gzip > "${BACKUP_FILE}"

# Verify backup size
FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "[$(date)] Backup successfully generated: ${BACKUP_FILE} (Size: ${FILE_SIZE})"

# Automated retention policy: Delete backups older than RETENTION_DAYS
echo "[$(date)] Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -type f -name "sakukeluarga_db_*.sql.gz" -mtime +${RETENTION_DAYS} -exec rm -f {} \;

echo "[$(date)] Backup routine completed successfully."
