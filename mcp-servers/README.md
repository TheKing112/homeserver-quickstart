# MCP Servers - Homeserver

Model Context Protocol (MCP) Server-Implementierungen für den Homeserver.

## 📦 Verfügbare Services

### 1. Dashboard (Port 3000)
**Status:** ✅ Implementiert

Haupt-Dashboard für alle MCP-Services.

**Features:**
- Übersicht aller Services
- Status-Monitoring
- Web-UI

**Endpoints:**
- `GET /` - Dashboard UI
- `GET /api/status` - Service-Status

---

### 2. Database (Port 3000)
**Status:** ✅ Basis-Implementierung

Datenbank-Management für PostgreSQL, MySQL/MariaDB und Redis.

**Dependencies:**
- `pg` - PostgreSQL Client
- `mysql2` - MySQL/MariaDB Client
- `redis` - Redis Client

**Geplante Endpoints:**
- `GET /api/databases` - Liste aller Datenbanken
- `POST /api/query` - SQL-Query ausführen
- `GET /api/health` - Datenbank-Health-Check

---

### 3. Docker (Port 3000)
**Status:** ✅ Basis-Implementierung

Docker-Container und Image-Management.

**Dependencies:**
- `dockerode` - Docker API Client

**Geplante Endpoints:**
- `GET /api/containers` - Liste aller Container
- `POST /api/containers/:id/start` - Container starten
- `POST /api/containers/:id/stop` - Container stoppen
- `GET /api/images` - Liste aller Images

---

### 4. Filesystem (Port 3000)
**Status:** ✅ Basis-Implementierung

Dateisystem-Operationen und File-Watching.

**Dependencies:**
- `chokidar` - File-Watcher

**Geplante Endpoints:**
- `GET /api/files` - Dateien auflisten
- `GET /api/files/:path` - Datei lesen
- `POST /api/files/:path` - Datei erstellen
- `DELETE /api/files/:path` - Datei löschen

---

### 5. HTTP Client (Port 3000)
**Status:** ✅ Basis-Implementierung

HTTP-Request-Proxy und REST-API-Client.

**Dependencies:**
- `axios` - HTTP Client

**Geplante Endpoints:**
- `POST /api/request` - HTTP-Request ausführen
- `GET /api/history` - Request-Historie

---

## 🚀 Installation & Start

### Alle Services

```bash
cd /workspace/Homeserver/homeserver-quickstart/mcp-servers

# Dependencies installieren (für alle Services)
for dir in */; do
  if [ -f "$dir/package.json" ]; then
    cd "$dir"
    npm install
    cd ..
  fi
done
```

### Einzelner Service

```bash
cd dashboard  # oder database, docker, filesystem, http-client
npm install
npm start
```

### Mit Docker Compose

```bash
cd /workspace/Homeserver/homeserver-quickstart/docker-compose
docker-compose -f docker-compose.mcp.yml up -d
```

---

## 📊 Service-URLs

Nach dem Start mit Docker Compose:

| Service | URL |
|---------|-----|
| Dashboard | http://mcp-dashboard.homeserver.local |
| Database | http://mcp-db.homeserver.local |
| Docker | http://mcp-docker.homeserver.local |
| Filesystem | http://mcp-fs.homeserver.local |
| HTTP Client | http://mcp-http.homeserver.local |

**Hinweis:** `/etc/hosts` muss entsprechend konfiguriert sein.

---

## 🔧 Entwicklung

### Struktur

```
mcp-servers/
├── dashboard/
│   ├── package.json
│   ├── index.js
│   ├── Dockerfile
│   └── public/
│       └── index.html
├── database/
│   ├── package.json
│   ├── index.js
│   └── Dockerfile
├── docker/
│   ├── package.json
│   ├── index.js
│   └── Dockerfile
├── filesystem/
│   ├── package.json
│   ├── index.js
│   └── Dockerfile
└── http-client/
    ├── package.json
    ├── index.js
    └── Dockerfile
```

### Development Mode

```bash
# Mit nodemon (Auto-Reload)
npm install -g nodemon
cd dashboard
npm run dev
```

### Docker Build

```bash
cd dashboard
docker build -t mcp-dashboard .
docker run -p 3000:3000 mcp-dashboard
```

---

## ✅ Status

| Service | package.json | index.js | Dockerfile | Status |
|---------|-------------|----------|------------|--------|
| Dashboard | ✅ | ✅ | ✅ | ✅ Vollständig |
| Database | ✅ | ✅ | ✅ | 🟡 Basis |
| Docker | ✅ | ✅ | ✅ | 🟡 Basis |
| Filesystem | ✅ | ✅ | ✅ | 🟡 Basis |
| HTTP Client | ✅ | ✅ | ✅ | 🟡 Basis |

**Legende:**
- ✅ Vollständig implementiert
- 🟡 Basis-Implementierung (erweiterbar)
- ❌ Fehlend

---

## 📝 Nächste Schritte

1. **API-Endpunkte implementieren**
   - Database: Query-Execution, Connection-Pooling
   - Docker: Container-Management-API
   - Filesystem: File-Operations, Watch-Events
   - HTTP Client: Request-Proxying

2. **Authentifizierung**
   - API-Token-System
   - JWT-basierte Auth

3. **Logging & Monitoring**
   - Strukturierte Logs
   - Metriken-Export (Prometheus)

4. **Tests**
   - Unit-Tests mit Jest
   - Integration-Tests

---

## 🛠️ Fehlerbehebung

### Port bereits belegt

```bash
# Port-Nutzung prüfen
lsof -i :3000

# Oder in docker-compose Port ändern
ports:
  - "3001:3000"  # statt 3000:3000
```

### Dependencies fehlen

```bash
cd <service>
rm -rf node_modules package-lock.json
npm install
```

### Container startet nicht

```bash
# Logs prüfen
docker logs mcp-dashboard

# Container neu bauen
docker-compose -f docker-compose.mcp.yml build --no-cache
docker-compose -f docker-compose.mcp.yml up -d
```

---

**Erstellt:** 2025-11-12  
**Version:** 1.0.0
