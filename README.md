# 🏠 Homeserver Quickstart

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu)](https://ubuntu.com/)
[![Docker](https://img.shields.io/badge/Docker-27.0+-2496ED?logo=docker)](https://www.docker.com/)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

> 🚀 **Vollständiger Homeserver-Stack in 15 Minuten** - Docker-basiert, produktionsreif, umfassend dokumentiert.

<<<<<<< HEAD
---

## ✨ Features

### Core Services
- 🔄 **Traefik** - Reverse Proxy mit Let's Encrypt
- 🐳 **Portainer** - Docker Management UI
- 📊 **Homepage** - Zentrales Dashboard
- 🗄️ **PostgreSQL, MariaDB, Redis** - Datenbank-Stack
- 📈 **Grafana + Prometheus + Netdata** - Monitoring
- 🔐 **Vaultwarden** - Passwort-Manager

### Development
- 🔧 **Gitea** - Self-Hosted Git Server
- 🚀 **Drone CI** - Continuous Integration
- 💻 **Code-Server** - VS Code im Browser
- 📦 **Docker Registry** - Private Container Registry

### Optional
- 📧 **Mail Server** - Mailu (konfigurierbar)
- 🤖 **MCP Servers** - AI Integration (5 Server)
- 💾 **Restic** - Automatische Backups
- 🔄 **Watchtower** - Auto-Updates

**Gesamt: 25+ vorkonfigurierte Services**

---

## 🎯 Quick Start

### Voraussetzungen

- Ubuntu 24.04 LTS Server
- 8+ GB RAM, 100+ GB Speicher
- Feste IP-Adresse (z.B. 192.168.1.100)
- Internet-Verbindung

### Installation (5 Befehle, 15 Minuten)

```bash
# 1. Projekt klonen
cd /opt
sudo git clone <your-repo-url> homeserver-setup
sudo chown -R $USER:$USER homeserver-setup
cd homeserver-setup

# 2. Secrets generieren
./scripts/00-generate-secrets.sh
# ⚠️ ALLE PASSWÖRTER NOTIEREN! ⚠️

# 3. .env anpassen
nano .env
# SERVER_IP, MAIL_PRIMARY_DOMAIN, TRAEFIK_ACME_EMAIL ändern

# 4. Installation starten
sudo ./install-homeserver.sh
# ⏱️ Dauer: ~10-15 Minuten

# 5. Status prüfen
docker ps
```

### Erste Schritte

1. **Hosts-Datei aktualisieren:**
   ```bash
   # Windows (als Admin):
   Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 home.homeserver.local"
   
   # Linux/Mac:
   echo "192.168.1.100 home.homeserver.local" | sudo tee -a /etc/hosts
   ```

2. **Dashboard öffnen:** http://home.homeserver.local

3. **Services konfigurieren:** Siehe [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md)

---

## 📚 Dokumentation

| Dokument | Beschreibung | Zielgruppe |
|----------|--------------|------------|
| [**SERVER_EINRICHTUNG_ANLEITUNG.md**](SERVER_EINRICHTUNG_ANLEITUNG.md) | Vollständige Schritt-für-Schritt Anleitung (15.000+ Wörter) | Einsteiger bis Fortgeschritten |
| [**QUICK_START_GUIDE.md**](QUICK_START_GUIDE.md) | Kompakter Guide für Profis (5.000+ Wörter) | Fortgeschrittene |
| [**BUGS_AND_FIXES.md**](BUGS_AND_FIXES.md) | Bekannte Bugs und Lösungen | Alle |
| [**CHANGELOG.md**](CHANGELOG.md) | Versions-Historie | Alle |
| [docs/configuration.md](docs/configuration.md) | Erweiterte Konfiguration | Fortgeschrittene |
| [docs/installation.md](docs/installation.md) | Alternative Installations-Methoden | Alle |
| [docs/mail-setup.md](docs/mail-setup.md) | Mail-Server Konfiguration | Fortgeschrittene |

---

## 🌐 Service-URLs

Nach der Installation sind folgende Services verfügbar:

| Service | URL | Beschreibung |
|---------|-----|--------------|
| Homepage | http://home.homeserver.local | Zentrale Übersicht |
| Traefik | http://traefik.homeserver.local | Reverse Proxy Dashboard |
| Portainer | http://portainer.homeserver.local | Container Management |
| Gitea | http://gitea.homeserver.local | Git Server |
| Grafana | http://grafana.homeserver.local | Monitoring Dashboards |
| Adminer | http://db.homeserver.local | Datenbank UI |
| Code-Server | http://code.homeserver.local | VS Code Web |
| Registry | http://registry.homeserver.local | Docker Registry |
| Vaultwarden | http://vault.homeserver.local | Passwort-Manager |
| Netdata | http://netdata.homeserver.local | System Monitoring |

**Vollständige Liste:** Siehe [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md#service-übersicht)

---

## 🔐 Sicherheit

### ✅ Implementierte Sicherheitsmaßnahmen

- ✅ Automatische Secret-Generierung (keine Defaults)
- ✅ Basic Auth für alle Admin-UIs (Portainer, Adminer, Grafana, etc.)
- ✅ Docker Registry mit Authentifizierung
- ✅ Firewall-Konfiguration (UFW)
- ✅ Keine hardcodierten Passwörter im Code
- ✅ Sichere JSON-Konstruktion (Injection-Schutz)
- ✅ Docker-Netzwerk-Isolation (frontend/backend)

### 🛡️ Empfohlene Zusatz-Maßnahmen

- SSH-Keys statt Passwörter
- Fail2ban Installation
- Let's Encrypt für öffentliche Services
- VPN (WireGuard) für Remote-Zugriff
- Regelmäßige Backups testen

**Details:** [SERVER_EINRICHTUNG_ANLEITUNG.md - Sicherheit](SERVER_EINRICHTUNG_ANLEITUNG.md#sicherheit)

---

## 💾 Backup & Restore

### Automatische Backups

```bash
# Backups laufen automatisch täglich um 2:00 Uhr
# Manuelles Backup:
cd /opt/homeserver
./scripts/backup.sh

# Snapshots anzeigen:
export RESTIC_PASSWORD=$(grep RESTIC_PASSWORD .env | cut -d= -f2)
restic -r /backup snapshots
```

### Wiederherstellung

```bash
# Komplettes Restore:
cd /opt/homeserver
./scripts/restore.sh

# Oder spezifischen Snapshot:
restic -r /backup restore <snapshot-id> --target /restore-path
```

**Details:** [SERVER_EINRICHTUNG_ANLEITUNG.md - Backup & Restore](SERVER_EINRICHTUNG_ANLEITUNG.md#backup--restore)

---

## 🔧 Wartung

### Updates

```bash
# Container-Updates (automatisch via Watchtower)
# Manuell:
cd /opt/homeserver/docker-compose
docker compose pull
docker compose up -d

# System-Updates:
sudo apt update && sudo apt upgrade -y
```

### Monitoring

```bash
# Container-Status:
docker ps

# Logs:
docker logs -f <container-name>

# Ressourcen:
docker stats
```

**Details:** [SERVER_EINRICHTUNG_ANLEITUNG.md - Wartung](SERVER_EINRICHTUNG_ANLEITUNG.md#wartung--updates)

---

## 🐛 Troubleshooting

### Häufige Probleme

**Container startet nicht:**
```bash
docker logs <container-name>
docker restart <container-name>
```

**Service nicht erreichbar:**
```bash
# 1. Container läuft?
docker ps | grep <service>

# 2. Traefik-Routing?
docker logs traefik | grep <service>

# 3. Hosts-Datei korrekt?
ping home.homeserver.local
```

**Datenbank-Verbindung fehlgeschlagen:**
```bash
# PostgreSQL:
docker exec -it postgres psql -U admin -d homeserver

# MariaDB:
docker exec -it mariadb mysql -u root -p
```

**Vollständige Troubleshooting-Guide:** [SERVER_EINRICHTUNG_ANLEITUNG.md - Troubleshooting](SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting)

---

## 📦 Projekt-Struktur

```
homeserver-quickstart/
├── autoinstall/              # Ubuntu Auto-Installation
├── configs/                  # Service-Konfigurationen
│   ├── traefik/             # Reverse Proxy Config
│   ├── grafana/             # Monitoring Dashboards
│   ├── prometheus/          # Metriken-Sammlung
│   └── ...
├── docker-compose/          # Docker Compose Files
│   ├── docker-compose.yml           # Haupt-Services
│   ├── docker-compose.monitoring.yml # Monitoring-Stack
│   └── docker-compose.mcp.yml       # MCP-Server
├── scripts/                 # Installations- & Wartungs-Scripts
│   ├── 00-generate-secrets.sh       # Secret-Generierung
│   ├── backup.sh                    # Backup-Script
│   └── ...
├── mail-api/                # Mail-Management API (Python)
├── mcp-servers/             # MCP Server Implementierungen (Node.js)
├── docs/                    # Zusätzliche Dokumentation
├── examples/                # Beispiel-Konfigurationen
├── windows-tools/           # Windows-Management Scripts (PowerShell)
├── .env.example             # Umgebungsvariablen-Template
├── install-homeserver.sh    # Haupt-Installations-Script
├── quick-start.sh           # Quick-Start Script
├── README.md                # Diese Datei
├── SERVER_EINRICHTUNG_ANLEITUNG.md  # Vollständige Anleitung
├── QUICK_START_GUIDE.md     # Kurzanleitung
├── BUGS_AND_FIXES.md        # Bug-Dokumentation
└── CHANGELOG.md             # Versions-Historie
```

---

## 🤝 Mitmachen

Beiträge sind willkommen! Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Details.

### Bug melden

1. [Bekannte Bugs prüfen](BUGS_AND_FIXES.md)
2. [Issue erstellen](.github/ISSUE_TEMPLATE/bug_report.md)
3. Logs und Umgebungsdetails angeben

### Feature vorschlagen

1. [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)
2. Use-Case beschreiben
3. Community-Diskussion abwarten

---

## 📊 Systemanforderungen

### Minimum (Persönliche Nutzung)
- **CPU:** 4 Kerne
- **RAM:** 8 GB
- **Disk:** 64 GB SSD + 500 GB HDD
- **Netzwerk:** 1 Gbit

### Empfohlen (Kleine Teams)
- **CPU:** 6-8 Kerne
- **RAM:** 16-32 GB
- **Disk:** 256 GB NVMe + 2 TB HDD
- **Netzwerk:** 1-2.5 Gbit

### High-End (Production)
- **CPU:** 8+ Kerne (Xeon/EPYC)
- **RAM:** 64+ GB ECC
- **Disk:** 512 GB NVMe RAID + 4 TB SSD RAID
- **Netzwerk:** 10 Gbit, redundant

**Details:** [SERVER_EINRICHTUNG_ANLEITUNG.md - Hardware](SERVER_EINRICHTUNG_ANLEITUNG.md#hardware-empfehlungen)

---

## 🎯 Roadmap

### v2.1 (Q1 2025)
- [ ] Kubernetes Deployment Option
- [ ] High-Availability Setup
- [ ] Advanced Monitoring Alerts
- [ ] Automated Security Scanning

### v3.0 (Q2 2025)
- [ ] Web-based Setup Wizard
- [ ] Plugin System
- [ ] Multi-Server Support
- [ ] Mobile Management App

**Vollständig:** [CHANGELOG.md - Unreleased](CHANGELOG.md#unreleased)

---

## 📜 Lizenz

MIT License - siehe [LICENSE](LICENSE) für Details.

---

## 🙏 Credits

Entwickelt mit folgenden Open-Source Projekten:
- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/)
- [Gitea](https://gitea.io/)
- [Grafana](https://grafana.com/)
- [Portainer](https://www.portainer.io/)
- ... und viele mehr

---

## 📞 Support

- 📖 **Dokumentation:** [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md)
- 🐛 **Bugs:** [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md)
- 💬 **Diskussionen:** GitHub Discussions
- 📧 **E-Mail:** support@example.com

---

## ⚡ Status

**Version:** 2.0.0  
**Status:** ✅ **PRODUKTIONSREIF**  
**Letztes Update:** 2025-11-13

- ✅ Alle kritischen Bugs behoben
- ✅ Umfassende Dokumentation
- ✅ Sicherheit gehärtet
- ✅ Getestet und verifiziert

**→ Bereit für den produktiven Einsatz!**

---

**⭐ Star dieses Projekt auf GitHub wenn es dir hilft!**
=======
## 📋 Features

This homeserver quickstart provides a complete, production-ready setup including:

### 🔧 Core Services
- **Traefik v3** - Reverse proxy with automatic SSL
- **PostgreSQL & MariaDB** - Database servers
- **Redis** - In-memory data store
- **Portainer** - Docker container management
- **Gitea** - Git server with UI
- **Drone CI/CD** - Automated build and deployment

### 🔐 Security & Authentication
- **Vaultwarden** - Password manager (Bitwarden compatible)
- **WireGuard** - VPN server configuration
- **Automated SSL** - Let's Encrypt certificates via Traefik

### 📊 Monitoring & Management
- **Grafana** - Metrics visualization
- **Prometheus** - Metrics collection
- **Homepage** - Service dashboard
- **Adminer** - Database web interface
- **Redis Commander** - Redis web interface

### 📧 Communication
- **Mail Server** - Complete mail server setup (Mailu)
- **Mail API** - RESTful API for mail management

### 🛠️ Development Tools
- **Code Server** - Web-based VS Code
- **Docker Registry** - Private container registry
- **Registry UI** - Web interface for registry

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 LTS server
- Root/sudo access
- At least 4GB RAM, 50GB storage
- Internet connection

### 1. Generate Configuration
```bash
# Generate secure secrets and configuration
./scripts/00-generate-secrets.sh
```

### 2. Install System
```bash
# Run automated installation (requires sudo)
sudo ./scripts/01-quickstart.sh
```

### 3. Access Services
After installation, access your services at:
- **Homepage**: http://home.homeserver.local
- **Portainer**: http://portainer.homeserver.local
- **Grafana**: http://grafana.homeserver.local
- **Traefik**: http://traefik.homeserver.local

## 🏗️ Architecture

```
                    ┌─────────────────┐
                    │  Internet/SSL   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Traefik v3    │
                    │  (Reverse Proxy)│
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
     ┌──────▼──────┐  ┌─────▼─────┐  ┌──────▼──────┐
     │   Frontend  │  │ Monitoring│  │   Backend   │
     │   Services  │  │   Stack   │  │  Services   │
     └─────────────┘  └───────────┘  └─────────────┘
```

## 📁 Project Structure

```
homeserver-quickstart/
├── .github/workflows/     # CI/CD pipelines
├── autoinstall/          # Ubuntu autoinstall files
├── configs/              # Service configurations
├── docker-compose/       # Docker compose files
├── docs/                 # Documentation
├── examples/             # Example configurations
├── mail-api/             # Mail management API
├── mcp-servers/          # MCP server configurations
├── scripts/              # Installation and management scripts
├── windows-tools/        # Windows-specific tools
├── .env.example          # Environment template
├── Makefile              # Management commands
└── README.md             # This file
```

## 🔧 Management Commands

Use the Makefile for common operations:

```bash
# Start all services
make start

# Stop all services
make stop

# View logs
make logs

# Check service status
make status

# Health check
make health

# Update all services
make update

# Backup data
make backup

# Clean up
make clean
```

## 🔒 Security

- All services run with security best practices
- Network isolation between frontend and backend
- Automated SSL certificate management
- Password generation with cryptographically secure methods
- Regular security updates via Watchtower

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Service Documentation](docs/services/)
- [Troubleshooting](docs/troubleshooting.md)
- [Development Guide](docs/development.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- [Issues](https://github.com/TheKing112/homeserver-quickstart/issues)
- [Discussions](https://github.com/TheKing112/homeserver-quickstart/discussions)
- Email: support@homeserver.local

## 🎯 Roadmap

- [ ] Kubernetes deployment option
- [ ] More service templates
- [ ] Backup and restore automation
- [ ] Monitoring alerts configuration
- [ ] Performance optimization guides

---

**Made with ❤️ for the self-hosting community**
>>>>>>> 12ffc10e51b5ddd256ba4dfe740324cde8144af0
