#!/usr/bin/env bash
set -euo pipefail

START_TS=$(date +%s) # Start timestamp
FAILED_STEP="unknown" # Initialize failed step variable

### ENV FILE #########################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a # Automatically export all variables
source "${SCRIPT_DIR}/.env"
set +a # Stop Auto-exports

### CONFIG ##########################################################
# Paths
DB_DUMP="${TMP_DIR}/immich-postgres.sql"
DB_DUMP_ZST="${DB_DUMP}.zst" # Compressed database dump file

### LOGGING #########################################################

exec > >(tee -a "${LOG_FILE}") 2>&1

### FAILURE HANDLER ###################################################

on_error() {
  EXIT_CODE=$?
  END_TS=$(date +%s)
  DURATION=$((END_TS - START_TS))

  "${NOTIFY_SCRIPT}" FAILED \
      "Step: ${FAILED_STEP}
Exit code: ${EXIT_CODE}
Duration: ${DURATION}s"

  exit "$EXIT_CODE"
}

trap on_error ERR

### START BACKUP ####################################################

echo "=== $(date) Starting Immich backup ==="

### DUMP POSTGRES ####

echo "[+] Dumping Immich PostgreSQL database"

FAILED_STEP="Dumping Immich PostgreSQL DB"

docker exec "${IMMICH_DB_CONTAINER}" \
  pg_dump -U "${IMMICH_DB_USER}" "${IMMICH_DB_NAME}" \
  > "$DB_DUMP"

echo "[+] Compressing database dump"

FAILED_STEP="Compressing DB Dump"

zstd -5 -f "$DB_DUMP" -o "$DB_DUMP_ZST"
rm -f "$DB_DUMP"

### RESTIC BACKUP ###

echo "[+] Running restic backup"

FAILED_STEP="Running Restic Backup"

restic -r "${RESTIC_REMOTE}" backup --exclude-file="${EXCLUDE_FILE}" \
  "$DATA_DIR" \
  "$DB_DUMP_ZST" \
  --one-file-system

### CLEANUP ###

echo "[+] Cleaning up temporary files"

FAILED_STEP="Cleaning up TMP Files"

rm -f "$DB_DUMP_ZST"

echo "[✓] Backup completed successfully at $(date)"

### NOTIFY ###

END_TS=$(date +%s)
DURATION=$((END_TS - START_TS))

"${NOTIFY_SCRIPT}" SUCCESS \
  "Backup completed successfully
Duration: ${DURATION}s
Respository: Scaleway (rclone)"
