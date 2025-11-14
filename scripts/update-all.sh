#!/bin/bash
set -euo pipefail

echo "Updating homeserver..."

HOMESERVER_DIR="${HOMESERVER_DIR:-/opt/homeserver}"

if [ ! -d "$HOMESERVER_DIR" ]; then
    echo "ERROR: Homeserver directory not found: $HOMESERVER_DIR"
    exit 1
fi

cd "$HOMESERVER_DIR" || exit 1

echo "Pulling latest images..."
docker compose -f docker-compose/docker-compose.yml pull
docker compose -f docker-compose/docker-compose.monitoring.yml pull

echo "Restarting services..."
docker compose -f docker-compose/docker-compose.yml up -d
docker compose -f docker-compose/docker-compose.monitoring.yml up -d

echo "OK Update complete!"