# START Homeserver Quickstart

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu)](https://ubuntu.com/)
[![Docker](https://img.shields.io/badge/Docker-24.0+-2496ED?logo=docker)](https://www.docker.com/)

> Complete automated homeserver setup in ~60 minutes with Docker, reverse proxy, databases, mail server, monitoring, and more!

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