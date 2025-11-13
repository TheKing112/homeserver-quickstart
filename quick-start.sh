#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   HOMESERVER QUICK-START & DIAGNOSE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Funktion für Checks
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 ist installiert"
        return 0
    else
        echo -e "${RED}✗${NC} $1 ist NICHT installiert"
        return 1
    fi
}

# 1. Voraussetzungen prüfen
echo -e "${YELLOW}[1/7] Voraussetzungen prüfen...${NC}"
echo "-------------------------------------------"

check_command docker || echo "  → Installation: curl -fsSL https://get.docker.com | sh"

# Check for docker compose (plugin or standalone)
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC} docker compose ist installiert (Plugin)"
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} docker-compose ist installiert (veraltet, nutze Plugin)"
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}✗${NC} docker compose ist NICHT installiert"
    echo "  → Installation: siehe INSTALLATION.md"
    DOCKER_COMPOSE="docker compose"
fi

if command -v docker &> /dev/null; then
    echo -e "  Docker Version: $(docker --version)"
    if [ "$DOCKER_COMPOSE" = "docker compose" ]; then
        echo -e "  Docker Compose Version: $(docker compose version)"
    else
        echo -e "  Docker Compose Version: $(docker-compose --version)"
    fi
fi

echo ""

# 2. Datei-Prüfung
echo -e "${YELLOW}[2/7] Konfigurationsdateien prüfen...${NC}"
echo "-------------------------------------------"

if [ ! -f ".env" ]; then
    echo -e "${RED}✗${NC} .env Datei fehlt!"
    echo "  → Erstelle von .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓${NC} .env erstellt (bitte anpassen!)"
else
    echo -e "${GREEN}✓${NC} .env vorhanden"
fi

REQUIRED_FILES=(
    "docker-compose/docker-compose.yml"
    "docker-compose/docker-compose.monitoring.yml"
    "configs/traefik/traefik.yml"
    "configs/prometheus/prometheus.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file FEHLT!"
    fi
done

echo ""

# 3. YAML-Validierung
echo -e "${YELLOW}[3/7] YAML-Syntax prüfen...${NC}"
echo "-------------------------------------------"

if command -v python3 &> /dev/null; then
    if python3 -c "import yaml" 2>/dev/null; then
        python3 << 'PYEOF'
import yaml
import sys

files = [
    'docker-compose/docker-compose.yml',
    'docker-compose/docker-compose.monitoring.yml',
    'docker-compose/docker-compose.mcp.yml'
]

errors = 0
for f in files:
    try:
        with open(f) as file:
            yaml.safe_load(file)
        print(f"\033[32m✓\033[0m {f}")
    except Exception as e:
        print(f"\033[31m✗\033[0m {f}: {e}")
        errors += 1

sys.exit(errors)
PYEOF
    else
        echo "  PyYAML nicht installiert, überspringe Validierung"
        echo "  → Installation: pip install pyyaml"
    fi
else
    echo "  Python3 nicht gefunden, überspringe Validierung"
fi

echo ""

# 4. Docker-Netzwerke
echo -e "${YELLOW}[4/7] Docker-Netzwerke prüfen...${NC}"
echo "-------------------------------------------"

if command -v docker &> /dev/null; then
    for network in homeserver_frontend homeserver_backend; do
        if docker network inspect $network &>/dev/null; then
            echo -e "${GREEN}✓${NC} Netzwerk '$network' existiert"
        else
            echo -e "${YELLOW}⚠${NC} Netzwerk '$network' fehlt, erstelle..."
            docker network create $network
            echo -e "${GREEN}✓${NC} Netzwerk '$network' erstellt"
        fi
    done
else
    echo "  Docker nicht verfügbar, überspringe Netzwerk-Check"
fi

echo ""

# 5. Container-Status
echo -e "${YELLOW}[5/7] Container-Status...${NC}"
echo "-------------------------------------------"

if command -v docker &> /dev/null; then
    CONTAINER_COUNT=$(docker ps -q | wc -l)
    echo "  Laufende Container: $CONTAINER_COUNT"
    
    if [ $CONTAINER_COUNT -gt 0 ]; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
    else
        echo "  Keine Container laufen"
    fi
else
    echo "  Docker nicht verfügbar"
fi

echo ""

# 6. Ports prüfen
echo -e "${YELLOW}[6/7] Port-Verfügbarkeit prüfen...${NC}"
echo "-------------------------------------------"

PORTS=(80 443 8080)

for port in "${PORTS[@]}"; do
    if command -v nc &> /dev/null; then
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} Port $port ist bereits belegt"
        else
            echo -e "${GREEN}✓${NC} Port $port ist frei"
        fi
    else
        if lsof -i :$port &>/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} Port $port ist bereits belegt"
        else
            echo -e "${GREEN}✓${NC} Port $port ist frei"
        fi
    fi
done

echo ""

# 7. Zusammenfassung & Nächste Schritte
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   ZUSAMMENFASSUNG${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}Nächste Schritte:${NC}"
echo ""
echo "1. .env-Datei anpassen:"
echo "   ${BLUE}nano .env${NC}"
echo ""
echo "2. Passwörter ändern (WICHTIG!):"
echo "   - POSTGRES_PASSWORD"
echo "   - MYSQL_ROOT_PASSWORD"
echo "   - REDIS_PASSWORD"
echo "   - GRAFANA_ADMIN_PASSWORD"
echo ""
echo "3. Services starten:"
echo "   ${BLUE}cd docker-compose${NC}"
echo "   ${BLUE}docker compose -f docker-compose.yml up -d${NC}"
echo ""
echo "4. Monitoring starten (optional):"
echo "   ${BLUE}docker compose -f docker-compose.monitoring.yml up -d${NC}"
echo ""
echo "5. Status prüfen:"
echo "   ${BLUE}docker ps${NC}"
echo "   ${BLUE}docker compose logs -f${NC}"
echo ""
echo "6. /etc/hosts konfigurieren:"
echo "   ${BLUE}sudo nano /etc/hosts${NC}"
echo "   ${YELLOW}127.0.0.1  home.homeserver.local portainer.homeserver.local${NC}"
echo ""
echo -e "${GREEN}Dokumentation:${NC} INSTALLATION.md"
echo ""

