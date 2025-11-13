# ⚡ HOMESERVER QUICK-START GUIDE
**Für erfahrene Benutzer - 15 Minuten Setup**

---

## 🎯 VORAUSSETZUNGEN

- Ubuntu 24.04 LTS Server (frisch installiert)
- Root/sudo Zugriff
- 8+ GB RAM, 100+ GB Speicher
- Feste IP (z.B. 192.168.1.100)

---

## 🚀 INSTALLATION (5 Befehle)

```bash
# 1. Projekt klonen
cd /opt
sudo git clone https://github.com/YOUR-REPO/homeserver-quickstart.git homeserver-setup
sudo chown -R $USER:$USER homeserver-setup
cd homeserver-setup

# 2. Secrets generieren
./scripts/00-generate-secrets.sh
# ⚠️ PASSWÖRTER NOTIEREN! ⚠️

# 3. .env anpassen
nano .env
# SERVER_IP, MAIL_PRIMARY_DOMAIN, TRAEFIK_ACME_EMAIL ändern

# 4. Installation starten
sudo ./install-homeserver.sh
# ⏱️ Dauer: ~10 Minuten

# 5. Status prüfen
docker ps
```

---

## 🖥️ CLIENT-SETUP (Windows)

```powershell
# Hosts-Datei (als Admin)
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 home.homeserver.local"
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 traefik.homeserver.local"
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 portainer.homeserver.local"
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 gitea.homeserver.local"
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 grafana.homeserver.local"

# Oder Script verwenden:
cd Homeserver\homeserver-quickstart\windows-tools
.\update-hosts.ps1 -ServerIP "192.168.1.100"
```

---

## 🔑 WICHTIGE ZUGANGSDATEN

**Aus .env / bei Secret-Generierung notiert:**

| Service | URL | User | Passwort |
|---------|-----|------|----------|
| Homepage | http://home.homeserver.local | - | - |
| Traefik | http://traefik.homeserver.local | admin | `TRAEFIK_DASHBOARD_AUTH` (generiert) |
| Portainer | http://portainer.homeserver.local | admin | `ADMIN_UI_PASSWORD` (generiert) |
| Gitea | http://gitea.homeserver.local | admin | Bei Ersteinrichtung setzen |
| Grafana | http://grafana.homeserver.local | admin | `GRAFANA_ADMIN_PASSWORD` |
| Adminer | http://db.homeserver.local | admin | `ADMIN_UI_PASSWORD` |

**Basic Auth (für Portainer, Adminer, Grafana, etc.):**
- User: `admin`
- Pass: Wurde bei `00-generate-secrets.sh` ausgegeben

---

## ⚙️ ERSTKONFIGURATION

### Gitea Setup

```bash
# URL: http://gitea.homeserver.local
# DB-Typ: PostgreSQL
# Host: postgres:5432
# DB: homeserver
# User: admin
# Pass: $POSTGRES_PASSWORD (aus .env)
```

### Drone CI (Optional)

```bash
# 1. OAuth in Gitea erstellen
# Gitea → Settings → Applications → New OAuth2 Application
# Name: Drone CI
# Redirect: http://drone.homeserver.local/login

# 2. .env ergänzen
nano /opt/homeserver/.env
# GITEA_OAUTH_CLIENT_ID=...
# GITEA_OAUTH_CLIENT_SECRET=...

# 3. Drone neu starten
docker compose restart drone-server drone-runner
```

---

## 📊 SERVICE-URLS (Top 10)

```
http://home.homeserver.local        # Homepage Dashboard
http://portainer.homeserver.local   # Container Management
http://gitea.homeserver.local       # Git Server
http://code.homeserver.local        # VS Code Web
http://grafana.homeserver.local     # Monitoring
http://db.homeserver.local          # Adminer (DB UI)
http://traefik.homeserver.local     # Traefik Dashboard
http://registry.homeserver.local    # Docker Registry
http://vault.homeserver.local       # Vaultwarden
http://netdata.homeserver.local     # System Monitoring
```

---

## 🔧 WICHTIGE BEFEHLE

### Docker

```bash
# Status
docker ps
docker compose ps

# Logs
docker logs -f <container>
docker compose logs -f

# Neu starten
docker restart <container>
docker compose restart

# Stoppen/Starten
docker compose down
docker compose up -d

# Updates
docker compose pull
docker compose up -d
```

### System

```bash
# Firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Speicher prüfen
df -h
docker system df

# Aufräumen
docker system prune -a
```

### Backup

```bash
# Manuelles Backup
cd /opt/homeserver
./scripts/backup.sh

# Snapshots anzeigen
export RESTIC_PASSWORD=$(grep RESTIC_PASSWORD .env | cut -d= -f2)
restic -r /backup snapshots

# Restore
./scripts/restore.sh
```

---

## 🐛 TROUBLESHOOTING CHEATSHEET

### Container startet nicht
```bash
docker logs <container>
docker inspect <container>
docker restart <container>
```

