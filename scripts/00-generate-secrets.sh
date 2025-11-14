#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
+===========================================================+
|           Security: HOMESERVER SECRETS GENERATOR             |
+===========================================================+
EOF
echo -e "${NC}"
echo ""

# Check dependencies
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}ERROR: openssl not found${NC}"
    echo "Install: sudo apt install openssl"
    exit 1
fi

# Functions
generate_password() {
    openssl rand -hex "${1:-16}"
}

generate_token() {
    openssl rand -hex "${1:-32}"
}

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}WARNING .env file already exists!${NC}"
    read -p "Overwrite? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

echo -e "${CYAN}Generating secure secrets...${NC}"
echo ""

# Generate all secrets
POSTGRES_PASSWORD=$(generate_password 32)
MYSQL_ROOT_PASSWORD=$(generate_password 32)
MYSQL_PASSWORD=$(generate_password 32)
REDIS_PASSWORD=$(generate_password 32)
MAIL_SECRET_KEY=$(generate_token 32)
MAIL_MYSQL_ROOT_PASSWORD=$(generate_password 32)
MAIL_MYSQL_PASSWORD=$(generate_password 32)
MAIL_API_TOKEN=$(generate_token 64)
DRONE_RPC_SECRET=$(generate_token 32)
CODE_SERVER_PASSWORD=$(generate_password 24)
GRAFANA_ADMIN_PASSWORD=$(generate_password 24)
RESTIC_PASSWORD=$(generate_password 32)
VAULTWARDEN_ADMIN_TOKEN=$(generate_token 64)
MCP_API_KEY=$(generate_token 64)
MCP_POSTGRES_PASSWORD=$(generate_password 32)
MCP_MYSQL_PASSWORD=$(generate_password 32)

# Traefik Dashboard Auth (Basic Auth)
TRAEFIK_USER="admin"
TRAEFIK_PASSWORD=$(generate_password 24)
if command -v htpasswd &> /dev/null; then
    TRAEFIK_DASHBOARD_AUTH=$(htpasswd -nb admin "$TRAEFIK_PASSWORD")
else
    echo -e "${RED}ERROR: htpasswd not found. Install apache2-utils:${NC}"
    echo "  sudo apt install apache2-utils"
    echo "  sudo dnf install httpd-tools"
    exit 1
fi

# Admin UI Auth (for Portainer, Adminer, Redis Commander, Netdata, Grafana)
ADMIN_UI_USER="admin"
ADMIN_UI_PASSWORD=$(generate_password 24)
ADMIN_UI_AUTH=$(htpasswd -nb "$ADMIN_UI_USER" "$ADMIN_UI_PASSWORD")

# Registry Auth (for Docker Registry)
REGISTRY_USER="registry"
REGISTRY_PASSWORD=$(generate_password 24)
REGISTRY_UI_AUTH=$(htpasswd -nb "$REGISTRY_USER" "$REGISTRY_PASSWORD")

# Create Registry htpasswd file
mkdir -p configs/registry/auth
chmod 700 configs/registry/auth
echo "$REGISTRY_UI_AUTH" > configs/registry/auth/htpasswd
chmod 600 configs/registry/auth/htpasswd

# Create .env file
cat > .env << EOF
# ================================
# HOMESERVER CONFIGURATION
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ================================

# Project
COMPOSE_PROJECT_NAME=homeserver
TZ=Europe/Berlin

# Network
SERVER_IP=192.168.1.100

# ================================
# DATABASE PASSWORDS
# ================================
POSTGRES_USER=admin
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=homeserver

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=homeserver
MYSQL_USER=admin
MYSQL_PASSWORD=${MYSQL_PASSWORD}

REDIS_PASSWORD=${REDIS_PASSWORD}

# ================================
# MAIL SERVER
# ================================
MAIL_PRIMARY_DOMAIN=homeserver.local
MAIL_DOMAINS=homeserver.local
MAIL_SECRET_KEY=${MAIL_SECRET_KEY}
MAIL_MYSQL_ROOT_PASSWORD=${MAIL_MYSQL_ROOT_PASSWORD}
MAIL_MYSQL_PASSWORD=${MAIL_MYSQL_PASSWORD}
MAIL_API_TOKEN=${MAIL_API_TOKEN}

