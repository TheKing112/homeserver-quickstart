#!/bin/bash

echo "ðŸ¥ HOMESERVER HEALTH CHECK"
echo ""
echo "STAT Service Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
echo ""
echo "STORAGE Disk Usage:"
df -h / | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5")"}'
echo ""
echo "ðŸ§  Memory:"
free -h | awk 'NR==2{print "  Used: "$3" / "$2" ("$3/$2*100"%)"}'
echo ""