### Service nicht erreichbar
```bash
# 1. Hosts-Datei?
ping home.homeserver.local

# 2. Container läuft?
docker ps | grep <service>

# 3. Traefik-Routing?
docker logs traefik | grep <service>

# 4. Firewall?
sudo ufw status
```

### Datenbank-Probleme
```bash
# PostgreSQL
docker exec -it postgres psql -U admin -d homeserver

# MariaDB
docker exec -it mariadb mysql -u root -p

# Redis
docker exec -it redis redis-cli -a $REDIS_PASSWORD
```

### Passwort vergessen
```bash
# .env prüfen
grep PASSWORD /opt/homeserver/.env

# Gitea Admin-Passwort reset
docker exec -it gitea gitea admin user change-password -u admin -p NewPass123

# Grafana Admin-Passwort reset
docker exec -it grafana grafana-cli admin reset-admin-password NewPass123
```

---

## 🔐 SICHERHEIT CHECKLISTE

- [ ] Alle Passwörter aus .env in Passwort-Manager gespeichert
- [ ] SSH-Keys statt Passwörter verwenden
- [ ] Firewall aktiviert (`sudo ufw enable`)
- [ ] Backup getestet
- [ ] .env-Datei Rechte: `chmod 600 .env`
- [ ] Nicht benötigte Services deaktiviert
- [ ] Regelmäßige Updates: `sudo apt update && sudo apt upgrade`

---

## 📦 EIGENE SERVICES HINZUFÜGEN

```yaml
# custom-service.yml
version: '3.8'

services:
  my-app:
    image: nginx:latest
    container_name: my-app
    restart: unless-stopped
    networks:
      - homeserver_frontend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`app.homeserver.local`)"
      - "traefik.http.routers.my-app.entrypoints=web"
      - "traefik.http.services.my-app.loadbalancer.server.port=80"

networks:
  homeserver_frontend:
    external: true
```

```bash
# Starten
docker compose -f custom-service.yml up -d

# Hosts-Datei ergänzen
echo "192.168.1.100 app.homeserver.local" >> /etc/hosts  # Linux
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.100 app.homeserver.local"  # Windows
```

---

## 🎯 PERFORMANCE-TIPPS

### Memory Limits setzen

```yaml
# In docker-compose.yml
services:
  gitea:
    # ...
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### Log-Rotation

```json
# /etc/docker/daemon.json
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

### Docker Volumes auf SSD

```bash
# Docker-Root auf SSD verlegen
sudo systemctl stop docker
sudo mv /var/lib/docker /mnt/ssd/docker
sudo ln -s /mnt/ssd/docker /var/lib/docker
sudo systemctl start docker
```

---

## 🆘 NOTFALL-WIEDERHERSTELLUNG

### Kompletter System-Crash

```bash
# 1. Ubuntu neu installieren
# 2. Projekt klonen
cd /opt && git clone <repo> homeserver-setup

# 3. .env aus Backup wiederherstellen
cp /backup/.env /opt/homeserver-setup/

# 4. Daten wiederherstellen
./scripts/restore.sh

# 5. Services starten
sudo ./install-homeserver.sh
```

### Container korrupt

```bash
# Stoppen und löschen
docker stop <container>
docker rm <container>

# Image neu pullen
docker compose pull <service>

# Neu starten
docker compose up -d <service>
```

---

## 📊 MONITORING QUICK-CHECK

```bash
# System-Ressourcen
htop
docker stats

# Disk Space
df -h
du -sh /var/lib/docker/*

# Netzwerk
netstat -tuln
ss -tuln

# Logs
journalctl -u docker -f
docker compose logs -f --tail=100
```

---

## 🔄 UPDATE-STRATEGIE

### Auto-Updates (Watchtower)
```bash
# Standardmäßig aktiviert, täglich 3:00 Uhr
# Deaktivieren:
docker stop watchtower
docker rm watchtower
```

### Manuelle Updates
```bash
cd /opt/homeserver/docker-compose
docker compose pull
docker compose up -d

# Oder einzelner Service:
docker compose pull gitea
docker compose up -d gitea
```

### System-Updates
```bash
# Monatlich ausführen:
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo reboot  # Falls Kernel-Update
```

---

## 📖 WEITERFÜHRENDE DOCS

- **Vollständige Anleitung:** `SERVER_EINRICHTUNG_ANLEITUNG.md`
- **Konfiguration:** `docs/configuration.md`
- **Mail-Setup:** `docs/mail-setup.md`
- **Beispiele:** `examples/README.md`

---

## 🎉 DONE!

**Setup-Zeit:** ~15 Minuten  
**Services laufend:** ~25 Container  
**RAM-Nutzung:** ~4-6 GB  
**Disk-Nutzung:** ~10-20 GB (frisch installiert)

---

**Bei Problemen:**
1. Logs prüfen: `docker logs <service>`
2. Dokumentation: `SERVER_EINRICHTUNG_ANLEITUNG.md`
3. GitHub Issues: https://github.com/YOUR-REPO/issues

**Version:** 2.0  
**Letzte Aktualisierung:** 2025-11-13
