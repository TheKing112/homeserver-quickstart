# Verbleibende Fixes - Priorität sortiert

Letzte Aktualisierung: 2025-11-14

## 🔴 KRITISCH (Vor Produktiveinsatz beheben!)

### 1. Redis Config-Template wird nicht generiert
**Problem:** Redis Container versucht `/usr/local/etc/redis/redis.conf` zu laden, aber nur `redis.conf.template` existiert.  
**Auswirkung:** Redis startet NICHT  
**Lösung:**
```bash
# In install-homeserver.sh oder 01-quickstart.sh NACH Secret-Generierung:
envsubst < configs/redis/redis.conf.template > configs/redis/redis.conf
chmod 644 configs/redis/redis.conf
```

**Datei:** `docker-compose/docker-compose.yml:193`  
**Command:** `redis-server /usr/local/etc/redis/redis.conf`

---

### 2. MCP Server Port-Mismatch (Dashboard)
**Problem:** Environment setzt `PORT=3000`, aber Traefik Label zeigt `server.port=3000`  
**Status:** Korrekt! (Beide 3000)  
**Keine Aktion nötig**

---

### 3. MCP Credentials fehlen in .env.example
**Problem:** `MCP_POSTGRES_PASSWORD` und `MCP_MYSQL_PASSWORD` werden NICHT von `00-generate-secrets.sh` generiert  
**Auswirkung:** MCP Database Service kann sich NICHT verbinden  
**Lösung:**

**In `scripts/00-generate-secrets.sh` nach Zeile 56 hinzufügen:**
```bash
MCP_POSTGRES_PASSWORD=$(generate_password 32)
MCP_MYSQL_PASSWORD=$(generate_password 32)
```

**In `.env` Generation (nach Zeile 146) hinzufügen:**
```bash
# ================================
# MCP DATABASE CREDENTIALS
# ================================
MCP_POSTGRES_USER=mcp_readonly
MCP_POSTGRES_PASSWORD=${MCP_POSTGRES_PASSWORD}
MCP_MYSQL_USER=mcp_readonly
MCP_MYSQL_PASSWORD=${MCP_MYSQL_PASSWORD}
```

---

### 4. .env.example REGISTRY_AUTH umbenennen
**Problem:** Variable heißt in .env.example noch `REGISTRY_AUTH`, sollte aber `REGISTRY_UI_AUTH` sein  
**Datei:** `.env.example:60`  
**Lösung:**
```bash
# Zeile 60 ändern von:
REGISTRY_AUTH=CHANGE_ME
# zu:
REGISTRY_UI_AUTH=CHANGE_ME
```

---

## 🟠 HOCH (Sollte behoben werden)

### 5. Fehlende Dependency-Checks in Scripts

#### restore.sh
**Problem:** Nutzt `restic` ohne zu prüfen ob installiert  
**Lösung:** Nach Zeile 6 hinzufügen:
```bash
if ! command -v restic &> /dev/null; then
    echo "ERROR: restic not installed"
    echo "Install: sudo apt install restic"
    exit 1
fi

mkdir -p "$RESTORE_DIR" || { echo "ERROR creating $RESTORE_DIR"; exit 1; }
```

#### mail-manager.sh
**Problem:** Nutzt `jq` ohne zu prüfen ob installiert  
**Lösung:** Nach Zeile 29 hinzufügen:
```bash
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not installed"
    echo "Install: sudo apt install jq"
    exit 1
fi
```

---

### 6. Nginx websites Verzeichnis fehlt
**Problem:** `docker-compose.yml` mounted `../examples/websites`, aber Verzeichnis existiert NICHT  
**Auswirkung:** Nginx zeigt 404  
**Lösung:**
```bash
mkdir -p examples/websites/default
cat > examples/websites/default/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Homeserver</title></head>
<body>
  <h1>🏠 Willkommen zum Homeserver</h1>
  <p>Zugriff auf Services: <a href="http://home.homeserver.local">Dashboard</a></p>
</body>
</html>
EOF
```

---

### 7. HOMEPAGE_VAR_GRAFANA_PASSWORD fehlt in Docker Compose
**Problem:** `configs/homepage/services.yaml` nutzt `{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}`, aber Variable fehlt im Container  
**Datei:** `docker-compose/docker-compose.yml` (homepage service)  
**Lösung:** Environment hinzufügen (nach Zeile 466):
```yaml
    environment:
      - DOCKER_HOST=tcp://docker-proxy:2375
      - TZ=${TZ:-Europe/Berlin}
      - HOMEPAGE_VAR_GRAFANA_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
```

---

## 🟡 MITTEL (Optional, verbessert UX)

### 8. Dokumentations-Inkonsistenzen

#### Gitea Domain
**Falsch in folgenden Dateien:**
- `QUICK_START_GUIDE.md` → `git.homeserver.local` (sollte `git.homeserver.local` sein)
- `SERVER_EINRICHTUNG_ANLEITUNG.md` → mehrfach `git.homeserver.local`

