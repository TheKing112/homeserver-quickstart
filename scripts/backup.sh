#!/bin/bash
set -e

BACKUP_DIR="/mnt/backup/restic-repo"
PASSWORD_FILE="/opt/homeserver/.restic-password"

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "ERROR Password file not found!"
    exit 1
fi

echo "STORAGE Starting backup at $(date)"

# Backup data
restic -r "$BACKUP_DIR" \
    --password-file "$PASSWORD_FILE" \
    backup /opt/homeserver \
    --exclude node_modules \
    --exclude .git \
    --exclude '*.log'

# Cleanup old backups
restic -r "$BACKUP_DIR" \
    --password-file "$PASSWORD_FILE" \
    forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

echo "OK Backup completed at $(date)"