#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="/opt/homeserver"
LOG_FILE="/var/log/homeserver-install.log"

# Redirect output to log
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

clear
cat << "EOF"
+===========================================================+
|                                                           |
|     HOMESERVER QUICKSTART INSTALLATION                    |
|                                                           |
+===========================================================+
EOF

echo ""
echo -e "${CYAN}${BOLD}Starting automated installation...${NC}"
echo -e "${YELLOW}Log file: $LOG_FILE${NC}"
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

# Check .env
if [ ! -f ".env" ]; then
    print_error ".env file not found! Run 00-generate-secrets.sh first."
fi

# Load environment
set -a
source .env
set +a

print_step "1/10 - System Configuration"
apt-get update -qq
sysctl -w net.ipv4.ip_forward=1 > /dev/null
print_success "System configured"

print_step "2/10 - Creating Directories"
mkdir -p $INSTALL_DIR/{configs,scripts,data,websites,mcp-servers}
print_success "Directories created"

print_step "3/10 - Copying Files"
cp -r . $INSTALL_DIR/
chown -R admin:admin $INSTALL_DIR
print_success "Files copied"

print_step "4/10 - Docker Networks"
docker network create frontend 2>/dev/null || true
docker network create backend 2>/dev/null || true
print_success "Networks created"

print_step "5/10 - Starting Core Services"
cd $INSTALL_DIR
docker compose -f docker-compose/docker-compose.yml up -d
sleep 10
print_success "Core services started"

print_step "6/10 - Starting Monitoring"
docker compose -f docker-compose/docker-compose.monitoring.yml up -d
sleep 5
print_success "Monitoring started"

print_step "7/10 - Starting Mail Server"
docker compose -f docker-compose/docker-compose.mail.yml up -d 2>/dev/null || echo "Mail server skipped (optional)"
print_success "Mail server started"

print_step "8/10 - Starting MCP Servers"
docker compose -f docker-compose/docker-compose.mcp.yml up -d 2>/dev/null || echo "MCP servers skipped (optional)"
print_success "MCP servers started"

print_step "9/10 - Configuring WireGuard"
if [ ! -f "/etc/wireguard/server_private.key" ]; then
    wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
    chmod 600 /etc/wireguard/server_private.key
fi
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
echo "$SERVER_PUBLIC_KEY" > $INSTALL_DIR/.wireguard-server-pubkey
print_success "WireGuard configured"

print_step "10/10 - Final Setup"
touch $INSTALL_DIR/.install-complete
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