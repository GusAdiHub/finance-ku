#!/bin/bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_backup_file.sql.gz>"
  exit 1
fi

BACKUP_FILE="$1"
DB_CONTAINER="${DB_CONTAINER:-sakukeluarga_db}"
DB_NAME="${DB_NAME:-finance_tracker}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_ROOT_PASSWORD:-RootSecurePass2026!}"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Error: Backup file '${BACKUP_FILE}' not found."
  exit 1
fi

echo "WARNING: Restoring will overwrite existing data in '${DB_NAME}'!"
read -p "Are you sure you want to proceed with restore? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Restore cancelled."
  exit 0
fi

echo "[$(date)] Restoring database from ${BACKUP_FILE}..."
gunzip < "${BACKUP_FILE}" | docker exec -i "${DB_CONTAINER}" mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}"

echo "[$(date)] Database restoration completed successfully!"
