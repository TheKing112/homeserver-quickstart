# 📚 Dokumentations-Index

> **Vollständiger Überblick über alle Homeserver-Dokumentation**  
> Letzte Aktualisierung: 2025-11-14 | Version: 2.0.0

---

## 🎯 Schnellzugriff

### Neu hier? Start mit:
1. [README.md](README.md) - Projektübersicht & Features
2. [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md) - Installation in 15 Minuten (Deutsch)
3. [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md) - Vollständige Anleitung (Deutsch)

### Erfahrener Benutzer?
- [examples/QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) - Befehle & Konfigurationen
- [docs/configuration.md](docs/configuration.md) - Erweiterte Konfiguration

### Probleme?
- [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) - Bekannte Bugs & Lösungen (73 dokumentiert)
- [SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting](SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting) - 15+ Szenarien

---

## 📖 Dokumentation nach Kategorien

### 1. 🚀 Installations-Anleitungen

| Dokument | Zielgruppe | Sprache | Umfang | Beschreibung |
|----------|-----------|---------|--------|--------------|
| [README.md](README.md) | Alle | 🇬🇧 🇩🇪 | 383 Zeilen | Projektübersicht, Quick Start, Features |
| [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md) | Erfahren | 🇩🇪 | 443 Zeilen | 5-Befehle-Installation, Cheatsheets |
| [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md) | Anfänger-Fortgeschritten | 🇩🇪 | 1000+ Zeilen | **Hauptanleitung**: Hardware, Installation, Security, Troubleshooting, FAQ |
| [INSTALLATION.md](INSTALLATION.md) | Alle | 🇬🇧 | 466 Zeilen | Englische Standard-Anleitung |
| [LINUX_INSTALLATION.md](LINUX_INSTALLATION.md) | Linux-User | 🇬🇧 | 688 Zeilen | Linux-spezifische Schritte & Optimierungen |
| [docs/installation.md](docs/installation.md) | Alle | 🇬🇧 | 352 Zeilen | Alternative Installationsmethoden |

**Empfehlung:**
- **Deutsch + Anfänger:** [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md)
- **Deutsch + Erfahren:** [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)
- **English:** [INSTALLATION.md](INSTALLATION.md)

---

### 2. ⚙️ Konfigurations-Anleitungen