# Email notifications (OPTIONAL - Configure only if needed)
# Use app-specific passwords for Gmail, not your main password
# Leave empty if not using email notifications
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=

# ================================
# DEVELOPMENT TOOLS
# ================================
# Gitea OAuth (generated after Gitea setup)
GITEA_OAUTH_CLIENT_ID=
GITEA_OAUTH_CLIENT_SECRET=

DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
CODE_SERVER_PASSWORD=${CODE_SERVER_PASSWORD}

# ================================
# MONITORING
# ================================
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}

# ================================
# MCP SERVICES
# ================================
MCP_API_KEY=${MCP_API_KEY}
MCP_POSTGRES_USER=mcp_readonly
MCP_POSTGRES_PASSWORD=${MCP_POSTGRES_PASSWORD}
MCP_MYSQL_USER=mcp_readonly
MCP_MYSQL_PASSWORD=${MCP_MYSQL_PASSWORD}

# ================================
# TRAEFIK DASHBOARD
# ================================
TRAEFIK_ACME_EMAIL=your-email@example.com
TRAEFIK_DASHBOARD_AUTH=${TRAEFIK_DASHBOARD_AUTH}

# ================================
# ADMIN UI AUTH
# ================================
ADMIN_UI_AUTH=${ADMIN_UI_AUTH}

# ================================
# DOCKER REGISTRY
# ================================
REGISTRY_UI_AUTH=${REGISTRY_UI_AUTH}

# ================================
# BACKUP
# ================================
RESTIC_PASSWORD=${RESTIC_PASSWORD}
BACKUP_SCHEDULE=0 2 * * *

# ================================
# SECURITY
# ================================
VAULTWARDEN_ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN}
EOF


chmod 600 .env


echo -e "${GREEN}✓ Secrets generated successfully!${NC}"
echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${YELLOW}         IMPORTANT - SECRETS SAVED TO .env FILE${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo -e "${RED}⚠ WARNING: Do NOT share these credentials!${NC}"
echo ""
echo -e "${GREEN}Secrets have been securely saved to: .env${NC}"
echo ""
echo -e "${YELLOW}To view your secrets (use with caution):${NC}"
echo "  cat .env | grep PASSWORD"
echo "  cat .env | grep TOKEN"
echo ""
echo -e "${YELLOW}CRITICAL: Save these to your password manager NOW:${NC}"
echo "  - PostgreSQL password"
echo "  - MySQL root password"
echo "  - Redis password"
echo "  - Mail API token"
echo "  - Code Server password: ${CODE_SERVER_PASSWORD}"
echo "  - Grafana admin password: ${GRAFANA_ADMIN_PASSWORD}"
echo "  - Vaultwarden admin token"
echo "  - Restic backup password"
echo "  - MCP API Key"
echo "  - Traefik Dashboard (user: admin, password: ${TRAEFIK_PASSWORD})"
echo "  - Admin UI BasicAuth (user: admin, password: ${ADMIN_UI_PASSWORD})"
echo "  - Docker Registry (user: registry, password: ${REGISTRY_PASSWORD})"
echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo ""
echo "1. ${GREEN}Edit .env and configure:${NC}"
echo "   - SMTP_USER and SMTP_PASSWORD"
echo "   - MAIL_DOMAINS (your real domains)"
echo "   - SERVER_IP (if different)"
echo ""
echo "2. ${GREEN}Save all passwords to your password manager${NC}"
echo ""
echo "3. ${GREEN}Ready to install!${NC}"
echo "   - Create bootable USB with Ubuntu 24.04"
echo "   - Copy autoinstall folder to USB"
echo "   - Boot and install"
echo "   - Run: sudo /opt/homeserver-setup/scripts/01-quickstart.sh"
echo ""
