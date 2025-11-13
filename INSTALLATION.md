# 🚀 Homeserver Installation & Fehlerbehebung

## 📋 Voraussetzungen

### Erforderliche Software

```bash
# Docker & Docker Compose
docker --version  # >= 20.10
docker-compose --version  # >= 1.29

# Optional aber empfohlen
git --version
```

### Installation auf Ubuntu/Debian

```bash
# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Neuanmeldung erforderlich
newgrp docker

# Docker Compose installieren
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

## ⚡ Schnellstart

### 1. Umgebungsvariablen einrichten

```bash
cd /workspace/Homeserver/homeserver-quickstart

# .env-Datei erstellen
cp .env.example .env

# Secrets generieren (wenn Skript vorhanden)
bash scripts/00-generate-secrets.sh
```

### 2. .env-Datei anpassen

```bash
nano .env
```

**Wichtige Variablen:**
```bash
TZ=Europe/Berlin
SERVER_IP=192.168.1.100  # Ihre Server-IP

# Passwörter ändern (WICHTIG!)
POSTGRES_PASSWORD=SecurePassword123!
MYSQL_ROOT_PASSWORD=SecurePassword456!
REDIS_PASSWORD=SecurePassword789!
GRAFANA_ADMIN_PASSWORD=SecurePassword000!
VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -hex 32)

# Email für Let's Encrypt
TRAEFIK_ACME_EMAIL=ihre-email@example.com

# Gitea OAuth (später konfigurieren)
GITEA_OAUTH_CLIENT_ID=
GITEA_OAUTH_CLIENT_SECRET=
```

### 3. Docker-Netzwerke erstellen

```bash
docker network create frontend
docker network create backend
```

### 4. Services starten

```bash
cd docker-compose

# Schritt 1: Haupt-Services
docker-compose -f docker-compose.yml up -d

# Warten auf Initialisierung
sleep 30

# Schritt 2: Monitoring (optional)
docker-compose -f docker-compose.monitoring.yml up -d

# Schritt 3: MCP-Server (optional, nur wenn konfiguriert)
docker-compose -f docker-compose.mcp.yml up -d
```

### 5. Status überprüfen

```bash
# Alle Container anzeigen
docker ps

# Logs überwachen
docker-compose -f docker-compose.yml logs -f

# Spezifischen Service prüfen
docker logs traefik
docker logs postgres
```

---

## 🛠️ Fehlerbehebung

### Problem: Container starten nicht

**Diagnose:**
```bash
# Container-Status
docker ps -a

# Logs prüfen
docker-compose -f docker-compose.yml logs

# Spezifischen Container prüfen
docker logs <container-name>
```

**Lösung:**
```bash
# Container neu starten
docker-compose -f docker-compose.yml restart

# Bei persistenten Problemen: Neustart
docker-compose -f docker-compose.yml down
docker-compose -f docker-compose.yml up -d
```

---

### Problem: Port bereits belegt

**Fehler:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use
```

**Diagnose:**
```bash
# Welcher Prozess nutzt Port 80?
sudo lsof -i :80
sudo netstat -tulpn | grep :80
```

**Lösung:**
```bash
# Anderen Dienst stoppen
sudo systemctl stop nginx  # oder apache2

# Oder Port in docker-compose.yml ändern
# ports:
#   - "8080:80"  # statt "80:80"
```

---

### Problem: Netzwerke fehlen

**Fehler:**
```
network frontend declared as external, but could not be found
```

**Lösung:**
```bash
# Netzwerke manuell erstellen
docker network create frontend
docker network create backend

# Oder external: true in docker-compose.yml entfernen
```

---

### Problem: Datenbank-Verbindung fehlgeschlagen

**Fehler in Logs:**
```
could not connect to server: Connection refused
```

**Lösung:**
```bash
# Datenbank-Status prüfen
docker logs postgres
docker logs mariadb

# Health-Check
docker exec postgres pg_isready -U admin

# Neustart
docker-compose -f docker-compose.yml restart postgres mariadb
```

---

### Problem: Traefik Dashboard nicht erreichbar

**Lösung:**
```bash
# Traefik-Logs prüfen
docker logs traefik

# /etc/hosts anpassen
sudo bash -c 'echo "127.0.0.1 traefik.homeserver.local" >> /etc/hosts'

# Browser öffnen
http://traefik.homeserver.local:8080
```

---

### Problem: Services nicht erreichbar

**Lösung:**

1. **Hosts-Datei konfigurieren:**

```bash
# Linux/Mac: /etc/hosts
# Windows: C:\Windows\System32\drivers\etc\hosts

sudo nano /etc/hosts
```

