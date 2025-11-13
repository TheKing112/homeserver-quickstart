#!/bin/bash

echo "=== MCP-Server Implementierungen erstellen ==="
echo ""

# Basis-Template für package.json
create_package_json() {
  local name=$1
  local desc=$2
  
  cat > "package.json" << PKGJSON
{
  "name": "mcp-${name}",
  "version": "1.0.0",
  "description": "${desc}",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "morgan": "^1.10.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
PKGJSON
}

# Basis-Template für Express-Server
create_index_js() {
  local service=$1
  local port=$2
  
  cat > "index.js" << INDEXJS
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || ${port};

app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: '${service}' });
});

app.get('/api/info', (req, res) => {
  res.json({
    service: '${service}',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(\`${service} running on port \${PORT}\`);
});
INDEXJS
}

# Dockerfile Template
create_dockerfile() {
  cat > "Dockerfile" << DOCKERFILE
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
DOCKERFILE
}

# Database MCP Server
echo "[1/4] Database MCP Server..."
cd /workspace/Homeserver/homeserver-quickstart/mcp-servers/database
create_package_json "database" "MCP Database Management Server"
cat >> package.json << 'PKG'
PKG
sed -i '/"dependencies": {/a\    "pg": "^8.11.3",\n    "mysql2": "^3.6.0",\n    "redis": "^4.6.7",' package.json
create_index_js "MCP Database Server" 3000
create_dockerfile
echo "✓ Database Server erstellt"

# Docker MCP Server
echo "[2/4] Docker MCP Server..."
cd /workspace/Homeserver/homeserver-quickstart/mcp-servers/docker
create_package_json "docker" "MCP Docker Management Server"
sed -i '/"dependencies": {/a\    "dockerode": "^4.0.0",' package.json
create_index_js "MCP Docker Server" 3000
create_dockerfile
echo "✓ Docker Server erstellt"

# Filesystem MCP Server
echo "[3/4] Filesystem MCP Server..."
cd /workspace/Homeserver/homeserver-quickstart/mcp-servers/filesystem
create_package_json "filesystem" "MCP Filesystem Server"
sed -i '/"dependencies": {/a\    "chokidar": "^3.5.3",' package.json
create_index_js "MCP Filesystem Server" 3000
create_dockerfile
echo "✓ Filesystem Server erstellt"

# HTTP Client MCP Server
echo "[4/4] HTTP Client MCP Server..."
cd /workspace/Homeserver/homeserver-quickstart/mcp-servers/http-client
create_package_json "http-client" "MCP HTTP Client Server"
sed -i '/"dependencies": {/a\    "axios": "^1.6.0",' package.json
create_index_js "MCP HTTP Client Server" 3000
create_dockerfile
echo "✓ HTTP Client Server erstellt"

echo ""
echo "=== Validierung ==="
for dir in database docker filesystem http-client; do
  cd /workspace/Homeserver/homeserver-quickstart/mcp-servers/$dir
  echo -n "$dir: "
  if python3 -c "import json; json.load(open('package.json'))" 2>/dev/null; then
    echo "✓"
  else
    echo "✗"
  fi
done

echo ""
echo "✓ Alle MCP-Server erstellt!"
