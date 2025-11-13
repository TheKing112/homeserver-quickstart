#!/bin/bash
# scripts/apply-critical-fixes.sh
# Automatisches Fix-Skript für kritische Sicherheitsprobleme

set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
+===========================================================+
|           HOMESERVER CRITICAL FIXES APPLICATOR           |
+===========================================================+
EOF
echo -e "${NC}"
echo ""

# Check if running from correct directory
if [ ! -f ".env.example" ]; then
    echo -e "${RED}Error: Must be run from homeserver-quickstart root directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Applying critical security fixes...${NC}"
echo ""

# 1. MCP API Key generieren (falls nicht vorhanden)
if [ -f ".env" ]; then
    if ! grep -q "^MCP_API_KEY=" .env; then
        echo -e "${YELLOW}[1/6]${NC} Generating MCP_API_KEY..."
        echo "MCP_API_KEY=$(openssl rand -hex 64)" >> .env
        echo -e "${GREEN}✓ MCP_API_KEY generated${NC}"
    else
        echo -e "${GREEN}✓ MCP_API_KEY already exists${NC}"
    fi
else
    echo -e "${YELLOW}[1/6]${NC} .env not found, skipping MCP_API_KEY"
fi

# 2. Traefik Dashboard Auth
if [ -f ".env" ]; then
    if ! grep -q "^TRAEFIK_DASHBOARD_AUTH=" .env; then
        echo -e "${YELLOW}[2/6]${NC} Generating Traefik Dashboard Auth..."
        if command -v htpasswd &> /dev/null; then
            TRAEFIK_PASSWORD=$(openssl rand -base64 24)
            TRAEFIK_DASHBOARD_AUTH=$(htpasswd -nb admin "$TRAEFIK_PASSWORD")
            echo "TRAEFIK_DASHBOARD_AUTH=${TRAEFIK_DASHBOARD_AUTH}" >> .env
            echo -e "${GREEN}✓ Traefik Dashboard Auth generated (User: admin)${NC}"
            echo -e "${CYAN}Save this password to your password manager: ${TRAEFIK_PASSWORD}${NC}"
        else
            echo -e "${YELLOW}Warning: htpasswd not found. Install: sudo apt install apache2-utils${NC}"
            echo "TRAEFIK_DASHBOARD_AUTH=CHANGE_ME" >> .env
        fi
    else
        echo -e "${GREEN}✓ TRAEFIK_DASHBOARD_AUTH already exists${NC}"
    fi
else
    echo -e "${YELLOW}[2/6]${NC} .env not found, skipping Traefik auth"
fi

# 3. Redis Config Template
echo -e "${YELLOW}[3/6]${NC} Creating Redis config template..."
mkdir -p configs/redis
if [ ! -f "configs/redis/redis.conf.template" ]; then
    cat > configs/redis/redis.conf.template << 'EOF'
# Redis Configuration
requirepass ${REDIS_PASSWORD}
appendonly yes
maxmemory 256mb
maxmemory-policy allkeys-lru
bind 0.0.0.0
protected-mode yes
EOF
    echo -e "${GREEN}✓ Redis config template created${NC}"
    echo -e "${YELLOW}  Note: You need to envsubst this template before starting Redis${NC}"
else
    echo -e "${GREEN}✓ Redis config template already exists${NC}"
fi

# 4. .env Symlink für docker-compose
echo -e "${YELLOW}[4/6]${NC} Creating .env symlink for docker-compose..."
if [ ! -L "docker-compose/.env" ] && [ -f ".env" ]; then
    ln -sf "$(pwd)/.env" "docker-compose/.env"
    echo -e "${GREEN}✓ .env symlink created${NC}"
elif [ -L "docker-compose/.env" ]; then
    echo -e "${GREEN}✓ .env symlink already exists${NC}"
else
    echo -e "${YELLOW}  .env not found yet, symlink will be created during install${NC}"
fi

# 5. BOLD Variable in install-homeserver.sh
echo -e "${YELLOW}[5/6]${NC} Checking install-homeserver.sh for BOLD variable..."
if [ -f "install-homeserver.sh" ]; then
    if ! grep -q "^BOLD=" install-homeserver.sh; then
        sed -i '/^CYAN=/a BOLD='"'"'\\033[1m'"'"'' install-homeserver.sh
        echo -e "${GREEN}✓ BOLD variable added${NC}"
    else
        echo -e "${GREEN}✓ BOLD variable already exists${NC}"
    fi
else
    echo -e "${YELLOW}  install-homeserver.sh not found${NC}"
fi

# 6. Check for rsync (für Dotfile-Copy)
echo -e "${YELLOW}[6/6]${NC} Checking for rsync..."
if command -v rsync &> /dev/null; then
    echo -e "${GREEN}✓ rsync installed${NC}"
else
    echo -e "${YELLOW}⚠ rsync not found. Installing...${NC}"
    if command -v apt &> /dev/null; then
        sudo apt install -y rsync
        echo -e "${GREEN}✓ rsync installed${NC}"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y rsync
        echo -e "${GREEN}✓ rsync installed${NC}"
    else
        echo -e "${RED}✗ Could not install rsync automatically${NC}"
    fi
fi

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}Critical fixes applied successfully!${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo -e "${YELLOW}Manual fixes still required:${NC}"
echo ""
echo "1. ${CYAN}autoinstall/user-data:${NC}"
echo "   - Add 'expire: true' to force password change on first login"
echo ""
echo "2. ${CYAN}scripts/setup-db-users.sh:${NC}"
echo "   - Replace '-p\"\${MYSQL_ROOT_PASSWORD}\"' with:"
echo "   - 'docker exec -e MYSQL_PWD=\"\${MYSQL_ROOT_PASSWORD}\" ...'"
echo ""
echo "3. ${CYAN}mail-api/app.py:${NC}"
echo "   - Add JSON validation to all POST/PUT endpoints"
echo "   - Use secrets.compare_digest for token comparison"
echo ""
echo "4. ${CYAN}docker-compose/docker-compose.monitoring.yml:${NC}"
echo "   - Add authentication middleware to Netdata"
echo ""
echo -e "${YELLOW}See VOLLSTÄNDIGE_BUG_LISTE.md for detailed instructions.${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Review and edit .env file"
echo "  2. Set SERVER_IP and TRAEFIK_ACME_EMAIL"
echo "  3. Run: ./install-homeserver.sh"
echo ""