**Einträge hinzufügen:**
```
192.168.1.100  home.homeserver.local
192.168.1.100  portainer.homeserver.local
192.168.1.100  traefik.homeserver.local
192.168.1.100  grafana.homeserver.local
192.168.1.100  prometheus.homeserver.local
192.168.1.100  netdata.homeserver.local
192.168.1.100  git.homeserver.local
192.168.1.100  vault.homeserver.local
192.168.1.100  db.homeserver.local
192.168.1.100  code.homeserver.local
192.168.1.100  www.homeserver.local
```

2. **Firewall prüfen:**

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp

# Firewalld (CentOS/Fedora)
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload
```

---

## 📊 Service-URLs

Nach erfolgreicher Installation sind folgende Services verfügbar:

| Service | URL | Beschreibung |
|---------|-----|--------------|
| **Homepage** | http://home.homeserver.local | Haupt-Dashboard |
| **Traefik** | http://traefik.homeserver.local:8080 | Reverse Proxy Dashboard |
| **Portainer** | http://portainer.homeserver.local | Docker Management |
| **Grafana** | http://grafana.homeserver.local | Monitoring & Visualisierung |
| **Prometheus** | http://prometheus.homeserver.local | Metriken-Sammlung |
| **Netdata** | http://netdata.homeserver.local | System-Monitoring |
| **Gitea** | http://git.homeserver.local | Git-Server |
| **Vaultwarden** | http://vault.homeserver.local | Passwort-Manager |
| **Adminer** | http://db.homeserver.local | Datenbank-UI |
| **Code-Server** | http://code.homeserver.local | VS Code im Browser |

---

## 🔧 Erweiterte Konfiguration

### Gitea OAuth für Drone

1. Gitea öffnen: http://git.homeserver.local
2. Einstellungen → Anwendungen → OAuth2-Anwendungen
3. Neue OAuth2-Anwendung erstellen:
   - **Name:** Drone CI
   - **Redirect URI:** http://drone.homeserver.local/login
4. Client-ID und Secret in `.env` eintragen:
   ```bash
   GITEA_OAUTH_CLIENT_ID=abc123...
   GITEA_OAUTH_CLIENT_SECRET=xyz789...
   ```
5. Container neu starten:
   ```bash
   docker-compose -f docker-compose.yml restart drone-server
   ```

---

### HTTPS mit Let's Encrypt

**traefik.yml anpassen:**
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${TRAEFIK_ACME_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

**docker-compose.yml Labels ergänzen:**
```yaml
labels:
  - "traefik.http.routers.portainer.tls=true"
  - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
```

---

## 🧪 Validierung

### YAML-Dateien prüfen

```bash
# Mit Python
pip install pyyaml
python3 -c "import yaml; yaml.safe_load(open('docker-compose/docker-compose.yml'))"

# Mit yamllint
yamllint docker-compose/docker-compose.yml
```

### Docker-Compose-Konfiguration testen

```bash
cd docker-compose
docker-compose -f docker-compose.yml config
```

### Alle Services prüfen

```bash
#!/bin/bash
SERVICES=(
  "http://home.homeserver.local"
  "http://traefik.homeserver.local:8080"
  "http://portainer.homeserver.local"
  "http://grafana.homeserver.local"
)

for url in "${SERVICES[@]}"; do
  echo -n "Testing $url ... "
  if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|401\|403"; then
    echo "✓ OK"
  else
    echo "✗ FEHLER"
  fi
done
```

---

## 🔄 Wartung

### Logs rotieren

```bash
# Docker-Logs begrenzen
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
sudo systemctl restart docker
```

### Backup

```bash
# Volumes sichern
docker run --rm \
  -v postgres_data:/source \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/postgres_$(date +%Y%m%d).tar.gz -C /source .

# Automatisches Backup (Cron)
0 2 * * * /opt/homeserver/scripts/backup.sh
```

### Updates

```bash
cd docker-compose

# Images aktualisieren
docker-compose -f docker-compose.yml pull

# Services neu starten
docker-compose -f docker-compose.yml up -d
```

---

## 📝 Checkliste

- [ ] Docker & Docker Compose installiert
- [ ] `.env` Datei erstellt und angepasst
- [ ] Passwörter geändert
- [ ] Docker-Netzwerke erstellt
- [ ] Services gestartet
- [ ] `/etc/hosts` konfiguriert
- [ ] Firewall-Ports geöffnet
- [ ] Services erreichbar
- [ ] Backup-Strategie implementiert

---

## 🆘 Support

Bei Problemen:

1. **Logs prüfen:**
   ```bash
   docker-compose logs -f
   ```

2. **Container neu starten:**
   ```bash
   docker-compose down && docker-compose up -d
   ```

3. **Vollständiger Neustart:**
   ```bash
   docker-compose down -v  # ⚠️ Löscht Daten!
   docker-compose up -d
   ```

4. **Konfiguration validieren:**
   ```bash
   docker-compose config
   ```

---

**Viel Erfolg mit Ihrem Homeserver! 🚀**
