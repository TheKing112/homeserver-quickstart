#!/bin/bash
set -e

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

# Functions
generate_password() {
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${1:-32}
}

generate_token() {
    openssl rand -hex ${1:-32}
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

# Email notifications (CONFIGURE THIS!)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-gmail-app-password

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

echo -e "${GREEN}OK Secrets generated successfully!${NC}"
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${YELLOW}Checklist: IMPORTANT PASSWORDS (save to password manager!)${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${YELLOW}Databases:${NC}"
echo "  PostgreSQL: ${POSTGRES_PASSWORD}"
echo "  MySQL Root: ${MYSQL_ROOT_PASSWORD}"
echo "  Redis:      ${REDIS_PASSWORD}"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo "  Code Server: ${CODE_SERVER_PASSWORD}"
echo "  Grafana:     ${GRAFANA_ADMIN_PASSWORD}"
echo "  Mail API:    ${MAIL_API_TOKEN}"
echo ""
echo -e "${YELLOW}Backup:${NC}"
echo "  Restic: ${RESTIC_PASSWORD}"
echo ""
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${YELLOW}WARNING NEXT STEPS:${NC}"
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