#!/usr/bin/env bash
# scripts/backup.sh
# Back up the Mattermost PostgreSQL database and data volume.
# Backups are saved to ./backups/ with a timestamp in the filename.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$BACKUP_DIR"

cd "$ROOT_DIR"

# ── 1. Database dump ─────────────────────────────────────────────────────────
DB_BACKUP="${BACKUP_DIR}/mattermost_db_${TIMESTAMP}.sql.gz"
echo "==> Dumping PostgreSQL database..."
if docker exec mm-postgres pg_dump -U mmuser mattermost | gzip > "$DB_BACKUP"; then
  echo "✅ Database backup saved to: ${DB_BACKUP}"
else
  echo "❌ Database backup FAILED."
  exit 1
fi

# ── 2. Data volume backup ────────────────────────────────────────────────────
DATA_BACKUP="${BACKUP_DIR}/mattermost_data_${TIMESTAMP}.tar.gz"
echo "==> Backing up mattermost-data volume..."
if docker run --rm \
     -v mattermost-chat_mattermost-data:/data:ro \
     -v "${BACKUP_DIR}":/backup \
     alpine \
     tar czf "/backup/mattermost_data_${TIMESTAMP}.tar.gz" -C /data .; then
  echo "✅ Data volume backup saved to: ${DATA_BACKUP}"
else
  echo "❌ Data volume backup FAILED."
  exit 1
fi

echo ""
echo "✅ All backups completed successfully."
echo "   Files saved in: ${BACKUP_DIR}"
