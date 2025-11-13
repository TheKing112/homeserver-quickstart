#!/bin/bash
set -euo pipefail

echo "========================================="
echo "  HOMESERVER HEALTH CHECK"
echo "========================================="
echo ""
echo "STAT Service Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
echo ""
echo "STORAGE Disk Usage:"
df -h / | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5")"}'
echo ""
echo "MEMORY Memory Usage:"
free -h | awk 'NR==2{used=$3; total=$2; printf "  Used: %s / %s\n", used, total}'
echo ""