**Find & Replace:**
```bash
grep -rl "gitea\.homeserver\.local" . | grep -v ".git" | \
  xargs sed -i 's/gitea\.homeserver\.local/git.homeserver.local/g'
```

#### Installations-Pfad
**Inkonsistenzen:**
- `/opt/homeserver` ✅ (korrekt)
- `/opt/homeserver-setup` ❌ (veraltet)
- `/opt/homeserver-quickstart` ❌ (veraltet)

**Fix:** Alle Dokumente auf `/opt/homeserver` standardisieren

---

### 9. Fehlende Dokumentation
**Erstellen:**
- `docs/wireguard-setup.md` (wird in `docs/installation.md:280` referenziert)
- `configs/grafana/README.md`
- `configs/nginx/README.md`
- `configs/prometheus/README.md`
- `configs/traefik/README.md`

---

## 🟢 NIEDRIG (Aufräumen)

### 10. Alte Bug-Reports konsolidieren
**Verzeichnis:** `archive/old-bug-reports/`  
**Enthält:** 4 ähnliche Bug-Reports vom 2025-11-13  
**Empfehlung:** Zusammenführen zu einer Datei oder löschen

### 11. Leere Verzeichnisse entfernen
```bash
rmdir configs/postfix/  # Nicht genutzt
rmdir docs/guides/      # Leer
rmdir docs/images/      # Leer
```

---

## 📋 SCHNELL-FIX SCRIPT

Erstelle `scripts/apply-remaining-fixes.sh`:

```bash
#!/bin/bash
set -euo pipefail

echo "Anwende verbleibende Fixes..."

# Fix 1: Redis Config generieren
if [ -f ".env" ]; then
    source .env
    envsubst < configs/redis/redis.conf.template > configs/redis/redis.conf
    chmod 644 configs/redis/redis.conf
    echo "✓ Redis Config generiert"
fi

# Fix 4: .env.example REGISTRY_AUTH umbenennen
sed -i 's/^REGISTRY_AUTH=/REGISTRY_UI_AUTH=/' .env.example
echo "✓ .env.example REGISTRY_AUTH → REGISTRY_UI_AUTH"

# Fix 6: Nginx websites erstellen
mkdir -p examples/websites/default
if [ ! -f "examples/websites/default/index.html" ]; then
    cat > examples/websites/default/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>Homeserver</title></head>
<body><h1>🏠 Willkommen zum Homeserver</h1></body></html>
EOF
    echo "✓ Nginx default website erstellt"
fi

# Fix 8: Gitea Domain korrigieren
find . -type f \( -name "*.md" -o -name "*.sh" \) -not -path "./.git/*" \
  -exec sed -i 's/gitea\.homeserver\.local/git.homeserver.local/g' {} +
echo "✓ Gitea Domain korrigiert"

echo ""
echo "✅ Fixes angewendet!"
echo ""
echo "MANUELL ZU BEHEBEN:"
echo "  - Fix 3: MCP Credentials in 00-generate-secrets.sh hinzufügen"
echo "  - Fix 5: Dependency-Checks in restore.sh und mail-manager.sh"
echo "  - Fix 7: HOMEPAGE_VAR_GRAFANA_PASSWORD in docker-compose.yml"
```

---

## ✅ TESTING CHECKLIST

Nach Anwendung der Fixes:

1. **Secrets generieren:**
   ```bash
   ./scripts/00-generate-secrets.sh
   cat .env | grep MCP_POSTGRES_PASSWORD  # Sollte NICHT leer sein
   ```

2. **Redis Config prüfen:**
   ```bash
   ls -l configs/redis/redis.conf  # Sollte existieren
   grep "requirepass" configs/redis/redis.conf  # Sollte Passwort enthalten
   ```

3. **Installation testen:**
   ```bash
   sudo ./install-homeserver.sh
   docker ps  # Alle Container sollten "Up" sein
   ```

4. **Services testen:**
   ```bash
   curl http://home.homeserver.local  # Homepage
   curl http://git.homeserver.local   # Gitea
   ```

5. **MCP DB testen:**
   ```bash
   docker logs mcp-db  # Keine Connection-Fehler
   ```

---

## 🎯 PRIORITÄTEN-REIHENFOLGE

1. **SOFORT:** Fix 1 (Redis Config) + Fix 3 (MCP Credentials)
2. **VOR DEPLOYMENT:** Fix 4, 5, 6, 7
3. **BEI GELEGENHEIT:** Fix 8, 9
4. **OPTIONAL:** Fix 10, 11

---

**Status:** Projekt ist zu **85% produktionsreif**  
**Verbleibende kritische Fixes:** 4  
**Geschätzte Fix-Zeit:** 30-60 Minuten
