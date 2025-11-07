# Configuration Guide

Detailed configuration options for all services.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Service Configuration](#service-configuration)
- [Network Configuration](#network-configuration)
- [Storage Configuration](#storage-configuration)

## Environment Variables

All configuration is in `.env` file at repository root.

### Core Settings
```bash
# Project name (used for container naming)
COMPOSE_PROJECT_NAME=homeserver

# Timezone (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
TZ=Europe/Berlin

# Server IP address
SERVER_IP=192.168.1.100
```

### Database Configuration
```bash
# PostgreSQL
POSTGRES_USER=admin              # Database admin user
POSTGRES_PASSWORD=xxx            # Secure password (auto-generated)
POSTGRES_DB=homeserver          # Default database name

# MariaDB/MySQL
MYSQL_ROOT_PASSWORD=xxx         # Root password
MYSQL_DATABASE=homeserver       # Default database
MYSQL_USER=admin                # Application user
MYSQL_PASSWORD=xxx              # User password

# Redis
REDIS_PASSWORD=xxx              # Redis authentication password
```

### Mail Server Configuration
```bash
# Primary domain (used for Mailu)
MAIL_PRIMARY_DOMAIN=homeserver.local

# All mail domains (comma-separated)
MAIL_DOMAINS=homeserver.local,example.com

# Mail server secrets
MAIL_SECRET_KEY=xxx
MAIL_MYSQL_ROOT_PASSWORD=xxx
MAIL_MYSQL_PASSWORD=xxx
MAIL_API_TOKEN=xxx

# SMTP for outgoing notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

**Gmail App Password:** [Create here](https://myaccount.google.com/apppasswords)

### Development Tools
```bash
# Gitea OAuth (configured after Gitea setup)
GITEA_OAUTH_CLIENT_ID=
GITEA_OAUTH_CLIENT_SECRET=

# Drone CI
DRONE_RPC_SECRET=xxx

# VS Code Server
CODE_SERVER_PASSWORD=xxx
```

### Monitoring
```bash
# Grafana admin password
GRAFANA_ADMIN_PASSWORD=xxx
```

### Backup
```bash
# Restic encryption password
RESTIC_PASSWORD=xxx

# Backup schedule (cron format)
BACKUP_SCHEDULE=0 2 * * *  # Daily at 2 AM
```

### Security
```bash
# Vaultwarden admin panel token
VAULTWARDEN_ADMIN_TOKEN=xxx
```

## Service Configuration

### Traefik (Reverse Proxy)

**Location:** `configs/traefik/traefik.yml`
```yaml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
```

**Enable SSL/TLS:**
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

### Homepage Dashboard

**Location:** `configs/homepage/`

**Add custom services:**
`services.yaml`:
```yaml
- Custom:
    - My Service:
        href: http://myservice.homeserver.local
        description: My custom application
        icon: custom-icon.png
```

**Add widgets:**
`widgets.yaml`:
```yaml
- datetime:
    text_size: xl
    format:
      dateStyle: long
```

### Grafana Dashboards

**Import dashboards:**

1. Visit http://grafana.homeserver.local
2. Dashboards â†’ Import
3. Enter dashboard ID or upload JSON

**Recommended:**
- Docker Container Stats: `193`
- Node Exporter Full: `1860`
- Redis Dashboard: `11835`

### Prometheus Metrics

**Location:** `configs/prometheus/prometheus.yml`

**Add custom scrape targets:**
```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['my-app:9090']
```

## Network Configuration

### Change Server IP

1. Edit `autoinstall/user-data`:
```yaml
network:
  ethernets:
    any:
      addresses: [192.168.1.200/24]  # New IP
```

2. Edit `.env`:
```bash
SERVER_IP=192.168.1.200
```

### Add Custom Domain

1. Add to `.env`:
```bash
MAIL_DOMAINS=homeserver.local,example.com,example2.com
```

2. Configure DNS:
```dns
example.com.     IN A     YOUR_PUBLIC_IP
mail            IN A     YOUR_PUBLIC_IP
@               IN MX 10 mail.example.com.
```

3. Add domain in Mailu admin panel

### Port Forwarding

For external access, forward these ports in your router:

| Port | Protocol | Service |
|------|----------|---------|
| 80 | TCP | HTTP (Traefik) |
| 443 | TCP | HTTPS (Traefik) |
| 25 | TCP | SMTP |
| 465 | TCP | SMTPS |
| 587 | TCP | Submission |
| 993 | TCP | IMAPS |
| 143 | TCP | IMAP |

## Storage Configuration

### Change Storage Locations

Edit `docker-compose/docker-compose.yml`:
```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      device: /mnt/external/postgres
      o: bind
```

### Add External Storage
```bash
# Mount external drive
sudo mkdir -p /mnt/external
sudo mount /dev/sdb1 /mnt/external

# Auto-mount on boot
sudo nano /etc/fstab
# Add: /dev/sdb1 /mnt/external ext4 defaults 0 2
```

### Backup Configuration

**Location:** `scripts/backup.sh`
```bash
# Backup to external drive
BACKUP_DIR="/mnt/external/backups/restic-repo"

# Backup to cloud (BackBlaze B2 example)
export RESTIC_REPOSITORY="b2:bucket-name:path"
export B2_ACCOUNT_ID="your-id"
export B2_ACCOUNT_KEY="your-key"
```

## Advanced Configuration

### Resource Limits

Add to service in `docker-compose.yml`:
```yaml
services:
  myservice:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          memory: 256M
```

### Custom Networks
```yaml
networks:
  dmz:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Service Dependencies
```yaml
services:
  webapp:
    depends_on:
      postgres:
        condition: service_healthy
```

## Applying Changes

After editing configuration:
```bash
cd /opt/homeserver

# Restart specific service
docker compose restart [service]

# Or restart everything
make restart
```

## See Also

- [Installation Guide](installation.md)
- [Mail Setup](mail-setup.md)
- [Security Guide](security.md)