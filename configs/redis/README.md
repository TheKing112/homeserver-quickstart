# Redis Configuration Template
# This file will be processed by envsubst to replace ${REDIS_PASSWORD}

# Network
bind 0.0.0.0
protected-mode yes
port 6379

# Security
requirepass ${REDIS_PASSWORD}

# Persistence
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

# Memory
maxmemory 256mb
maxmemory-policy allkeys-lru

# Performance
save 900 1
save 300 10
save 60 10000

# Logging
loglevel notice
# Redis Configuration

## Setup

The Redis configuration uses a template file to avoid exposing passwords in the Docker command line.

### Automatic Setup (Recommended)

The `install-homeserver.sh` script will automatically generate `redis.conf` from `redis.conf.template` by replacing `${REDIS_PASSWORD}` with the actual password from `.env`.

### Manual Setup

If you need to generate the config manually:

```bash
# From homeserver-quickstart root directory
export $(cat .env | grep REDIS_PASSWORD)
envsubst < configs/redis/redis.conf.template > configs/redis/redis.conf
chmod 600 configs/redis/redis.conf
```

## Security

- `redis.conf` is in `.gitignore` to prevent password leakage
- Only `redis.conf.template` is version controlled
- Config file is mounted read-only in Docker container
