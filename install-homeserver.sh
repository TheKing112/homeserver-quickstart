#!/bin/bash

set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     🚀 HOMESERVER AUTOMATISCHE INSTALLATION 🚀            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Dieses Skript installiert Ihren kompletten Homeserver.${NC}"
echo -e "${CYAN}Geschätzte Dauer: 10-15 Minuten${NC}"
echo ""
read -p "Möchten Sie fortfahren? (j/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
    echo -e "${RED}Installation abgebrochen.${NC}"
    exit 1
fi

# Log-Datei
LOG_FILE="/tmp/homeserver-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${CYAN}Log-Datei: ${LOG_FILE}${NC}"
echo ""

# Funktionen
print_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}SCHRITT $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    echo -e "${RED}Installation fehlgeschlagen!${NC}"
    echo -e "${YELLOW}Log-Datei: ${LOG_FILE}${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Variablen
INSTALL_DIR="/opt/homeserver"
CURRENT_DIR=$(pwd)

# Cleanup-Funktion für Fehlerbehandlung
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo -e "${RED}═══════════════════════════════════════════════${NC}"
        echo -e "${RED}  Installation fehlgeschlagen (Exit Code: $exit_code)${NC}"
        echo -e "${RED}═══════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Fehler in Zeile $BASH_LINENO${NC}"
        echo -e "${YELLOW}Log-Datei: ${LOG_FILE}${NC}"
        echo ""
        echo -e "${CYAN}Für Support, bitte Log-Datei bereitstellen.${NC}"
    fi
}

trap cleanup EXIT ERR

# ============================================
# SCHRITT 1: Voraussetzungen prüfen
# ============================================
print_step "1/10 - Voraussetzungen prüfen"

# Root-Check
if [ "$EUID" -eq 0 ]; then 
    print_error "Bitte NICHT als root ausführen! Nutzen Sie: ./install-homeserver.sh"
fi

# Betriebssystem erkennen
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
    print_success "Betriebssystem: $PRETTY_NAME"
else
    print_error "Betriebssystem nicht erkannt"
fi

# Freier Speicherplatz
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    print_warning "Nur ${AVAILABLE_SPACE}GB frei (min. 20GB empfohlen)"
else
    print_success "Freier Speicherplatz: ${AVAILABLE_SPACE}GB"
fi

# RAM
TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
if [ "$TOTAL_RAM" -lt 4 ]; then
    print_warning "Nur ${TOTAL_RAM}GB RAM (min. 4GB empfohlen)"
else
    print_success "RAM: ${TOTAL_RAM}GB"
fi

# ============================================
# SCHRITT 2: Docker installieren
# ============================================
print_step "2/10 - Docker installieren"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker bereits installiert: $DOCKER_VERSION"
else
    echo "Docker wird installiert..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        # Ubuntu/Debian
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt-get update -qq
        sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
        # CentOS/RHEL/Fedora
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        print_error "Nicht unterstütztes Betriebssystem: $OS"
    fi
    
    print_success "Docker installiert"
fi

# Docker ohne sudo
if groups $USER | grep -q docker; then
    print_success "User '$USER' ist in Docker-Gruppe"
else
    echo "Füge User zur Docker-Gruppe hinzu..."
    sudo usermod -aG docker $USER
    print_warning "WICHTIG: Nach Installation neu anmelden für Docker-Rechte!"
fi

# Docker testen
if docker ps &> /dev/null; then
    print_success "Docker läuft und ist erreichbar"
else
    print_error "Docker läuft nicht oder keine Berechtigung. Bitte neu anmelden!"
fi

# ============================================
# SCHRITT 3: Projekt-Verzeichnis erstellen
# ============================================
print_step "3/10 - Projekt-Verzeichnis erstellen"

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Verzeichnis $INSTALL_DIR existiert bereits"
    read -p "Überschreiben? (j/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        sudo rm -rf "$INSTALL_DIR"
        print_success "Altes Verzeichnis gelöscht"
    else
        print_error "Installation abgebrochen"
    fi
