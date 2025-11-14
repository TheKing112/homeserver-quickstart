#!/bin/bash
set -euo pipefail

# ============================================
# Homeserver Database User Setup Script
# ============================================
# This script automates the creation of dedicated database users
# with minimal privileges for Mail API and MCP services

# Cleanup-Funktion
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Script failed with exit code: $exit_code${NC}"
    fi
}

trap cleanup EXIT ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  HOMESERVER DATABASE USER SETUP${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Secure .env loading function
load_env_safe() {
    local env_file="${1:-.env}"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}ERROR: .env file not found${NC}"
        echo "Please run this script from the homeserver-quickstart directory"
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

# Load environment variables
load_env_safe .env || exit 1

# Generate secure passwords if not set
generate_password() {
    openssl rand -hex 13
}

MAILU_API_PASSWORD=${MAILU_API_PASSWORD:-$(generate_password)}
MCP_MYSQL_PASSWORD=${MCP_MYSQL_PASSWORD:-$(generate_password)}
MCP_POSTGRES_PASSWORD=${MCP_POSTGRES_PASSWORD:-$(generate_password)}

echo -e "${YELLOW}Step 1: Setting up MySQL/MariaDB users...${NC}"

# Check if MariaDB container is running
if ! docker ps | grep -q mariadb; then
    echo -e "${RED}ERROR: MariaDB container is not running${NC}"
    echo "Please start the database first: docker-compose up -d mariadb"
    exit 1
fi

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
timeout=30
until docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mariadb mysqladmin -u root ping --silent 2>/dev/null || [ $timeout -eq 0 ]; do
    echo -n "."
    sleep 2
    timeout=$((timeout - 2))
done
echo ""

if [ $timeout -eq 0 ]; then
    echo -e "${RED}ERROR: MariaDB did not become ready in time${NC}"
    exit 1
fi

# Create Mail API user
echo "Creating mailu_api user..."
docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" -i mariadb mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'mailu_api'@'%' IDENTIFIED BY '${MAILU_API_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE ON mailu.* TO 'mailu_api'@'%';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Mail API user created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create Mail API user${NC}"
fi

# Create MCP MySQL read-only user
echo "Creating mcp_readonly MySQL user..."
docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" -i mariadb mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'mcp_readonly'@'%' IDENTIFIED BY '${MCP_MYSQL_PASSWORD}';
GRANT SELECT ON homeserver.* TO 'mcp_readonly'@'%';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ MCP MySQL read-only user created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create MCP MySQL user${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Setting up PostgreSQL users...${NC}"

# Check if PostgreSQL container is running
if ! docker ps | grep -q postgres; then
    echo -e "${RED}ERROR: PostgreSQL container is not running${NC}"
    echo "Please start the database first: docker-compose up -d postgres"
    exit 1
fi

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
timeout=30
until docker exec postgres pg_isready -U "${POSTGRES_USER:-admin}" 2>/dev/null || [ $timeout -eq 0 ]; do
    echo -n "."
    sleep 2
    timeout=$((timeout - 2))
done
echo ""

if [ $timeout -eq 0 ]; then
    echo -e "${RED}ERROR: PostgreSQL did not become ready in time${NC}"
    exit 1
fi

# Create MCP PostgreSQL read-only user
echo "Creating mcp_readonly PostgreSQL user..."
docker exec -i postgres psql -U "${POSTGRES_USER:-admin}" -d "${POSTGRES_DB:-homeserver}" <<EOF
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mcp_readonly') THEN
        CREATE USER mcp_readonly WITH PASSWORD '${MCP_POSTGRES_PASSWORD}';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE ${POSTGRES_DB:-homeserver} TO mcp_readonly;
GRANT USAGE ON SCHEMA public TO mcp_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mcp_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO mcp_readonly;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO mcp_readonly;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ MCP PostgreSQL read-only user created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create MCP PostgreSQL user${NC}"
fi

echo ""
echo -e "${YELLOW}Step 3: Updating .env file...${NC}"

# Backup .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ Backed up .env file${NC}"

# Update or add variables to .env
update_env_var() {
    local key=$1
    local value=$2
    if grep -q "^${key}=" .env; then
        sed -i "s|^${key}=.*|${key}=${value}|" .env
    else
        echo "${key}=${value}" >> .env
    fi
}

update_env_var "MAIL_MYSQL_USER" "mailu_api"
update_env_var "MAIL_MYSQL_PASSWORD" "${MAILU_API_PASSWORD}"
update_env_var "MCP_MYSQL_USER" "mcp_readonly"
update_env_var "MCP_MYSQL_PASSWORD" "${MCP_MYSQL_PASSWORD}"
update_env_var "MCP_POSTGRES_USER" "mcp_readonly"
update_env_var "MCP_POSTGRES_PASSWORD" "${MCP_POSTGRES_PASSWORD}"

echo -e "${GREEN}✓ Updated .env file${NC}"

echo ""
echo -e "${YELLOW}Step 4: Verification...${NC}"

# Verify MySQL users
echo "Verifying MySQL users..."
docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mariadb mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User IN ('mailu_api', 'mcp_readonly');"

# Verify PostgreSQL user
echo ""
echo "Verifying PostgreSQL users..."
docker exec postgres psql -U "${POSTGRES_USER:-admin}" -d "${POSTGRES_DB:-homeserver}" -c "\du mcp_readonly"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  DATABASE USERS SETUP COMPLETED${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT SECURITY NOTES:${NC}"
echo ""
echo "1. New database credentials have been generated and saved to .env"
echo "2. A backup of your .env file has been created"
echo "3. Passwords are stored in .env file - keep it secure!"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Restart affected services:"
echo "   ${BLUE}docker compose restart mail-api${NC}"
echo "   ${BLUE}docker compose -f docker-compose/docker-compose.mcp.yml restart${NC}"
echo ""
echo "2. Verify database connections are working"
echo ""
echo -e "${GREEN}Done!${NC}"
