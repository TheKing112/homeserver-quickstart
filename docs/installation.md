# Installation Guide

Complete step-by-step guide to installing your homeserver.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Prepare](#step-1-prepare)
- [Step 2: Create Bootable USB](#step-2-create-bootable-usb)
- [Step 3: Install Ubuntu](#step-3-install-ubuntu)
- [Step 4: Deploy Services](#step-4-deploy-services)
- [Step 5: Post-Installation](#step-5-post-installation)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Storage | 50 GB HDD | 100+ GB SSD |
| Network | 100 Mbit Ethernet | 1 Gbit Ethernet |

### Software Requirements

- Ubuntu Server 24.04 LTS ISO
- 8GB+ USB drive
- Rufus (Windows) or Etcher (Mac/Linux)
- SSH client (PuTTY, Windows Terminal, or terminal)

### Network Requirements

- Wired Ethernet connection
- Router with DHCP
- Ability to configure port forwarding (for external access)

## Step 1: Prepare

### 1.1 Download Repository
```bash
git clone https://github.com/YOUR_USERNAME/homeserver-quickstart.git
cd homeserver-quickstart
```

### 1.2 Generate Secrets

**Linux/Mac:**
```bash
bash scripts/00-generate-secrets.sh
```

**Windows:**
```powershell
.\windows-tools\generate-secrets.ps1
```

### 1.3 Configure Environment

Edit `.env` file:
```bash
# Essential settings to change:
SERVER_IP=192.168.1.100          # Your server IP
MAIL_DOMAINS=example.com         # Your domain(s)
SMTP_USER=your-email@gmail.com   # For notifications
SMTP_PASSWORD=your-app-password  # Gmail app password
```

**Important:** Save all generated passwords to a password manager!

## Step 2: Create Bootable USB

### Windows

1. Download [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server)
2. Download and install [Rufus](https://rufus.ie/)
3. Insert USB drive
4. Run Rufus:
   - Device: Your USB drive
   - Boot selection: Ubuntu ISO
   - Partition scheme: GPT
   - Target system: UEFI
5. Click START

### Mac/Linux

1. Download Ubuntu Server 24.04 LTS
2. Download [Etcher](https://etcher.balena.io/)
3. Insert USB drive
4. Run Etcher:
   - Select ISO
   - Select USB drive
   - Flash!

### Add Autoinstall

After creating bootable USB:

1. Mount the USB drive
2. Copy `autoinstall/` folder to USB root
3. Rename to `nocloud-ubuntu/`

Your USB structure:
```
USB Drive
â”œâ”€â”€ nocloud-ubuntu/
â”‚   â”œâ”€â”€ user-data
â”‚   â””â”€â”€ meta-data
â””â”€â”€ [other Ubuntu files]
```

## Step 3: Install Ubuntu

### 3.1 Boot from USB

1. Insert USB into server
2. Power on
3. Enter BIOS/UEFI (usually F2, F12, or DEL)
4. Set boot order: USB first
5. Save and exit

**Note:** You may need to disable Secure Boot

### 3.2 Automated Installation

The installation runs automatically!

**What happens:**
1. Ubuntu boots from USB
2. Reads autoinstall configuration
3. Partitions disk
4. Installs system
5. Configures network
6. Installs packages (Docker, WireGuard, etc.)
7. Sets up firewall
8. Creates admin user
9. Reboots

**Duration:** ~15 minutes

### 3.3 First Login

After reboot:
```bash
ssh admin@192.168.1.100
# Password: homeserver (CHANGE IMMEDIATELY!)

# Change password
passwd
```

## Step 4: Deploy Services

### 4.1 Copy Configuration

From your PC:
```bash
scp .env admin@192.168.1.100:/opt/homeserver-setup/
```

### 4.2 Run Quickstart

On the server:
```bash
cd /opt/homeserver-setup
sudo ./scripts/01-quickstart.sh
```

**What happens:**
1. Checks prerequisites
2. Creates directories
3. Copies files to `/opt/homeserver`
4. Creates Docker networks
5. Starts core services (Traefik, Portainer, Databases)
6. Starts monitoring (Grafana, Prometheus, Netdata)
7. Starts mail server (optional)
8. Starts MCP servers (optional)
9. Configures WireGuard

**Duration:** ~20-30 minutes

Watch the progress - it will show each step!

### 4.3 Verify Installation
```bash
# Check running containers
docker ps

# Check service status
cd /opt/homeserver
make status

# Run health check
make health
```

## Step 5: Post-Installation

### 5.1 Configure Hosts File

**Windows:** `C:\Windows\System32\drivers\etc\hosts`
**Linux/Mac:** `/etc/hosts`

Add:
```
192.168.1.100  homeserver.local home.homeserver.local
192.168.1.100  portainer.homeserver.local traefik.homeserver.local
192.168.1.100  vault.homeserver.local git.homeserver.local
192.168.1.100  code.homeserver.local db.homeserver.local
192.168.1.100  grafana.homeserver.local netdata.homeserver.local
192.168.1.100  mail.homeserver.local mcp.homeserver.local
```

**Or use Windows tool:**
```powershell
.\windows-tools\update-hosts.ps1 -ServerIP 192.168.1.100
```

### 5.2 Initial Service Setup

#### Portainer
1. Visit http://portainer.homeserver.local
2. Create admin account
3. Connect to local Docker environment

#### Vaultwarden
1. Visit http://vault.homeserver.local
2. Create account
3. Save all passwords from `.env`

#### Grafana
1. Visit http://grafana.homeserver.local
2. Login: `admin` / (password from .env)
3. Change password
4. Explore pre-configured dashboards

#### Gitea
1. Visit http://git.homeserver.local
2. Complete setup wizard
3. Create admin account

### 5.3 Security Hardening

#### Change Default Passwords
```bash
# Server admin password
passwd

# Update all service passwords in Vaultwarden
```

#### Setup SSH Keys
```bash
# On your PC
ssh-keygen -t ed25519
ssh-copy-id admin@192.168.1.100

# On server - disable password auth
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

#### Configure Firewall
```bash
# Check firewall status
sudo ufw status

# Allow specific IPs only (optional)
sudo ufw allow from 192.168.1.0/24
```

### 5.4 Configure Mail Server (Optional)

See [Mail Setup Guide](mail-setup.md)

### 5.5 Setup WireGuard Bonding (Optional)

See [WireGuard Setup Guide](wireguard-setup.md)

## Troubleshooting

### Installation Issues

**Autoinstall doesn't start**
- Verify USB structure: `nocloud-ubuntu/user-data` exists
- Check BIOS: Secure Boot disabled
- Try different USB port

**Network not configured**
- Edit `autoinstall/user-data`
- Change IP addresses to match your network
- Recreate USB

**Installation hangs**
- Wait 20 minutes
- Check server logs on screen
- Restart and try again

### Service Issues

**Services not starting**
```bash
# Check logs
docker compose logs [service-name]

# Restart service
docker compose restart [service-name]

# Check resources
docker stats
```

**Can't access services**
```bash
# Verify services running
docker ps

# Check firewall
sudo ufw status

# Test connectivity
ping 192.168.1.100
```

**Disk space full**
```bash
# Check space
df -h

# Clean up
docker system prune -af
```

### Getting Help

- Check logs: `/var/log/homeserver-install.log`
- Run health check: `make health`
- View service logs: `make logs`
- [Report issues](https://github.com/YOUR_USERNAME/homeserver-quickstart/issues)

## Next Steps

- [Configuration Guide](configuration.md)
- [Mail Setup](mail-setup.md)
- [Security Best Practices](security.md)
- [Backup Guide](backup.md)

---

Congratulations! Your homeserver is now running! ðŸŽ‰