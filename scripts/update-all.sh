#!/bin/bash
set -e

echo "Updating homeserver..."

cd /opt/homeserver

echo "Pulling latest images..."
docker compose -f docker-compose/docker-compose.yml pull
docker compose -f docker-compose/docker-compose.monitoring.yml pull

echo "Restarting services..."
docker compose -f docker-compose/docker-compose.yml up -d
docker compose -f docker-compose/docker-compose.monitoring.yml up -d

echo "OK Update complete!"