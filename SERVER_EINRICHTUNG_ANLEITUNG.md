# 🏠 HOMESERVER KOMPLETT-ANLEITUNG
**Vollständige Einrichtung & Konfiguration**

Version: 2.0  
Datum: 2025-11-13  
Zielgruppe: Einsteiger bis Fortgeschrittene

---

## 📋 INHALTSVERZEICHNIS

1. [Überblick](#überblick)
2. [Voraussetzungen](#voraussetzungen)
3. [Hardware-Empfehlungen](#hardware-empfehlungen)
4. [Installation Schritt-für-Schritt](#installation-schritt-für-schritt)
5. [Erstkonfiguration](#erstkonfiguration)
6. [Service-Übersicht](#service-übersicht)
7. [Zugriff auf Services](#zugriff-auf-services)
8. [Sicherheit](#sicherheit)
9. [Backup & Restore](#backup--restore)
10. [Wartung & Updates](#wartung--updates)
11. [Troubleshooting](#troubleshooting)
12. [FAQ](#faq)

---

## 🎯 ÜBERBLICK

### Was ist der Homeserver?

Der Homeserver ist eine All-in-One Lösung für:
- ✅ Entwicklungsumgebung (Gitea, Drone CI, Code-Server)
- ✅ Datenbank-Management (PostgreSQL, MariaDB, Redis)
- ✅ Container-Verwaltung (Portainer, Docker Registry)
- ✅ Monitoring (Grafana, Prometheus, Netdata)
- ✅ Mail-Server (Mailu mit API)
- ✅ Passwort-Manager (Vaultwarden)
- ✅ Reverse Proxy (Traefik mit HTTPS)
- ✅ Dashboard (Homepage)
- ✅ Automatische Backups (Restic)

### Architektur

```
Internet
   ↓
Traefik (Reverse Proxy) → HTTPS/TLS
   ↓
┌─────────────────────────────────────────┐
│  Frontend Network                       │
│  ├── Homepage Dashboard                 │
│  ├── Gitea (Git Server)                 │
│  ├── Portainer (Container Management)   │
│  ├── Grafana (Monitoring)               │
│  └── ...                                 │
└─────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────┐
│  Backend Network                        │
│  ├── PostgreSQL                         │
│  ├── MariaDB                            │
│  ├── Redis                              │
│  └── Docker Registry                    │
└─────────────────────────────────────────┘
```

---

## 📦 VORAUSSETZUNGEN

### Software (wird automatisch installiert)
- Ubuntu 24.04 LTS Server
- Docker Engine 27.x
- Docker Compose v2.x
- Git
- htpasswd (apache2-utils)

### Benötigte Kenntnisse
- ⭐ **Minimal:** Linux Grundkenntnisse, Umgang mit Terminal
- ⭐⭐ **Empfohlen:** Docker Basics, Netzwerk-Grundlagen
- ⭐⭐⭐ **Optional:** Git, CI/CD, Reverse Proxies

### Netzwerk-Voraussetzungen
- Feste IP-Adresse im lokalen Netzwerk (z.B. 192.168.1.100)
- Zugriff auf Router für Port-Weiterleitung (optional, für externe Erreichbarkeit)
- DNS/Hosts-Datei Zugriff für lokale Domains

---

## 💻 HARDWARE-EMPFEHLUNGEN

### Minimum (Basis-Setup)
- **CPU:** 4 Kerne (z.B. Intel i3, AMD Ryzen 3)
- **RAM:** 8 GB
- **Speicher:** 
  - System: 64 GB SSD
  - Daten: 500 GB HDD
- **Netzwerk:** 1 Gbit Ethernet

**Geeignet für:** Persönliche Nutzung, 1-2 Nutzer, Entwicklung

---

### Empfohlen (Standard-Setup)
- **CPU:** 6-8 Kerne (z.B. Intel i5/i7, AMD Ryzen 5/7)
- **RAM:** 16-32 GB
- **Speicher:**
  - System: 256 GB NVMe SSD
  - Daten: 2 TB HDD/SSD
  - Backup: Externes USB-Laufwerk 2+ TB
- **Netzwerk:** 1-2.5 Gbit Ethernet

**Geeignet für:** Kleine Teams, mehrere Nutzer, CI/CD

---

### High-End (Production-Ready)
- **CPU:** 8+ Kerne (z.B. Intel Xeon, AMD EPYC)
- **RAM:** 64+ GB ECC
- **Speicher:**
  - System: 512 GB NVMe SSD (RAID 1)
  - Daten: 4+ TB SSD (RAID 10)
  - Backup: NAS mit RAID
- **Netzwerk:** 10 Gbit Ethernet, redundant
- **USV:** APC/Eaton USV für sauberes Herunterfahren

**Geeignet für:** Firmen, viele Nutzer, kritische Services

---

## 🚀 INSTALLATION SCHRITT-FÜR-SCHRITT

### Methode 1: Automatische Installation (Empfohlen)

#### Schritt 1: Ubuntu Server installieren

1. **USB-Stick erstellen:**
   ```powershell
   # Auf Windows:
   cd Homeserver/homeserver-quickstart/windows-tools
   .\create-usb.ps1
   ```

2. **Ubuntu Server 24.04 LTS herunterladen:**
   - https://ubuntu.com/download/server
   - ISO-Datei auf USB schreiben (Rufus, balenaEtcher)

3. **Server booten und installieren:**
   - Boot-Reihenfolge im BIOS anpassen (USB first)
   - Sprache: Deutsch / English
   - Tastatur-Layout auswählen
   - Netzwerk: DHCP oder manuelle IP (z.B. 192.168.1.100)
   - Festplatte: "Use an entire disk" (ACHTUNG: Alle Daten werden gelöscht!)
   - Profil erstellen:
     - Name: homeserver
     - Server-Name: homeserver
     - Benutzername: admin
     - Passwort: [SICHERES PASSWORT WÄHLEN]
   - SSH Server installieren: [X] Install OpenSSH server
   - Featured Server Snaps: Nichts auswählen
   - Installation abschließen und neu starten

---

#### Schritt 2: Erstzugriff via SSH

```bash
# Von deinem PC aus:
ssh admin@192.168.1.100

# Beim ersten Mal:
# - Fingerprint bestätigen (yes)
# - Passwort eingeben
```

---

#### Schritt 3: System aktualisieren

```bash
# Pakete aktualisieren
sudo apt update
sudo apt upgrade -y

# Optional: Neustart falls Kernel-Update
sudo reboot
```

---

#### Schritt 4: Homeserver-Projekt klonen

```bash
# Git installieren (falls nicht vorhanden)
sudo apt install -y git

# Projekt klonen
cd /opt
sudo git clone https://github.com/YOUR-USERNAME/homeserver-quickstart.git homeserver-setup

# Oder: Download als ZIP und extrahieren
sudo wget https://github.com/YOUR-USERNAME/homeserver-quickstart/archive/main.zip
sudo unzip main.zip
sudo mv homeserver-quickstart-main homeserver-setup

# Berechtigungen setzen
sudo chown -R $USER:$USER /opt/homeserver-setup
cd /opt/homeserver-setup
```

---

#### Schritt 5: Secrets generieren

```bash
# Secrets-Script ausführen
cd /opt/homeserver-setup
./scripts/00-generate-secrets.sh

# WICHTIG: Alle generierten Passwörter notieren!
# Diese werden benötigt für:
# - Datenbank-Zugriff
# - Admin-Dashboards
# - Mail-Server
# - Backups
```

**📋 Passwörter sicher aufbewahren:**
- In Passwort-Manager speichern (z.B. Bitwarden, KeePass)
- NICHT in Cloud-Speicher ohne Verschlüsselung!
- Physisches Backup an sicherem Ort

---

#### Schritt 6: Umgebungsvariablen anpassen

```bash
# .env Datei bearbeiten
nano .env

# WICHTIGE Einstellungen anpassen:
# 1. SERVER_IP (z.B. 192.168.1.100)
# 2. MAIL_PRIMARY_DOMAIN (z.B. homeserver.local oder deine Domain)
# 3. TRAEFIK_ACME_EMAIL (deine E-Mail für Let's Encrypt)
# 4. SMTP_* (wenn E-Mail-Benachrichtigungen gewünscht)

# Speichern: Strg+O, Enter, Strg+X
```

---

#### Schritt 7: Installation ausführen

```bash
# Installations-Script starten
sudo ./install-homeserver.sh

# Das Script führt automatisch aus:
# [1/10] Docker Installation
# [2/10] Docker Compose Installation
# [3/10] Projekt-Verzeichnis erstellen (/opt/homeserver)
# [4/10] Dateien kopieren
# [5/10] Umgebungsvariablen konfigurieren
# [6/10] Datenbank-Konfigurationen erstellen
# [7/10] Redis-Konfiguration generieren
# [8/10] Firewall konfigurieren
# [9/10] Docker Services starten
# [10/10] Gesundheitschecks

# Dauer: ca. 10-15 Minuten
```

---

#### Schritt 8: Installation überprüfen

```bash
# Docker Status prüfen
docker ps

# Sollte ~25 Container anzeigen:
# - traefik
# - portainer
# - postgres
# - mariadb
# - redis
# - gitea
# - ...

# Service-Logs prüfen
docker compose -f /opt/homeserver/docker-compose/docker-compose.yml logs -f traefik

# Strg+C zum Beenden
```

---

### Methode 2: Manuelle Installation

<details>
<summary>Klicken für detaillierte manuelle Schritte</summary>

#### 1. Docker manuell installieren

```bash
# Alte Versionen entfernen
sudo apt remove docker docker-engine docker.io containerd runc

# Abhängigkeiten installieren
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker GPG Key hinzufügen
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Repository hinzufügen
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker installieren
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Benutzer zur docker-Gruppe hinzufügen
sudo usermod -aG docker $USER

# Abmelden und wieder anmelden für Gruppenrechte
exit
# SSH neu verbinden
```

#### 2. Services manuell starten

```bash
cd /opt/homeserver/docker-compose

# Haupt-Services starten
docker compose up -d

# Monitoring starten
docker compose -f docker-compose.monitoring.yml up -d

# MCP Services starten (optional)
docker compose -f docker-compose.mcp.yml up -d
```

</details>

---

## ⚙️ ERSTKONFIGURATION

### 1. Hosts-Datei konfigurieren

Für lokalen Zugriff auf Services müssen die Hostnamen aufgelöst werden.

#### Auf Windows:

```powershell
# Als Administrator PowerShell öffnen
cd C:\Windows\System32\drivers\etc

# hosts Datei bearbeiten
notepad hosts

# Folgende Zeilen am Ende hinzufügen (IP anpassen!):
192.168.1.100 home.homeserver.local
192.168.1.100 traefik.homeserver.local
192.168.1.100 portainer.homeserver.local
192.168.1.100 git.homeserver.local
192.168.1.100 drone.homeserver.local
192.168.1.100 code.homeserver.local
192.168.1.100 db.homeserver.local
192.168.1.100 redis.homeserver.local
192.168.1.100 registry.homeserver.local
192.168.1.100 registry-ui.homeserver.local
192.168.1.100 grafana.homeserver.local
192.168.1.100 prometheus.homeserver.local
192.168.1.100 netdata.homeserver.local
192.168.1.100 vault.homeserver.local
192.168.1.100 mail-api.homeserver.local

# Speichern und schließen
```

**Oder automatisch mit Script:**
```powershell
cd Homeserver\homeserver-quickstart\windows-tools
.\update-hosts.ps1 -ServerIP "192.168.1.100"
```

#### Auf Linux/Mac:

```bash
# /etc/hosts bearbeiten
sudo nano /etc/hosts

# Gleiche Zeilen wie bei Windows hinzufügen
# Speichern: Strg+O, Enter, Strg+X
```

---

### 2. Dashboard öffnen

```
http://home.homeserver.local
```

Das Homepage-Dashboard zeigt alle Services auf einen Blick.

---

### 3. Gitea einrichten (Git-Server)

1. **Gitea öffnen:** http://git.homeserver.local

2. **Erstinstallation:**
   - Datenbank-Typ: PostgreSQL
   - Host: postgres:5432
   - Benutzername: admin
   - Passwort: [POSTGRES_PASSWORD aus .env]
   - Datenbankname: homeserver
   - Server-Domäne: git.homeserver.local
   - Gitea-Basis-URL: http://git.homeserver.local
   - Administrator-Konto erstellen:
     - Benutzername: admin
     - E-Mail: admin@homeserver.local
     - Passwort: [SICHERES PASSWORT]

3. **Registrierung klicken**

---

### 4. Drone CI einrichten (Optional)

1. **Gitea OAuth erstellen:**
   - Gitea → Einstellungen → Anwendungen
   - Neue OAuth2-Anwendung
   - Name: Drone CI
   - Redirect URI: http://drone.homeserver.local/login
   - Client ID und Client Secret kopieren

2. **.env aktualisieren:**
   ```bash
   cd /opt/homeserver
   nano .env
   
   # Eintragen:
   GITEA_OAUTH_CLIENT_ID=<client-id>
   GITEA_OAUTH_CLIENT_SECRET=<client-secret>
   
   # Speichern
   ```

3. **Drone neu starten:**
   ```bash
   cd /opt/homeserver/docker-compose
   docker compose restart drone-server drone-runner
   ```

4. **Drone öffnen:** http://drone.homeserver.local
   - Mit Gitea-Account anmelden

---

### 5. Portainer einrichten

1. **Portainer öffnen:** http://portainer.homeserver.local

2. **Basic Auth eingeben:**
   - Benutzername: admin
   - Passwort: [ADMIN_UI_PASSWORD aus .env - wurde beim Generieren angezeigt]

3. **Admin-Passwort erstellen:**
   - Neues Portainer-Passwort wählen (mind. 12 Zeichen)

4. **Environment auswählen:**
   - "Get Started" klicken
   - "local" Environment ist bereits verbunden

---

### 6. Grafana einrichten

1. **Grafana öffnen:** http://grafana.homeserver.local

2. **Basic Auth:**
   - Benutzername: admin
   - Passwort: [ADMIN_UI_PASSWORD]

3. **Grafana Login:**
   - Benutzername: admin
   - Passwort: [GRAFANA_ADMIN_PASSWORD aus .env]

4. **Dashboard importieren:**
   - Dashboards → Import
   - Dashboard ID eingeben:
     - Docker Monitoring: 893
     - Node Exporter: 1860
   - Prometheus Data Source auswählen
   - Import klicken

---

## 📊 SERVICE-ÜBERSICHT

### Core Services (Immer laufend)

| Service | Beschreibung | URL | Port (intern) |
|---------|--------------|-----|---------------|
| **Traefik** | Reverse Proxy & Load Balancer | http://traefik.homeserver.local | 80, 443 |
| **Homepage** | Service Dashboard | http://home.homeserver.local | 3000 |
| **Portainer** | Docker Container Management | http://portainer.homeserver.local | 9000 |

### Datenbanken

| Service | Beschreibung | URL | Port |
|---------|--------------|-----|------|
| **PostgreSQL** | Relationale Datenbank | db.homeserver.local | 5432 |
| **MariaDB** | MySQL-kompatible Datenbank | - | 3306 |
| **Redis** | In-Memory Cache/DB | redis.homeserver.local | 6379 |
| **Adminer** | Datenbank Web-UI | http://db.homeserver.local | 8080 |
| **Redis Commander** | Redis Web-UI | http://redis.homeserver.local | 8081 |

### Entwicklung

| Service | Beschreibung | URL |
|---------|--------------|-----|
| **Gitea** | Git-Server (GitHub-Alternative) | http://git.homeserver.local |
| **Drone** | CI/CD Pipeline | http://drone.homeserver.local |
| **Code-Server** | VS Code im Browser | http://code.homeserver.local |
| **Docker Registry** | Private Container Registry | http://registry.homeserver.local |
| **Registry UI** | Registry Browser | http://registry-ui.homeserver.local |

### Monitoring

| Service | Beschreibung | URL |
|---------|--------------|-----|
| **Grafana** | Visualisierung & Dashboards | http://grafana.homeserver.local |
| **Prometheus** | Metriken-Sammlung | http://prometheus.homeserver.local |
| **Netdata** | Echtzeit-Monitoring | http://netdata.homeserver.local |

### Sicherheit & Tools

| Service | Beschreibung | URL |
|---------|--------------|-----|
| **Vaultwarden** | Passwort-Manager (Bitwarden) | http://vault.homeserver.local |
| **Watchtower** | Automatische Container-Updates | - |
| **Restic** | Backup-Lösung | CLI |

### Optional (MCP Services)

| Service | Beschreibung | URL |
|---------|--------------|-----|
| **MCP Dashboard** | MCP Service Übersicht | http://mcp-dashboard.homeserver.local |
| **MCP Database** | Datenbank-Zugriff via MCP | http://mcp-db.homeserver.local |
| **MCP Docker** | Docker-Management via MCP | http://mcp-docker.homeserver.local |
| **MCP Filesystem** | Dateisystem-Zugriff | http://mcp-fs.homeserver.local |
| **MCP HTTP** | HTTP Client Service | http://mcp-http.homeserver.local |

---

## 🔐 SICHERHEIT

### Passwort-Richtlinien

✅ **Mindestanforderungen:**
- Länge: Mind. 16 Zeichen
- Komplexität: Groß-/Kleinbuchstaben, Zahlen, Sonderzeichen
- Einzigartigkeit: Für jeden Service ein anderes Passwort

✅ **Empfohlene Tools:**
- Passwort-Generator: `openssl rand -base64 24`
- Passwort-Manager: Vaultwarden (im Homeserver integriert)

---

### Firewall-Regeln

Die Installation konfiguriert UFW automatisch:

```bash
# Firewall-Status prüfen
sudo ufw status

# Erlaubte Ports:
# 22/tcp    - SSH
# 80/tcp    - HTTP (Traefik)
# 443/tcp   - HTTPS (Traefik)
```

**Zusätzliche Ports öffnen (nur bei Bedarf):**
```bash
# Beispiel: Port 8080 für spezielle App
sudo ufw allow 8080/tcp
```

---

### SSH-Absicherung

```bash
# SSH-Config bearbeiten
sudo nano /etc/ssh/sshd_config

# Empfohlene Einstellungen:
PermitRootLogin no
PasswordAuthentication yes  # Auf 'no' setzen wenn SSH-Keys verwendet werden
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# SSH neu starten
sudo systemctl restart sshd
```

**SSH-Keys einrichten (empfohlen):**
```bash
# Auf Client (Windows PowerShell):
ssh-keygen -t ed25519 -C "homeserver-key"
# Public Key auf Server kopieren:
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh admin@192.168.1.100 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Auf Server: Password Auth deaktivieren
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
sudo systemctl restart sshd
```

---

### Netzwerk-Isolation

Die Docker-Netzwerke sind isoliert:

- **homeserver_frontend:** Öffentlich erreichbare Services (via Traefik)
- **homeserver_backend:** Nur intern erreichbar (Datenbanken)

Services ohne Traefik-Labels sind NUR aus dem internen Netzwerk erreichbar.

---

### TLS/HTTPS (Optional für Produktiv-Umgebung)

**Für interne Nutzung (.local Domains):**
- HTTP ist ausreichend (keine Daten verlassen das lokale Netz)

**Für externe Erreichbarkeit:**

1. **Domain registrieren** (z.B. bei Cloudflare, Namecheap)

2. **DNS konfigurieren:**
   ```
   A Record: homeserver.example.com → [Öffentliche IP]
   A Record: *.homeserver.example.com → [Öffentliche IP]
   ```

3. **Port-Weiterleitung im Router:**
   - Port 80 → 192.168.1.100:80
   - Port 443 → 192.168.1.100:443

4. **.env anpassen:**
   ```bash
   # Domains auf echte Domain ändern
   MAIL_PRIMARY_DOMAIN=homeserver.example.com
   TRAEFIK_ACME_EMAIL=admin@example.com
   ```

5. **Traefik neu starten:**
   ```bash
   docker compose restart traefik
   ```

Let's Encrypt wird automatisch Zertifikate ausstellen.

---

## 💾 BACKUP & RESTORE

### Automatische Backups (Restic)

Backups laufen automatisch täglich um 2:00 Uhr.

**Backup-Verzeichnis prüfen:**
```bash
# Backup-Script anzeigen
cat /opt/homeserver/scripts/backup.sh

# Manuelles Backup ausführen
cd /opt/homeserver
./scripts/backup.sh

# Backup-Status prüfen
# Passwort aus .env holen
grep RESTIC_PASSWORD .env

# Repository prüfen
export RESTIC_PASSWORD=<passwort>
restic -r /backup snapshots
```

**Backup-Speicherorte:**
- Lokal: `/backup` (Docker Volume)
- Optional: Externes USB-Laufwerk einbinden
- Optional: Cloud-Storage (AWS S3, Backblaze B2)

---

### Externes Backup konfigurieren

```bash
# USB-Laufwerk einbinden
sudo mkdir -p /mnt/backup
sudo mount /dev/sdb1 /mnt/backup

# Backup-Script anpassen
nano /opt/homeserver/scripts/backup.sh

# BACKUP_DIR ändern:
BACKUP_DIR="/mnt/backup/homeserver-restic"

# Auto-Mount bei Boot (optional)
sudo nano /etc/fstab
# Zeile hinzufügen:
/dev/sdb1 /mnt/backup ext4 defaults 0 2
```

---

### Restore (Wiederherstellung)

```bash
# Alle Snapshots anzeigen
export RESTIC_PASSWORD=<passwort>
restic -r /backup snapshots

# Snapshot wiederherstellen
restic -r /backup restore latest --target /opt/homeserver-restore

# Oder spezifischen Snapshot:
restic -r /backup restore abc123de --target /opt/homeserver-restore

# Dateien zurückkopieren
sudo cp -r /opt/homeserver-restore/* /opt/homeserver/
```

**Oder mit Script:**
```bash
cd /opt/homeserver
./scripts/restore.sh
```

---

## 🔄 WARTUNG & UPDATES

### Container-Updates (automatisch)

Watchtower aktualisiert Container automatisch (täglich um 3:00 Uhr).

**Manuelles Update:**
```bash
cd /opt/homeserver/docker-compose
docker compose pull
docker compose up -d
```

---

### System-Updates

```bash
# Pakete aktualisieren
sudo apt update
sudo apt upgrade -y

# Optional: Neustart nach Kernel-Update
sudo reboot
```

---

### Docker-Aufräumen

```bash
# Unbenutzte Container/Images/Volumes entfernen
docker system prune -a --volumes

# ACHTUNG: Löscht auch gestoppte Container und unbenutzte Volumes!
```

---

### Logs verwalten

```bash
# Log-Größe prüfen
docker system df

# Logs eines Services anzeigen
docker logs traefik
docker logs --tail 100 -f gitea  # Live-Logs

# Log-Rotation konfigurieren
sudo nano /etc/docker/daemon.json
```

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
# Docker neu starten
sudo systemctl restart docker
```

---

## 🔧 TROUBLESHOOTING

### Container startet nicht

```bash
# Status prüfen
docker ps -a

# Logs anzeigen
docker logs <container-name>

# Container neu starten
docker restart <container-name>

# Container-Details prüfen
docker inspect <container-name>
```

---

### Service nicht erreichbar

**1. Container läuft?**
```bash
docker ps | grep <service-name>
```

**2. Traefik-Logs prüfen:**
```bash
docker logs traefik | grep <service-name>
```

**3. Hosts-Datei korrekt?**
```bash
# Windows:
ping home.homeserver.local
# Sollte 192.168.1.100 auflösen

# Linux/Server:
nslookup home.homeserver.local
```

**4. Firewall blockiert?**
```bash
sudo ufw status
# Port 80/443 sollten erlaubt sein
```

**5. Docker-Netzwerk prüfen:**
```bash
docker network ls
docker network inspect homeserver_frontend
```

---

### Datenbank-Verbindung fehlgeschlagen

**PostgreSQL:**
```bash
# Container-Logs prüfen
docker logs postgres

# Interaktiv verbinden
docker exec -it postgres psql -U admin -d homeserver

# Passwort aus .env holen
grep POSTGRES_PASSWORD /opt/homeserver/.env
```

**MariaDB:**
```bash
# Logs prüfen
docker logs mariadb

# Interaktiv verbinden
docker exec -it mariadb mysql -u root -p
# Passwort aus .env: MYSQL_ROOT_PASSWORD
```

**Redis:**
```bash
# Logs prüfen
docker logs redis

# Redis-CLI
docker exec -it redis redis-cli -a $(grep REDIS_PASSWORD /opt/homeserver/.env | cut -d= -f2)
# Testen:
> PING
PONG
```

---

### Traefik-Dashboard leer / keine Services

**1. Labels prüfen:**
```bash
docker inspect gitea | grep traefik
# Sollte Labels anzeigen
```

**2. Traefik-Config prüfen:**
```bash
cat /opt/homeserver/configs/traefik/traefik.yml
# api.dashboard sollte true sein
```

**3. Middleware-Fehler:**
```bash
docker logs traefik | grep middleware
# Fehler bei admin-auth?
```

**Fix: .env ADMIN_UI_AUTH prüfen**
```bash
grep ADMIN_UI_AUTH /opt/homeserver/.env
# Sollte htpasswd-Hash enthalten, nicht "CHANGE_ME"
```

---

### Backup schlägt fehl

**1. Restic-Passwort korrekt?**
```bash
grep RESTIC_PASSWORD /opt/homeserver/.env
# Sollte gesetzt sein
```

**2. Backup-Verzeichnis existiert?**
```bash
ls -la /backup
# Sollte Verzeichnis/Volume sein
```

**3. Manueller Test:**
```bash
export RESTIC_PASSWORD=$(grep RESTIC_PASSWORD /opt/homeserver/.env | cut -d= -f2)
restic -r /backup check
```

**4. Repository neu initialisieren (ACHTUNG: Löscht alte Backups!):**
```bash
restic -r /backup init
```

---

### Festplatte voll

```bash
# Speicherplatz prüfen
df -h

# Größte Verzeichnisse finden
du -sh /opt/homeserver/* | sort -h

# Docker-Volumes prüfen
docker system df

# Aufräumen
docker system prune -a --volumes  # VORSICHT!

# Logs rotieren (siehe Wartung)
```

---

### Passwort vergessen

**Portainer:**
- Container neu starten löscht Admin-Account
- Neuen Account erstellen bei erneutem Zugriff

**Gitea:**
```bash
# CLI in Container
docker exec -it gitea gitea admin user change-password -u admin -p NewPassword123
```

**Grafana:**
```bash
# Admin-Passwort zurücksetzen
docker exec -it grafana grafana-cli admin reset-admin-password NewPassword123
```

**Datenbanken:**
- Siehe .env Datei für Root-Passwörter

---

## ❓ FAQ

### Kann ich den Homeserver auf Windows betreiben?

**Ja, mit Docker Desktop:**
- Docker Desktop für Windows installieren
- WSL2 Backend aktivieren
- Git Bash oder PowerShell verwenden
- Performance ist etwas schlechter als nativer Linux-Server

**Besser:** Dedizierter Linux-Server oder VM

---

### Wie viel Strom verbraucht der Homeserver?

**Abhängig von Hardware:**
- **Raspberry Pi 4:** ~5-10W (15€/Jahr)
- **Mini-PC (Intel NUC):** ~20-40W (50€/Jahr)
- **Standard-PC (i5/Ryzen 5):** ~50-100W (120€/Jahr)
- **Server (Xeon/EPYC):** ~150-300W (350€/Jahr)

*Strompreis: 0,30€/kWh angenommen*

---

### Kann ich eigene Services hinzufügen?

**Ja!** Siehe `examples/docker-compose/custom-service.yml`

Beispiel: Nextcloud hinzufügen
```yaml
services:
  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    restart: unless-stopped
    networks:
      - homeserver_frontend
      - homeserver_backend
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=nextcloud
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - nextcloud_data:/var/www/html
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nextcloud.rule=Host(`cloud.homeserver.local`)"
      - "traefik.http.routers.nextcloud.entrypoints=web"
      - "traefik.http.services.nextcloud.loadbalancer.server.port=80"

volumes:
  nextcloud_data:
```

Dann in docker-compose Verzeichnis speichern und starten:
```bash
docker compose -f docker-compose.nextcloud.yml up -d
```

---

### Wie viele Benutzer unterstützt der Homeserver?

**Abhängig von Hardware und Nutzung:**
- **Minimum-Setup (8GB RAM):** 1-3 Benutzer
- **Standard-Setup (16-32GB):** 5-15 Benutzer
- **High-End (64GB+):** 20-50+ Benutzer

**Limitierende Faktoren:**
- Gleichzeitige CI/CD Pipelines
- Datenbank-Last
- Container-Anzahl

---

### Gibt es ein Web-Interface für die Verwaltung?

**Ja, mehrere:**
- **Homepage Dashboard:** Übersicht aller Services
- **Portainer:** Container-Verwaltung (empfohlen)
- **Adminer:** Datenbank-Verwaltung
- **Traefik Dashboard:** Reverse-Proxy Status
- **Netdata:** System-Monitoring

---

### Kann ich den Homeserver von außen erreichen?

**Ja, mit Vorsicht:**

1. **VPN einrichten (empfohlen):**
   - WireGuard installieren
   - Nur VPN-Port nach außen öffnen (51820)
   - Sicherer als direkte Exposition

2. **Direkte Exposition (nur mit HTTPS!):**
   - Domain registrieren
   - Let's Encrypt aktivieren (siehe Sicherheit-Sektion)
   - DDoS-Schutz verwenden (z.B. Cloudflare)
   - Starke Passwörter + 2FA

---

## 📞 SUPPORT & COMMUNITY

### Hilfe bekommen

1. **Dokumentation:** Diese Anleitung + `/docs` Verzeichnis
2. **Logs prüfen:** `docker logs <service>`
3. **GitHub Issues:** Bugs/Feature-Requests melden
4. **Community:** Discord/Forum (falls vorhanden)

---

### Nützliche Ressourcen

- **Docker Docs:** https://docs.docker.com
- **Traefik Docs:** https://doc.traefik.io/traefik/
- **Gitea Docs:** https://docs.gitea.io
- **Drone Docs:** https://docs.drone.io

---

## 🎉 FERTIG!

**Glückwunsch!** Dein Homeserver ist einsatzbereit.

**Nächste Schritte:**
1. ✅ Alle Passwörter im Passwort-Manager speichern
2. ✅ Erste Backups testen
3. ✅ Erstes Git-Repository in Gitea erstellen
4. ✅ Monitoring-Dashboards erkunden
5. ✅ Eigene Services hinzufügen

---

**Version:** 2.0  
**Letztes Update:** 2025-11-13  
**Lizenz:** MIT  

Bei Fragen oder Problemen: GitHub Issues öffnen oder Community fragen.
