#!/bin/bash
set -e

BACKUP_DIR="/mnt/backup/restic-repo"
PASSWORD_FILE="/opt/homeserver/.restic-password"
RESTORE_DIR="${1:-/tmp/restore}"

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "ERROR Password file not found!"
    exit 1
fi

echo "PKG Restoring latest backup to $RESTORE_DIR"

restic -r "$BACKUP_DIR" \
    --password-file "$PASSWORD_FILE" \
    restore latest \
    --target "$RESTORE_DIR"

echo "OK Restore completed"
echo "DIR Files restored to: $RESTORE_DIR"