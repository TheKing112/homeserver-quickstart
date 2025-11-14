#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="/opt/homeserver"
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/homeserver-install.log"

# Redirect output to log with fallback
if [ -w "$LOG_DIR" ]; then
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
else
    LOG_FILE="./homeserver-install.log"
    echo "WARNING: Cannot write to /var/log, logging to $LOG_FILE"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
fi

clear
cat << "EOF"
+===========================================================+
|                                                           |
|     HOMESERVER QUICKSTART INSTALLATION                    |
|                                                           |
+===========================================================+
EOF

echo ""
echo -e "${CYAN}Initialisiere Installation...${NC}"
echo ""

# Functions
print_step() {
    echo ""
    echo -e "${BLUE}${BOLD}===========================================${NC}"
    echo -e "${CYAN}${BOLD}RUN $1${NC}"
    echo -e "${BLUE}${BOLD}===========================================${NC}"
}

print_success() {
    echo -e "${GREEN}OK${NC} $1"
}

print_error() {
    echo -e "${RED}FAILED${NC} $1"
    exit 1
}

# Root check
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (sudo)"
fi

# Check dependencies
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v docker &> /dev/null; then
    MISSING_DEPS+=("docker")
fi

if ! docker compose version &> /dev/null 2>&1; then
    MISSING_DEPS+=("docker-compose-plugin")
fi

if ! command -v envsubst &> /dev/null; then
    MISSING_DEPS+=("envsubst (gettext-base)")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    print_error "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install with:"
    echo "  sudo apt install docker.io docker-compose-plugin gettext-base"
    exit 1
fi

print_success "All dependencies available"
echo ""

# Check .env
if [ ! -f ".env" ]; then
    print_error ".env file not found! Run 00-generate-secrets.sh first."
fi

# Secure .env loading function
load_env_safe() {
    local env_file="${1:-.env}"
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    # Parse only valid KEY=VALUE lines, ignore comments and invalid syntax
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Match valid variable assignment (KEY=VALUE)
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        fi
    done < "$env_file"
}

# Load environment
load_env_safe .env

print_step "1/10 - System Configuration"
apt-get update -qq
sysctl -w net.ipv4.ip_forward=1 > /dev/null
print_success "System configured"

print_step "2/10 - Creating Directories"
mkdir -p "$INSTALL_DIR"/{configs,scripts,data,websites,mcp-servers}
print_success "Directories created"

print_step "3/10 - Copying Files"
cp -r . "$INSTALL_DIR"/
if id "admin" &>/dev/null; then
    chown -R admin:admin "$INSTALL_DIR"
fi
print_success "Files copied"

print_step "4/10 - Docker Networks"
docker network create homeserver_frontend 2>/dev/null || true
docker network create homeserver_backend 2>/dev/null || true
print_success "Networks created"

print_step "4.5/10 - Generating Redis Config"
if [ -f "configs/redis/redis.conf.template" ] && [ ! -f "configs/redis/redis.conf" ]; then
    envsubst < configs/redis/redis.conf.template > configs/redis/redis.conf
    chmod 644 configs/redis/redis.conf
    print_success "Redis config generated"
else
    print_success "Redis config already exists or template missing"
fi

print_step "5/10 - Starting Core Services"
cd "$INSTALL_DIR" || print_error "Cannot change to $INSTALL_DIR"
docker compose -f docker-compose/docker-compose.yml up -d
sleep 10
print_success "Core services started"

print_step "6/10 - Starting Monitoring"
docker compose -f docker-compose/docker-compose.monitoring.yml up -d
sleep 5
print_success "Monitoring started"

print_step "7/10 - Starting MCP Servers"
docker compose -f docker-compose/docker-compose.mcp.yml up -d 2>/dev/null || echo "MCP servers skipped (optional)"
print_success "MCP servers started"

print_step "8/10 - Configuring WireGuard"
if [ ! -f "/etc/wireguard/server_private.key" ]; then
    if command -v wg &> /dev/null; then
        wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
        chmod 600 /etc/wireguard/server_private.key
        SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
        echo "$SERVER_PUBLIC_KEY" > "$INSTALL_DIR"/.wireguard-server-pubkey
        print_success "WireGuard configured"
    else
        echo "WireGuard not installed, skipping..."
        print_success "WireGuard skipped"
    fi
else
    SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
    echo "$SERVER_PUBLIC_KEY" > "$INSTALL_DIR"/.wireguard-server-pubkey
    print_success "WireGuard already configured"
fi

print_step "8.5/10 - Creating Backup Password File"
if [ -n "${RESTIC_PASSWORD:-}" ]; then
    echo "$RESTIC_PASSWORD" > "$INSTALL_DIR"/.restic-password
    chmod 600 "$INSTALL_DIR"/.restic-password
    print_success "Backup password file created"
else
    echo "RESTIC_PASSWORD not set, skipping..."
    print_success "Backup password skipped"
fi

print_step "9/10 - Final Setup"
touch "$INSTALL_DIR"/.install-complete
print_success "Installation complete"

clear
cat << "EOF"

+===========================================================+
|              OK INSTALLATION COMPLETE! OK                 |
+===========================================================+

EOF

echo -e "${GREEN}${BOLD}Your homeserver is ready!${NC}"
echo ""
echo -e "${CYAN}Access your services at:${NC}"
echo "  STAT Dashboard:  http://home.homeserver.local"
echo "  PKG Portainer:  http://portainer.homeserver.local"
echo "  GRAPH Grafana:    http://grafana.homeserver.local"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Add services to your hosts file"
echo "  2. Access Portainer to create admin account"
echo "  3. Configure Vaultwarden and save passwords"
echo "  4. Setup WireGuard clients for bonding"
echo ""
echo -e "${CYAN}WireGuard Server Public Key:${NC}"
echo "${GREEN}$SERVER_PUBLIC_KEY${NC}"
echo ""
echo -e "${GREEN}Documentation: $INSTALL_DIR/README.md${NC}"
echo ""
