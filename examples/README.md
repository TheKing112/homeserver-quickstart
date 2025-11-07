# Homeserver Examples

This directory contains example configurations and templates for your homeserver setup.

## Directory Structure

```
examples/
â”œâ”€â”€ docker-compose/
â”‚   â”œâ”€â”€ docker-compose.override.example.yml  # Override base configuration
â”‚   â””â”€â”€ custom-service.yml                   # Custom service examples
â”œâ”€â”€ nginx-sites/
â”‚   â””â”€â”€ example-site.conf                    # Nginx site configuration
â”œâ”€â”€ websites/
â”‚   â””â”€â”€ default/
â”‚       â””â”€â”€ index.html                       # Example website
â””â”€â”€ .env.production.example                  # Environment variables template
```

## Getting Started

### 1. Docker Compose Overrides

Use `docker-compose.override.yml` to customize your base configuration without modifying the main files.

```bash
# Copy the example override
cp examples/docker-compose/docker-compose.override.example.yml docker-compose.override.yml

# Edit according to your needs
nano docker-compose.override.yml

# Restart services to apply changes
docker-compose up -d
```

### 2. Custom Services

Add new services by copying the examples:

```bash
# Copy custom service example
cp examples/docker-compose/custom-service.yml custom-services.yml

# Add to your main docker-compose.yml
# Include: - custom-services.yml
```

### 3. Nginx Configurations

Add custom site configurations:

```bash
# Copy example configuration
cp examples/nginx-sites/example-site.conf nginx-sites/
# Replace 'example' with your domain
sed 's/example/yourdomain/g' nginx-sites/example.conf > nginx-sites/yourdomain.conf

# Test configuration
docker-compose exec nginx nginx -t
```

### 4. Environment Variables

Set up your production environment:

```bash
# Copy environment template
cp examples/.env.production.example .env

# Edit with your values
nano .env
```

### 5. Example Website

Deploy a sample website:

```bash
# Create website directory
mkdir -p websites/default

# Copy example HTML
cp examples/websites/default/index.html websites/default/

# Update nginx configuration to point to new website
# Add location block in nginx configuration
```

## Common Use Cases

### Adding New Services

1. Find a relevant example in `docker-compose/custom-service.yml`
2. Copy and modify the service configuration
3. Add required environment variables
4. Configure nginx reverse proxy
5. Set up SSL certificate

### Database Backups

Add backup configuration to your services:

```yaml
services:
  your-service:
    # ... your service config
    volumes:
      - your-data:/data
      - ./backups:/backups
    command: /path/to/backup/script.sh
```

### Monitoring

Add monitoring services:

```yaml
services:
  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    labels:
      - traefik.enable=true
      - traefik.http.routers.grafana.rule=Host(`grafana.homeserver.local`)
```

## Security Notes

- Always change default passwords
- Use strong, unique passwords for all services
- Regularly update container images
- Monitor logs for suspicious activity
- Keep SSL certificates updated

## Troubleshooting

### Services Not Starting

Check logs:
```bash
docker-compose logs service_name
```

### Port Conflicts

Check if ports are already in use:
```bash
netstat -tlnp | grep :port
```

### Permission Issues

Fix file permissions:
```bash
sudo chown -R $USER:$USER ./data
sudo chmod -R 755 ./data
```

## Support

For questions and support:
- Check the main README.md
- Review service documentation
- Check container logs
- Search existing issues