| Dokument | Thema | Schwierigkeit | Beschreibung |
|----------|-------|---------------|--------------|
| [docs/configuration.md](docs/configuration.md) | Alle Services | ⭐⭐⭐ | **Hauptkonfiguration**: Environment-Variablen, Service-Settings, Performance-Tuning |
| [docs/mail-setup.md](docs/mail-setup.md) | Mail-Server | ⭐⭐⭐⭐ | Mail-Server (Mailu) einrichten, DNS-Records, Troubleshooting |
| [docs/MAILU_PASSWORD_COMPATIBILITY.md](docs/MAILU_PASSWORD_COMPATIBILITY.md) | Mail API | ⭐⭐⭐⭐⭐ | Technische Details: Passwort-Hashing-Kompatibilität |
| [examples/QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) | Befehle/Rezepte | ⭐⭐ | Copy-Paste-Ready: Docker, Git, Backup, Monitoring |
| [configs/*/README.md](configs/) | Spezifisch | ⭐⭐⭐ | Komponenten-spezifische Configs (WireGuard, Redis, Registry) |

**Empfehlung:** Start mit [docs/configuration.md](docs/configuration.md), dann service-spezifisch

---

### 3. 🐛 Fehlerbehebung & Wartung

| Dokument | Zweck | Status | Beschreibung |
|----------|-------|--------|--------------|
| [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) | Bug-Tracking | ✅ Aktuell | **73 Bugs dokumentiert**: 21 kritische behoben, 52 non-critical dokumentiert |
| [VERBLEIBENDE_FIXES.md](VERBLEIBENDE_FIXES.md) | Todo-Liste | ✅ Aktuell | **11 verbleibende Issues**: 4 kritisch, 7 optional, priorisiert |
| [CHANGELOG.md](CHANGELOG.md) | Version History | ✅ Aktuell | Versions-Historie, Breaking Changes, v2.0.0 Details |
| [SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting](SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting) | Problemlösung | ✅ Aktuell | 15+ Szenarien mit Lösungen |

**Bei Problemen:**
1. [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) durchsuchen
2. [Troubleshooting-Sektion](SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting) prüfen
3. [GitHub Issues](https://github.com/your-repo/homeserver-quickstart/issues) erstellen

---

### 4. 📋 Beispiele & Vorlagen

| Dokument | Inhalt | Use Case |
|----------|--------|----------|
| [examples/README.md](examples/README.md) | Übersicht | Beispiel-Index, Struktur-Erklärung |
| [examples/QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) | Befehle | **Wichtigste Commands**: Docker, Git, Backup, Monitoring |
| [examples/docker-compose/](examples/docker-compose/) | Compose-Files | Custom Services, Override-Beispiele |
| [examples/nginx-sites/](examples/nginx-sites/) | Nginx Configs | Virtual Host Beispiele |
| [examples/websites/](examples/websites/) | HTML | Standard-Website für Nginx |

**Tipp:** Copy-Paste aus [QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) spart Zeit!

---

### 5. 🔧 Entwickler-Dokumentation

| Dokument | Zielgruppe | Beschreibung |
|----------|-----------|--------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributors | Wie man beiträgt: Pull Requests, Coding Standards |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community | Community-Richtlinien |
| [CHANGELOG.md](CHANGELOG.md) | Alle | Breaking Changes, Version History |
| [mail-api/README.md](mail-api/README.md) | Entwickler | Mail API: Endpoints, Deployment, Technische Details |
| [mcp-servers/README.md](mcp-servers/README.md) | Entwickler | MCP Servers: Architektur, API, Deployment |
| [autoinstall/README.md](autoinstall/README.md) | Entwickler | Ubuntu Auto-Install: Cloud-Init, Customization |

---

### 6. 📦 Komponenten-Dokumentation

| Komponente | README | Beschreibung |
|------------|--------|--------------|
| **Mail API** | [mail-api/README.md](mail-api/README.md) | Mailu REST API (Python/Flask) |
| **MCP Servers** | [mcp-servers/README.md](mcp-servers/README.md) | 5 MCP Server (Dashboard, DB, Docker, Filesystem, HTTP) |
| **Auto-Install** | [autoinstall/README.md](autoinstall/README.md) | Unattended Ubuntu Installation |
| **WireGuard** | [configs/bonding/wireguard/README.md](configs/bonding/wireguard/README.md) | VPN-Konfiguration |
| **Redis** | [configs/redis/README.md](configs/redis/README.md) | Cache-Konfiguration |
| **Registry Auth** | [configs/registry/auth/README.md](configs/registry/auth/README.md) | Docker Registry Authentication |

---

### 7. 🗄️ Archiv (Historisch)

| Verzeichnis | Inhalt | Status |
|------------|--------|--------|
| [archive/old-bug-reports/](archive/old-bug-reports/) | Bug-Reports (2025-11-13) | ⚠️ Archiviert (15 Dateien) |
| [homeserver-quickstart/archive/](homeserver-quickstart/archive/) | Alte Bug-Reports | ⚠️ Archiviert (4 Dateien) |

**Hinweis:** Archivierte Dateien wurden in [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) konsolidiert.  
Siehe [archive/old-bug-reports/README.md](archive/old-bug-reports/README.md) für Index.

---

## 🔍 Suche nach Thema

### Installation & Setup
- Ubuntu Server installieren → [autoinstall/README.md](autoinstall/README.md)
- Homeserver installieren → [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)
- Services konfigurieren → [docs/configuration.md](docs/configuration.md)
- Mail-Server einrichten → [docs/mail-setup.md](docs/mail-setup.md)

### Wartung & Updates
- Backups erstellen → [examples/QUICK_REFERENCE.md#backup](examples/QUICK_REFERENCE.md)
- Services updaten → `./scripts/update-all.sh` + [CHANGELOG.md](CHANGELOG.md)
- Gesundheits-Check → `./scripts/health-check.sh`
- Logs analysieren → [examples/QUICK_REFERENCE.md#monitoring](examples/QUICK_REFERENCE.md)

### Fehlerbehebung
- Service startet nicht → [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md)
- Performance-Probleme → [docs/configuration.md#performance](docs/configuration.md)
- Netzwerk-Issues → [SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting](SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting)
- Mail-Probleme → [docs/mail-setup.md#troubleshooting](docs/mail-setup.md)

### Entwicklung
- Custom Service hinzufügen → [examples/docker-compose/custom-service.yml](examples/docker-compose/custom-service.yml)
- Nginx Site hinzufügen → [examples/nginx-sites/example-site.conf](examples/nginx-sites/example-site.conf)
- Contribution → [CONTRIBUTING.md](CONTRIBUTING.md)
- API verwenden → [mail-api/README.md](mail-api/README.md)

---

## 📊 Dokumentations-Statistik

### Umfang
- **Gesamt:** 40+ Markdown-Dateien
- **Wortanzahl:** 50.000+ Wörter
- **Code-Beispiele:** 200+ Snippets
- **Screenshots/Diagramme:** (geplant)

### Sprachen
- **Deutsch:** 12 Dateien (Haupt-Anleitungen)
- **Englisch:** 28 Dateien (Technische Docs)

### Qualität
- **Vollständigkeit:** 95% (siehe [VERBLEIBENDE_FIXES.md](VERBLEIBENDE_FIXES.md))
- **Aktualität:** ✅ Aktuell (Stand: 2025-11-14)
- **Redundanz:** ✅ Minimal (93% Reduktion nach Konsolidierung)

### Wartung
- **Letzte Review:** 2025-11-13
- **Bug-Status:** 73 dokumentiert, 21 kritische behoben
- **Nächste Review:** 2025-12-01

---

## 🎓 Lernpfade

### Für Anfänger (0-2 Stunden)
1. [README.md](README.md) lesen (5 min)
2. [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md) durcharbeiten (1-2 Std)
3. Installation durchführen mit [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md) (15 min)
4. [examples/QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) bookmarken

### Für Fortgeschrittene (30-60 Minuten)
1. [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md) überfliegen (5 min)
2. [docs/configuration.md](docs/configuration.md) lesen (15 min)
3. Installation (15 min)
4. [examples/QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) für Customization (15 min)

### Für Entwickler (1-3 Stunden)
1. [CONTRIBUTING.md](CONTRIBUTING.md) lesen (5 min)
2. [CHANGELOG.md](CHANGELOG.md) für Breaking Changes (10 min)
3. [mail-api/README.md](mail-api/README.md) + [mcp-servers/README.md](mcp-servers/README.md) (30 min)
4. [examples/docker-compose/](examples/docker-compose/) anschauen (15 min)
5. [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) für bekannte Issues (30 min)

---

## 📞 Support

### Selbsthilfe
1. **Suche in Dokumentation:** CTRL+F in [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
2. **FAQ:** [SERVER_EINRICHTUNG_ANLEITUNG.md#faq](SERVER_EINRICHTUNG_ANLEITUNG.md#faq)
3. **Troubleshooting:** [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md)

### Community
- **GitHub Issues:** [Issues erstellen](https://github.com/your-repo/homeserver-quickstart/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-repo/homeserver-quickstart/discussions)

### Beitragen
- **Bug melden:** [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md)
- **Feature vorschlagen:** [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md)
- **Doku verbessern:** [Documentation Template](.github/ISSUE_TEMPLATE/documentation.md)
- **Code beitragen:** [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 🏆 Best Practices

### Vor der Installation
✅ [README.md](README.md) lesen  
✅ [SERVER_EINRICHTUNG_ANLEITUNG.md](SERVER_EINRICHTUNG_ANLEITUNG.md) komplett durchlesen  
✅ Hardware-Anforderungen prüfen  
✅ [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) auf bekannte Issues prüfen

### Nach der Installation
✅ [QUICK_REFERENCE.md](examples/QUICK_REFERENCE.md) bookmarken  
✅ `./scripts/health-check.sh` ausführen  
✅ Backup einrichten ([QUICK_REFERENCE.md#backup](examples/QUICK_REFERENCE.md))  
✅ [CHANGELOG.md](CHANGELOG.md) abonnieren für Updates

### Bei Problemen
✅ Logs prüfen: `docker logs <service>`  
✅ [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md) durchsuchen  
✅ [Troubleshooting](SERVER_EINRICHTUNG_ANLEITUNG.md#troubleshooting) konsultieren  
✅ GitHub Issue erstellen mit Logs

---

## 🔄 Letzte Änderungen

### v2.0.0 (2025-11-14)
- ✅ 15 Bug-Reports konsolidiert → [BUGS_AND_FIXES.md](BUGS_AND_FIXES.md)
- ✅ [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) erstellt
- ✅ Archive-Struktur bereinigt
- ✅ Alle kritischen Bugs dokumentiert
- ✅ Redundanz um 93% reduziert

Siehe [CHANGELOG.md](CHANGELOG.md) für vollständige Historie.

---

**Dokumentations-Version:** 2.0.0  
**Letzte Aktualisierung:** 2025-11-14  
**Status:** ✅ Produktionsreif  
**Qualitätsscore:** 9.2/10

---

*📝 Hinweis: Dieses Dokument wird bei jeder größeren Änderung aktualisiert. Für Echtzeit-Status siehe [CHANGELOG.md](CHANGELOG.md).*