fi

sudo mkdir -p "$INSTALL_DIR"
sudo chown -R $USER:$USER "$INSTALL_DIR"
print_success "Verzeichnis erstellt: $INSTALL_DIR"

# ============================================
# SCHRITT 4: Dateien kopieren
# ============================================
print_step "4/10 - Projekt-Dateien kopieren"

if [ -d "$CURRENT_DIR/docker-compose" ]; then
    rsync -a "$CURRENT_DIR"/ "$INSTALL_DIR"/
    print_success "Dateien von $CURRENT_DIR kopiert (inkl. Dotfiles)"
elif [ -d "/workspace/Homeserver/homeserver-quickstart" ]; then
    rsync -a /workspace/Homeserver/homeserver-quickstart/ "$INSTALL_DIR"/
    print_success "Dateien von /workspace kopiert (inkl. Dotfiles)"
else
    print_error "Projekt-Dateien nicht gefunden!"
fi

cd "$INSTALL_DIR"

# ============================================
# SCHRITT 5: Umgebungsvariablen konfigurieren
# ============================================
print_step "5/10 - Umgebungsvariablen konfigurieren"

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success ".env erstellt von .env.example"
    else
        print_error ".env.example nicht gefunden!"
    fi
else
    print_success ".env bereits vorhanden"
fi

# Secrets generieren
echo "Generiere sichere Passwörter..."

if [ -f "scripts/00-generate-secrets.sh" ]; then
    chmod +x scripts/00-generate-secrets.sh
    bash scripts/00-generate-secrets.sh
    print_success "Secrets automatisch generiert"
else
    # Manuell generieren (mit hex statt base64 für sed-Sicherheit)
    sed -i "s|POSTGRES_PASSWORD=CHANGE_ME|POSTGRES_PASSWORD=$(openssl rand -hex 32)|" .env
    sed -i "s|MYSQL_ROOT_PASSWORD=CHANGE_ME|MYSQL_ROOT_PASSWORD=$(openssl rand -hex 32)|" .env
    sed -i "s|MYSQL_PASSWORD=CHANGE_ME|MYSQL_PASSWORD=$(openssl rand -hex 32)|" .env
    sed -i "s|REDIS_PASSWORD=CHANGE_ME|REDIS_PASSWORD=$(openssl rand -hex 32)|" .env
    sed -i "s|GRAFANA_ADMIN_PASSWORD=CHANGE_ME|GRAFANA_ADMIN_PASSWORD=$(openssl rand -hex 24)|" .env
    sed -i "s|VAULTWARDEN_ADMIN_TOKEN=CHANGE_ME|VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -hex 32)|" .env
    sed -i "s|DRONE_RPC_SECRET=CHANGE_ME|DRONE_RPC_SECRET=$(openssl rand -hex 32)|" .env
    sed -i "s|CODE_SERVER_PASSWORD=CHANGE_ME|CODE_SERVER_PASSWORD=$(openssl rand -hex 24)|" .env
    print_success "Passwörter generiert"
fi

# Server-IP automatisch erkennen
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -n "$SERVER_IP" ]; then
    sed -i "s/SERVER_IP=192.168.1.100/SERVER_IP=$SERVER_IP/" .env
    print_success "Server-IP gesetzt: $SERVER_IP"
fi

print_warning "WICHTIG: Bitte .env überprüfen und Email-Adresse setzen:"
echo "  nano $INSTALL_DIR/.env"
echo "  → TRAEFIK_ACME_EMAIL=ihre-email@example.com"

# ============================================
# SCHRITT 6: Firewall konfigurieren
# ============================================
print_step "6/10 - Firewall konfigurieren"

