#!/bin/bash
set -euo pipefail

# Cleanup-Funktion
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "ERROR: Backup failed with exit code: $exit_code"
    fi
}

trap cleanup EXIT ERR

# Check dependencies
if ! command -v restic &> /dev/null; then
    echo "ERROR: restic not installed"
    echo "Install with: apt-get install restic"
    exit 1
fi

BACKUP_DIR="/mnt/backup/restic-repo"
PASSWORD_FILE="/opt/homeserver/.restic-password"

# Determine credential method
if [ -f "$PASSWORD_FILE" ]; then
    PASS_OP=(--password-file "$PASSWORD_FILE")
    echo "Using password file: $PASSWORD_FILE"
elif [ -n "${RESTIC_PASSWORD:-}" ]; then
    export RESTIC_PASSWORD
    PASS_OP=()
    echo "Using RESTIC_PASSWORD environment variable"
else
    echo "ERROR: RESTIC_PASSWORD not set and password file not found at $PASSWORD_FILE"
    exit 1
fi

echo "STORAGE Starting backup at $(date)"

# Initialize repository if needed
if ! restic -r "$BACKUP_DIR" "${PASS_OP[@]}" snapshots &>/dev/null; then
    echo "STORAGE Initializing restic repository..."
    if ! restic -r "$BACKUP_DIR" "${PASS_OP[@]}" init; then
        echo "ERROR: Failed to initialize repository"
        exit 1
    fi
    echo "OK Repository initialized"
fi

# Backup data
if ! restic -r "$BACKUP_DIR" \
    "${PASS_OP[@]}" \
    backup /opt/homeserver \
    --exclude node_modules \
    --exclude .git \
    --exclude '*.log'; then
    echo "ERROR: Backup command failed"
    exit 1
fi

# Cleanup old backups
if ! restic -r "$BACKUP_DIR" \
    "${PASS_OP[@]}" \
    forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune; then
    echo "WARNING: Cleanup command failed"
fi

echo "OK Backup completed at $(date)"