#!/bin/bash
set -euo pipefail

BACKUP_DIR="/mnt/backup/restic-repo"
PASSWORD_FILE="/opt/homeserver/.restic-password"
RESTORE_DIR="${1:-/tmp/restore}"

if ! command -v restic &> /dev/null; then
    echo "ERROR: restic not installed"
    echo "Install: sudo apt install restic"
    exit 1
fi

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "ERROR: Password file not found: $PASSWORD_FILE"
    echo ""
    echo "Creating password file from .env..."
    
    if [ -f "/opt/homeserver/.env" ]; then
        # Secure .env loading
        while IFS= read -r line || [ -n "$line" ]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
                export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
            fi
        done < "/opt/homeserver/.env"
        if [ -n "${RESTIC_PASSWORD:-}" ]; then
            echo "$RESTIC_PASSWORD" > "$PASSWORD_FILE"
            chmod 600 "$PASSWORD_FILE"
            echo "Password file created successfully"
        else
            echo "ERROR: RESTIC_PASSWORD not found in .env"
            exit 1
        fi
    else
        echo "ERROR: .env file not found at /opt/homeserver/.env"
        exit 1
    fi
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR Backup directory not found: $BACKUP_DIR"
    exit 1
fi

mkdir -p "$RESTORE_DIR" || { echo "ERROR creating $RESTORE_DIR"; exit 1; }

echo "PKG Restoring latest backup to $RESTORE_DIR"

restic -r "$BACKUP_DIR" \
    --password-file "$PASSWORD_FILE" \
    restore latest \
    --target "$RESTORE_DIR"

echo "OK Restore completed"
echo "DIR Files restored to: $RESTORE_DIR"