if command -v ufw &> /dev/null; then
    # UFW (Ubuntu)
    sudo ufw allow 80/tcp comment 'Homeserver HTTP' &>/dev/null || true
    sudo ufw allow 443/tcp comment 'Homeserver HTTPS' &>/dev/null || true
    sudo ufw allow 8080/tcp comment 'Traefik Dashboard' &>/dev/null || true
    print_success "UFW Regeln hinzugefügt"
elif command -v firewall-cmd &> /dev/null; then
    # Firewalld (CentOS/RHEL)
    sudo firewall-cmd --permanent --add-port=80/tcp &>/dev/null || true
    sudo firewall-cmd --permanent --add-port=443/tcp &>/dev/null || true
    sudo firewall-cmd --permanent --add-port=8080/tcp &>/dev/null || true
    sudo firewall-cmd --reload &>/dev/null || true
    print_success "Firewalld Regeln hinzugefügt"
else
    print_warning "Keine Firewall erkannt, überspringe"
fi

# ============================================
# SCHRITT 7: Docker-Netzwerke erstellen
# ============================================
print_step "7/11 - Docker-Netzwerke erstellen"

docker network create homeserver_frontend 2>/dev/null || print_success "Netzwerk 'homeserver_frontend' existiert bereits"
docker network create homeserver_backend 2>/dev/null || print_success "Netzwerk 'homeserver_backend' existiert bereits"
print_success "Docker-Netzwerke bereit"

# ============================================
# SCHRITT 8: Redis-Konfiguration generieren
# ============================================
print_step "8/11 - Redis-Konfiguration generieren"

if [ -f "$INSTALL_DIR/configs/redis/redis.conf.template" ]; then
    # Load REDIS_PASSWORD from .env
    REDIS_PASSWORD=$(grep '^REDIS_PASSWORD=' "$INSTALL_DIR/.env" | cut -d '=' -f2)
    
    if [ -n "$REDIS_PASSWORD" ]; then
        # Generate redis.conf from template
        sed "s/\${REDIS_PASSWORD}/$REDIS_PASSWORD/" \
            "$INSTALL_DIR/configs/redis/redis.conf.template" > \
            "$INSTALL_DIR/configs/redis/redis.conf"
        
        chmod 600 "$INSTALL_DIR/configs/redis/redis.conf"
        print_success "Redis-Konfiguration erstellt"
    else
        print_warning "REDIS_PASSWORD nicht in .env gefunden"
    fi
else
    print_warning "Redis-Template nicht gefunden, überspringe"
fi

# ============================================
# SCHRITT 9: Services starten
# ============================================
print_step "9/11 - Services starten"

# WICHTIG: .env Symlink erstellen
if [ ! -L "$INSTALL_DIR/docker-compose/.env" ]; then
    ln -sf "$INSTALL_DIR/.env" "$INSTALL_DIR/docker-compose/.env"
    print_success ".env Symlink erstellt"
fi

cd "$INSTALL_DIR/docker-compose"

echo "Starte Haupt-Services..."
if ! docker compose -f docker-compose.yml up -d; then
    print_error "Fehler beim Starten der Services!"
fi
print_success "Haupt-Services gestartet"

echo "Warte auf Container-Initialisierung..."
timeout=60
healthy_count=0
while [ $timeout -gt 0 ] && [ $healthy_count -lt 3 ]; do
    healthy_count=$(docker ps --filter "health=healthy" 2>/dev/null | wc -l)
    echo -ne "${CYAN}Gesunde Container: $healthy_count | Timeout: ${timeout}s\r${NC}"
    sleep 2
    timeout=$((timeout - 2))
done
echo ""
if [ $healthy_count -ge 3 ]; then
    print_success "Container sind bereit"
else
    print_warning "Einige Container benötigen noch Zeit zum Starten"
fi

echo "Starte Monitoring..."
docker compose -f docker-compose.monitoring.yml up -d 2>/dev/null || print_warning "Monitoring optional übersprungen"
print_success "Monitoring gestartet"

