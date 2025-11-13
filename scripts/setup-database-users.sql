-- ============================================
-- HOMESERVER DATABASE SECURITY SETUP
-- ============================================
-- This script creates dedicated database users with minimal privileges
-- Run these commands manually in your database containers

-- ============================================
-- MYSQL/MARIADB - Mail API User
-- ============================================
-- Connect to MariaDB:
-- docker exec -it mariadb mysql -u root -p

-- Create dedicated user for Mail API (replace PASSWORD with strong password)
CREATE USER IF NOT EXISTS 'mailu_api'@'%' IDENTIFIED BY 'CHANGE_ME_SECURE_PASSWORD';

-- Grant only necessary privileges on mailu database
GRANT SELECT, INSERT, UPDATE, DELETE ON mailu.* TO 'mailu_api'@'%';

-- Apply privileges
FLUSH PRIVILEGES;

-- Verify user creation
SELECT User, Host FROM mysql.user WHERE User = 'mailu_api';

-- Test connection (from another terminal):
-- docker exec -it mariadb mysql -u mailu_api -p mailu


-- ============================================
-- MYSQL/MARIADB - MCP Read-Only User
-- ============================================

-- Create read-only user for MCP services
CREATE USER IF NOT EXISTS 'mcp_readonly'@'%' IDENTIFIED BY 'CHANGE_ME_MCP_PASSWORD';

-- Grant read-only access to homeserver database
GRANT SELECT ON homeserver.* TO 'mcp_readonly'@'%';

-- Apply privileges
FLUSH PRIVILEGES;

-- Verify user creation
SELECT User, Host FROM mysql.user WHERE User = 'mcp_readonly';


-- ============================================
-- POSTGRESQL - MCP Read-Only User
-- ============================================
-- Connect to PostgreSQL:
-- docker exec -it postgres psql -U admin -d homeserver

-- Create read-only user for MCP services
CREATE USER mcp_readonly WITH PASSWORD 'CHANGE_ME_MCP_PG_PASSWORD';

-- Grant connect permission
GRANT CONNECT ON DATABASE homeserver TO mcp_readonly;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO mcp_readonly;

-- Grant select on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mcp_readonly;

-- Grant select on future tables (important!)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO mcp_readonly;

-- Grant usage on sequences (for reading sequence values)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO mcp_readonly;

-- Verify user creation
\du mcp_readonly

-- Test connection (from another terminal):
-- docker exec -it postgres psql -U mcp_readonly -d homeserver


-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- MySQL/MariaDB - Check user privileges
SHOW GRANTS FOR 'mailu_api'@'%';
SHOW GRANTS FOR 'mcp_readonly'@'%';

-- PostgreSQL - Check user privileges
-- \du+ mcp_readonly
-- \dp (shows table permissions)


-- ============================================
-- CLEANUP (if needed)
-- ============================================

-- MySQL/MariaDB - Remove users if needed
-- DROP USER IF EXISTS 'mailu_api'@'%';
-- DROP USER IF EXISTS 'mcp_readonly'@'%';
-- FLUSH PRIVILEGES;

-- PostgreSQL - Remove user if needed
-- DROP USER IF EXISTS mcp_readonly;


-- ============================================
-- NOTES
-- ============================================
-- After creating users, update these files:
-- 
-- 1. .env file:
--    MAIL_MYSQL_USER=mailu_api
--    MAIL_MYSQL_PASSWORD=your_secure_password
--    MCP_MYSQL_USER=mcp_readonly
--    MCP_MYSQL_PASSWORD=your_mcp_password
--    MCP_POSTGRES_USER=mcp_readonly
--    MCP_POSTGRES_PASSWORD=your_mcp_pg_password
--
-- 2. Restart affected services:
--    docker-compose restart mail-api
--    docker-compose -f docker-compose/docker-compose.mcp.yml restart
