# Homeserver Quick Reference

## Essential Commands

```bash
# Service Management
docker-compose up -d                    # Start all services
docker-compose down                     # Stop all services
docker-compose restart service          # Restart specific service
docker-compose logs -f service          # Follow logs
docker-compose ps                       # List running containers

# Maintenance
docker system prune -a                  # Clean unused containers/images
docker-compose pull                     # Update images
docker-compose up -d --force-recreate   # Recreate all containers

# Backups
tar -czf backup-$(date +%Y%m%d).tar.gz data/
tar -czf backup-$(date +%Y%m%d).tar.gz ./docker-compose.yml
```

## Port Reference

| Service | Port | Description |
|---------|------|-------------|
| Traefik | 80,443,8080 | Reverse proxy, Dashboard |
| Nginx | 80,443 | Web server |
| PostgreSQL | 5432 | Database |
| MySQL | 3306 | Database |
| Redis | 6379 | Cache |
| Mail | 587,993,995 | SMTP, IMAP, POP3 |

## Common Configurations

### Adding a New Service

1. **Create service definition** in `custom-services.yml`:
```yaml
services:
  my-service:
    image: service/image:latest
    ports:
      - "port:container-port"
    labels:
      - traefik.enable=true
      - traefik.http.routers.my-service.rule=Host(`my-service.homeserver.local`)
    networks:
      - frontend
      - backend
```

2. **Update main docker-compose.yml**:
```yaml
version: '3.8'
services:
  nginx:
    # ... existing config
  # ... other services
  my-service:
    extends: file: custom-services.yml
    service: my-service
```

3. **Test configuration**:
```bash
docker-compose config
docker-compose up -d
```

### Environment Variables

Core variables to set in `.env`:

```env
DOMAIN=homeserver.local
EMAIL=admin@homeserver.local
POSTGRES_PASSWORD=strong_password
MYSQL_ROOT_PASSWORD=strong_password
TZ=Europe/Berlin
```

### SSL Certificate Setup

Traefik automatically provisions Let's Encrypt certificates:

```yaml
# docker-compose.yml
services:
  traefik:
    # ... existing config
    command:
      # ... existing commands
      - --certificatesresolvers.letsencrypt.acme.email=admin@homeserver.local
      - --certificatesresolvers.letsencrypt.acme.storage=/acme.json
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
```

## Monitoring

### Health Checks

All services include health checks:

```bash
# Check service health
docker-compose ps

# Manual health check
curl http://localhost/health
```

### Log Analysis

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs nginx
docker-compose logs postgres

# Follow logs in real-time
docker-compose logs -f
```

## Security

### Basic Security Checklist

- Change all default passwords
- Enable SSL/TLS for all services
- Use strong, unique passwords
- Keep containers updated
- Monitor logs regularly
- Restrict external access
- Enable Traefik basic auth

### Network Security

Docker networks are isolated:
- `frontend`: External access via Traefik
- `backend`: Internal service communication

## Backup Strategy

### Automated Backups

```bash
# Database backups
docker-compose exec postgres pg_dump -U postgres dbname > backup.sql

# File backups
tar -czf /backups/files-$(date +%Y%m%d).tar.gz /data/files
```

### Backup Script Example

```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups"

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backups
docker-compose exec -T postgres pg_dump -U postgres --all > $BACKUP_DIR/databases-$DATE.sql

# Container volumes
tar -czf $BACKUP_DIR/volumes-$DATE.tar.gz /home/user/homeserver/data/

# Configuration files
tar -czf $BACKUP_DIR/config-$DATE.tar.gz /home/user/homeserver/

# Upload to remote storage
rclone copy $BACKUP_DIR remote:backups/homeserver/$DATE/
```

## Performance

### Resource Limits

Set memory limits in docker-compose:

```yaml
services:
  postgres:
    mem_limit: 1g
    cpus: '1.0'
  redis:
    mem_limit: 512m
    cpus: '0.5'
```

### Monitoring

Access monitoring at:
- Grafana: http://grafana.homeserver.local
- Traefik Dashboard: http://traefik.homeserver.local:8080

## Troubleshooting

### Services Not Starting

1. Check logs: `docker-compose logs service_name`
2. Verify ports: `netstat -tlnp | grep :port`
3. Check permissions: `sudo chown -R $USER:$USER ./data`

### Network Issues

```bash
# Check network status
docker network ls
docker network inspect homeserver_backend

# Test connectivity
docker-compose exec nginx ping postgres
```

### Database Issues

```bash
# Connect to database
docker-compose exec postgres psql -U postgres

# Check database size
docker-compose exec postgres psql -U postgres -c "\l+"

# Check connections
docker-compose exec postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

## Useful Links

- [Traefik Documentation](https://docs.traefik.io/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)