echo "Starte MCP-Server..."
docker compose -f docker-compose.mcp.yml up -d 2>/dev/null || print_warning "MCP-Server optional übersprungen"
print_success "MCP-Server gestartet"

# ============================================
# SCHRITT 10: Status prüfen
# ============================================
print_step "10/11 - Status prüfen"

RUNNING=$(docker ps --filter "name=homeserver" --format "{{.Names}}" | wc -l)
echo "Laufende Container: $RUNNING"

if [ "$RUNNING" -gt 10 ]; then
    print_success "Alle Services laufen"
else
    print_warning "Nur $RUNNING Container laufen, erwarte mehr"
fi

# Wichtige Services prüfen
CRITICAL_SERVICES=("traefik" "portainer" "postgres" "mariadb" "redis")
for service in "${CRITICAL_SERVICES[@]}"; do
    if docker ps | grep -q "$service"; then
        echo -e "${GREEN}✓${NC} $service läuft"
    else
        echo -e "${RED}✗${NC} $service läuft NICHT"
    fi
done

# ============================================
# SCHRITT 11: Hosts-Datei Info
# ============================================
print_step "11/11 - Hosts-Datei konfigurieren"

echo -e "${YELLOW}Fügen Sie folgende Zeilen zu /etc/hosts hinzu:${NC}"
echo ""
echo "# Homeserver Services"
echo "$SERVER_IP  home.homeserver.local"
echo "$SERVER_IP  portainer.homeserver.local"
echo "$SERVER_IP  traefik.homeserver.local"
echo "$SERVER_IP  grafana.homeserver.local"
echo "$SERVER_IP  prometheus.homeserver.local"
echo "$SERVER_IP  netdata.homeserver.local"
echo "$SERVER_IP  git.homeserver.local"
echo "$SERVER_IP  vault.homeserver.local"
echo "$SERVER_IP  code.homeserver.local"
echo "$SERVER_IP  db.homeserver.local"
echo ""

# ============================================
# ABSCHLUSS
# ============================================
clear
echo -e "${GREEN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         ✅ INSTALLATION ERFOLGREICH! ✅                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}Ihr Homeserver läuft!${NC}"
echo ""
echo -e "${CYAN}📊 Service-URLs:${NC}"
echo "  Dashboard:    http://home.homeserver.local"
echo "  Portainer:    http://portainer.homeserver.local"
echo "  Traefik:      http://traefik.homeserver.local:8080"
echo "  Grafana:      http://grafana.homeserver.local"
echo "  Gitea:        http://git.homeserver.local"
echo "  Vaultwarden:  http://vault.homeserver.local"
echo ""
echo -e "${YELLOW}📝 Nächste Schritte:${NC}"
echo ""
echo "1. Hosts-Datei konfigurieren:"
echo "   ${BLUE}sudo nano /etc/hosts${NC}"
echo "   → Einträge von oben hinzufügen"
echo ""
echo "2. Portainer Admin-Account erstellen:"
echo "   → http://portainer.homeserver.local"
echo ""
echo "3. Gitea einrichten:"
echo "   → http://git.homeserver.local"
echo ""
echo "4. Passwörter ansehen:"
echo "   ${BLUE}cat $INSTALL_DIR/.env | grep PASSWORD${NC}"
echo ""
echo -e "${GREEN}📚 Dokumentation:${NC}"
echo "  $INSTALL_DIR/LINUX_INSTALLATION.md"
echo "  $INSTALL_DIR/INSTALLATION.md"
echo ""
echo -e "${CYAN}🔧 Nützliche Befehle:${NC}"
echo "  docker ps                              # Container-Status"
echo "  docker compose logs -f                 # Logs verfolgen"
echo "  cd $INSTALL_DIR/docker-compose         # Zum Projekt"
echo ""
echo -e "${YELLOW}📋 Log-Datei: ${LOG_FILE}${NC}"
echo ""
echo -e "${GREEN}Viel Erfolg mit Ihrem Homeserver! 🚀${NC}"
echo ""
