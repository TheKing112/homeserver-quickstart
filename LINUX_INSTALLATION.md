# 🐧 Homeserver Installation - Linux Komplettanleitung

## 📋 Inhaltsverzeichnis

1. [Systemanforderungen](#systemanforderungen)
2. [Vorbereitung](#vorbereitung)
3. [Installation](#installation)
4. [Konfiguration](#konfiguration)
5. [Start](#start)
6. [Zugriff](#zugriff)
7. [Fehlerbehebung](#fehlerbehebung)

---

## 📊 Systemanforderungen

### Minimum:
- **OS:** Ubuntu 20.04+, Debian 11+, CentOS 8+, Fedora 35+
- **RAM:** 4 GB
- **Speicher:** 20 GB frei
- **CPU:** 2 Kerne

### Empfohlen:
- **OS:** Ubuntu 22.04 LTS oder Debian 12
- **RAM:** 8 GB oder mehr
- **Speicher:** 50 GB SSD
- **CPU:** 4 Kerne

---

## 🔧 Vorbereitung

### Schritt 1: System aktualisieren

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL/Fedora
sudo dnf update -y

# Neustart empfohlen
sudo reboot
```

### Schritt 2: Docker installieren

#### Ubuntu/Debian:

```bash
# Alte Versionen entfernen
sudo apt remove docker docker-engine docker.io containerd runc -y

# Dependencies installieren
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker GPG Key hinzufügen
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker Repository hinzufügen
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker installieren
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker ohne sudo nutzen
sudo usermod -aG docker $USER

# Neuanmeldung erforderlich!
newgrp docker
```

#### CentOS/RHEL/Fedora:

```bash
# Docker Repository hinzufügen
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Docker installieren
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker starten
sudo systemctl start docker
sudo systemctl enable docker

# User zu Docker-Gruppe hinzufügen
sudo usermod -aG docker $USER
newgrp docker
```

### Schritt 3: Docker-Installation testen

```bash
# Docker Version prüfen
docker --version
docker compose version

# Test-Container
docker run hello-world
```

**✅ Erwartete Ausgabe:** "Hello from Docker!"

---

## 💾 Installation

### Methode 1: Automatisches Installations-Skript (EMPFOHLEN)

```bash
# 1. Projekt klonen/herunterladen
cd /opt
sudo git clone https://github.com/YOUR-REPO/homeserver-quickstart.git
# ODER wenn Sie die Dateien schon haben:
sudo cp -r /workspace/Homeserver/homeserver-quickstart /opt/

# 2. Rechte setzen
sudo chown -R $USER:$USER /opt/homeserver-quickstart
cd /opt/homeserver-quickstart

# 3. Automatisches Installations-Skript ausführen
chmod +x install-homeserver.sh
./install-homeserver.sh
```

### Methode 2: Manuelle Installation (Schritt für Schritt)

#### Schritt 1: Verzeichnis vorbereiten

```bash
# Installations-Verzeichnis erstellen
sudo mkdir -p /opt/homeserver
sudo chown -R $USER:$USER /opt/homeserver
cd /opt/homeserver

# Projekt-Dateien kopieren
cp -r /workspace/Homeserver/homeserver-quickstart/* .
```

#### Schritt 2: Umgebungsvariablen konfigurieren

```bash
# .env-Datei erstellen
cp .env.example .env

# .env bearbeiten
nano .env
```

**Wichtige Variablen anpassen:**

```bash
# System
TZ=Europe/Berlin
SERVER_IP=192.168.1.100  # IHRE SERVER-IP

# Datenbank-Passwörter (WICHTIG: ÄNDERN!)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

# Service-Passwörter
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 24)
CODE_SERVER_PASSWORD=$(openssl rand -base64 24)
VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -hex 32)
DRONE_RPC_SECRET=$(openssl rand -hex 32)

# Email für Let's Encrypt
TRAEFIK_ACME_EMAIL=ihre-email@example.com
```

**Tipp:** Passwörter automatisch generieren:

```bash
# Automatisches Secrets-Skript
chmod +x scripts/00-generate-secrets.sh
./scripts/00-generate-secrets.sh
```

#### Schritt 3: Docker-Netzwerke erstellen

```bash
docker network create frontend
docker network create backend
```

#### Schritt 4: Firewall konfigurieren (falls aktiv)

**UFW (Ubuntu):**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw status
```

**Firewalld (CentOS/RHEL):**
```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

**iptables (falls verwendet):**
```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---

## 🚀 Start

### Services starten

```bash
cd /opt/homeserver/docker-compose

# 1. Haupt-Services starten
docker compose -f docker-compose.yml up -d

# Warten auf Initialisierung (30 Sekunden)
sleep 30

# Status prüfen
docker compose -f docker-compose.yml ps

# 2. Monitoring starten (optional)
docker compose -f docker-compose.monitoring.yml up -d

# 3. MCP-Server starten (optional)
docker compose -f docker-compose.mcp.yml up -d
```

### Status überprüfen

```bash
# Alle laufenden Container
docker ps

# Logs live verfolgen
docker compose -f docker-compose.yml logs -f

# Spezifischen Service prüfen
docker logs traefik
docker logs portainer
docker logs grafana
```

---

## 🌐 Zugriff

### Hosts-Datei konfigurieren

**Auf Ihrem Client-PC (Windows/Linux/Mac):**

#### Linux/Mac:
```bash
sudo nano /etc/hosts
```

#### Windows:
```powershell
# Als Administrator:
notepad C:\Windows\System32\drivers\etc\hosts
```

**Einträge hinzufügen:**
```
# Ersetzen Sie 192.168.1.100 mit Ihrer Server-IP
192.168.1.100  home.homeserver.local
192.168.1.100  portainer.homeserver.local
192.168.1.100  traefik.homeserver.local
192.168.1.100  grafana.homeserver.local
192.168.1.100  prometheus.homeserver.local
192.168.1.100  netdata.homeserver.local
192.168.1.100  git.homeserver.local
192.168.1.100  drone.homeserver.local
192.168.1.100  vault.homeserver.local
192.168.1.100  code.homeserver.local
192.168.1.100  db.homeserver.local
192.168.1.100  redis.homeserver.local
192.168.1.100  www.homeserver.local
192.168.1.100  registry.homeserver.local
192.168.1.100  registry-ui.homeserver.local
```

### Service-URLs

Nach der Installation sind folgende Services verfügbar:

| Service | URL | Standard-Login |
|---------|-----|----------------|
| **Homepage Dashboard** | http://home.homeserver.local | - |
| **Portainer** | http://portainer.homeserver.local | Admin bei Erstbesuch anlegen |
| **Traefik** | http://traefik.homeserver.local:8080 | - |
| **Grafana** | http://grafana.homeserver.local | admin / aus .env |
| **Prometheus** | http://prometheus.homeserver.local | - |
| **Netdata** | http://netdata.homeserver.local | - |
| **Gitea** | http://git.homeserver.local | Bei Erstbesuch einrichten |
| **Drone CI** | http://drone.homeserver.local | Via Gitea OAuth |
| **Vaultwarden** | http://vault.homeserver.local | Registrieren |
| **Code-Server** | http://code.homeserver.local | Passwort aus .env |
| **Adminer** | http://db.homeserver.local | DB-Credentials aus .env |
| **Docker Registry** | http://registry.homeserver.local | - |
| **Registry UI** | http://registry-ui.homeserver.local | - |

---

## 📝 Ersteinrichtung

### 1. Portainer einrichten

```
URL: http://portainer.homeserver.local
1. Admin-Benutzer erstellen
2. "Get Started" klicken
3. Local Docker Environment auswählen
```

### 2. Gitea einrichten

```
URL: http://git.homeserver.local
1. Datenbank-Einstellungen:
   - Typ: PostgreSQL
   - Host: postgres:5432
   - Benutzer: admin (aus .env POSTGRES_USER)
   - Passwort: aus .env POSTGRES_PASSWORD
   - Datenbank: gitea

2. Basis-Einstellungen:
   - Server-Domain: git.homeserver.local
   - SSH-Port: 22
   - HTTP-URL: http://git.homeserver.local
   
3. Admin-Account erstellen
4. "Installation abschließen" klicken
```

### 3. Grafana einrichten

```
URL: http://grafana.homeserver.local
Login: admin / GRAFANA_ADMIN_PASSWORD (aus .env)

1. Data Source hinzufügen:
   - Typ: Prometheus
   - URL: http://prometheus:9090
   - "Save & Test"

2. Dashboards importieren:
   - Node Exporter Dashboard: ID 1860
   - Docker Dashboard: ID 893
   - Traefik Dashboard: ID 4475
```

### 4. Vaultwarden (Passwort-Manager)

```
URL: http://vault.homeserver.local
1. Account erstellen
2. Master-Passwort festlegen (WICHTIG: Merken!)
3. Browser-Extension installieren (optional)
```

---

## 🔧 Wartung

### Container verwalten

```bash
cd /opt/homeserver/docker-compose

# Status anzeigen
docker compose -f docker-compose.yml ps

# Services neu starten
docker compose -f docker-compose.yml restart

# Services stoppen
docker compose -f docker-compose.yml stop

# Services starten
docker compose -f docker-compose.yml start

# Services herunterfahren
docker compose -f docker-compose.yml down

# Logs anzeigen
docker compose -f docker-compose.yml logs -f [service-name]
```

### Updates durchführen

```bash
cd /opt/homeserver/docker-compose

# Images aktualisieren
docker compose -f docker-compose.yml pull

# Services neu starten
docker compose -f docker-compose.yml up -d

# Alte Images löschen
docker image prune -a
```

### Backup erstellen

```bash
# Backup-Verzeichnis erstellen
sudo mkdir -p /backup/homeserver

# Volumes sichern
docker run --rm \
  -v portainer_data:/source \
  -v /backup/homeserver:/backup \
  alpine tar czf /backup/portainer_$(date +%Y%m%d).tar.gz -C /source .

# Für alle wichtigen Volumes wiederholen:
# postgres_data, mariadb_data, gitea_data, vaultwarden_data
```

### Automatisches Backup (Cron)

```bash
# Cron-Job einrichten
crontab -e

# Folgendes hinzufügen:
0 2 * * * /opt/homeserver/scripts/backup.sh
```

---

## ⚠️ Fehlerbehebung

### Container startet nicht

```bash
# Logs prüfen
docker logs <container-name>

# Beispiel:
docker logs traefik
docker logs postgres

# Container neu starten
docker restart <container-name>
```

### Port bereits belegt

```bash
# Welcher Prozess nutzt Port 80?
sudo lsof -i :80
sudo netstat -tulpn | grep :80

# Prozess stoppen
sudo systemctl stop nginx  # oder apache2

# Oder in docker-compose.yml Port ändern
```

### Datenbank-Verbindung fehlgeschlagen

```bash
# PostgreSQL-Health-Check
docker exec postgres pg_isready -U admin

# In Datenbank einloggen
docker exec -it postgres psql -U admin -d homeserver

# MariaDB-Health-Check
docker exec mariadb mysqladmin ping -u root -p

# In Datenbank einloggen
docker exec -it mariadb mysql -u root -p
```

### Service nicht erreichbar

**1. Container läuft?**
```bash
docker ps | grep <service-name>
```

**2. Netzwerk korrekt?**
```bash
docker network inspect frontend
docker network inspect backend
```

**3. Hosts-Datei konfiguriert?**
```bash
# Auf Client-PC:
ping home.homeserver.local
```

**4. Firewall blockiert?**
```bash
# Status prüfen
sudo ufw status
sudo firewall-cmd --list-all

# Temporär deaktivieren zum Testen
sudo ufw disable
sudo systemctl stop firewalld
```

### Alle Services neu starten

```bash
cd /opt/homeserver/docker-compose

# Alles stoppen
docker compose -f docker-compose.yml down
docker compose -f docker-compose.monitoring.yml down
docker compose -f docker-compose.mcp.yml down

# Netzwerke neu erstellen
docker network rm frontend backend
docker network create frontend
docker network create backend

# Alles neu starten
docker compose -f docker-compose.yml up -d
sleep 30
docker compose -f docker-compose.monitoring.yml up -d
docker compose -f docker-compose.mcp.yml up -d
```

---

## 🔒 Sicherheit

### Wichtige Sicherheitsmaßnahmen

**1. Passwörter ändern**
```bash
# ALLE Passwörter in .env ändern
nano /opt/homeserver/.env

# Besonders wichtig:
# - POSTGRES_PASSWORD
# - MYSQL_ROOT_PASSWORD
# - GRAFANA_ADMIN_PASSWORD
# - VAULTWARDEN_ADMIN_TOKEN
```

**2. Firewall aktivieren**
```bash
# UFW
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**3. HTTPS aktivieren (Produktiv)**

In `configs/traefik/traefik.yml`:
```yaml
entryPoints:
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${TRAEFIK_ACME_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

**4. Vaultwarden Signups deaktivieren**

Nach Erstanmeldung in `.env` ändern:
```bash
VAULTWARDEN_SIGNUPS_ALLOWED=false
```

Container neu starten:
```bash
docker compose -f docker-compose.yml restart vaultwarden
```

---

## 📚 Nützliche Befehle

```bash
# Alle Container anzeigen
docker ps -a

# Container-Ressourcen
docker stats

# Speicherplatz
docker system df

# Logs verfolgen
docker compose logs -f --tail=100

# Container-Shell
docker exec -it <container-name> sh

# Alle gestoppten Container löschen
docker container prune

# Alle ungenutzten Images löschen
docker image prune -a

# Komplette Bereinigung (VORSICHT!)
docker system prune -a --volumes
```

---

## 🆘 Support & Hilfe

### Quick-Diagnose

```bash
cd /opt/homeserver
bash quick-start.sh
```

### Vollständige Dokumentation

- `INSTALLATION.md` - Diese Datei
- `FIXES_APPLIED.md` - Durchgeführte Korrekturen
- `docs/` - Erweiterte Dokumentation
- `README.md` - Projekt-Übersicht

### Logs sammeln

```bash
# Alle Logs in Datei speichern
cd /opt/homeserver/docker-compose
docker compose -f docker-compose.yml logs > /tmp/homeserver-logs.txt
```

---

## ✅ Checkliste

Nach Installation:

- [ ] Docker installiert und läuft
- [ ] Projekt nach `/opt/homeserver` kopiert
- [ ] `.env` erstellt und angepasst
- [ ] Alle Passwörter geändert
- [ ] Docker-Netzwerke erstellt
- [ ] Firewall konfiguriert
- [ ] Services gestartet
- [ ] Hosts-Datei konfiguriert
- [ ] Services erreichbar
- [ ] Portainer Admin-Account erstellt
- [ ] Gitea eingerichtet
- [ ] Grafana konfiguriert
- [ ] Vaultwarden Account erstellt
- [ ] Backup-Strategie implementiert

---

**🎉 Viel Erfolg mit Ihrem Homeserver!**

Bei Problemen: `docker compose logs -f` ist Ihr bester Freund! 🐛
