#!/bin/bash
set -euo pipefail

echo "🧹 Anwende verbleibende Fixes..."

# Fix 1: Redis Config generieren
if [ -f ".env" ]; then
    source .env
    if [ -f "configs/redis/redis.conf.template" ]; then
        envsubst < configs/redis/redis.conf.template > configs/redis/redis.conf
        chmod 644 configs/redis/redis.conf
        echo "✓ Redis Config generiert"
    fi
fi

# Fix 4: .env.example REGISTRY_AUTH umbenennen
if grep -q "^REGISTRY_AUTH=" .env.example 2>/dev/null; then
    sed -i 's/^REGISTRY_AUTH=/REGISTRY_UI_AUTH=/' .env.example
    echo "✓ .env.example REGISTRY_AUTH → REGISTRY_UI_AUTH"
fi

# Fix 6: Nginx websites erstellen
mkdir -p examples/websites/default
if [ ! -f "examples/websites/default/index.html" ]; then
    cat > examples/websites/default/index.html << 'HTML'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Homeserver</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 800px;
            margin: 100px auto;
            padding: 20px;
            text-align: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        a {
            display: inline-block;
            margin: 10px;
            padding: 15px 30px;
            background: rgba(255,255,255,0.2);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            transition: all 0.3s;
        }
        a:hover { background: rgba(255,255,255,0.3); transform: translateY(-2px); }
    </style>
</head>
<body>
    <h1>🏠 Willkommen zum Homeserver</h1>
    <p style="font-size: 1.2em; margin: 30px 0;">Dein persönlicher Server ist bereit!</p>
    <div>
        <a href="http://home.homeserver.local">📊 Dashboard</a>
        <a href="http://git.homeserver.local">🔧 Gitea</a>
        <a href="http://portainer.homeserver.local">🐳 Portainer</a>
        <a href="http://grafana.homeserver.local">📈 Grafana</a>
    </div>
</body>
</html>
HTML
    echo "✓ Nginx default website erstellt"
fi

# Fix 8: Gitea Domain korrigieren (falls noch vorhanden)
find . -type f \( -name "*.md" -o -name "*.sh" \) -not -path "./.git/*" \
  -exec sed -i 's/gitea\.homeserver\.local/git.homeserver.local/g' {} + 2>/dev/null || true
echo "✓ Gitea Domain korrigiert (falls vorhanden)"

# Fix 11: Leere Verzeichnisse entfernen
[ -d "configs/postfix" ] && [ -z "$(ls -A configs/postfix)" ] && rmdir configs/postfix && echo "✓ Leeres configs/postfix/ entfernt"
[ -d "docs/guides" ] && [ -z "$(ls -A docs/guides)" ] && rmdir docs/guides && echo "✓ Leeres docs/guides/ entfernt"
[ -d "docs/images" ] && [ -z "$(ls -A docs/images)" ] && rmdir docs/images && echo "✓ Leeres docs/images/ entfernt"

echo ""
echo "✅ Automatische Fixes angewendet!"
echo ""
echo "📝 MANUELL ZU BEHEBEN:"
echo "  1. Fix 3: MCP Credentials in scripts/00-generate-secrets.sh hinzufügen"
echo "  2. Fix 5: Dependency-Checks in scripts/restore.sh und scripts/mail-manager.sh"
echo "  3. Fix 7: HOMEPAGE_VAR_GRAFANA_PASSWORD in docker-compose/docker-compose.yml"
echo ""
echo "Siehe VERBLEIBENDE_FIXES.md für Details"
