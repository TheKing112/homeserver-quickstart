# Mail Management API

RESTful API for managing the Mailu mail server.

## Features

- Domain management
- Mailbox creation/deletion
- Password changes
- Alias management
- Statistics

## Authentication

All endpoints (except `/health`) require Bearer token authentication:
```bash
Authorization: Bearer YOUR_API_TOKEN
```

## Endpoints

### Health Check
```bash
GET /health
```

### Domains
```bash
# List domains
GET /api/domains

# Add domain
POST /api/domains
{
  "domain": "example.com"
}

# Delete domain
DELETE /api/domains/example.com
```

### Mailboxes
```bash
# List mailboxes
GET /api/mailboxes?domain=example.com

# Create mailbox
POST /api/mailboxes
{
  "email": "user",
  "domain": "example.com",
  "password": "SecurePass123!",
  "quota_bytes": 1073741824
}

# Delete mailbox
DELETE /api/mailboxes/user@example.com

# Change password
PUT /api/mailboxes/user@example.com/password
{
  "password": "NewSecurePass456!"
}
```

### Aliases
```bash
# List aliases
GET /api/aliases?domain=example.com

# Create alias
POST /api/aliases
{
  "alias": "contact",
  "domain": "example.com",
  "destination": "user@example.com"
}
```

### Statistics
```bash
GET /api/stats
```

## Usage Example
```bash
# Set token
TOKEN="your-api-token-here"

# Add domain
curl -X POST http://mail-api.homeserver.local/api/domains \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"domain":"example.com"}'

# Create mailbox
curl -X POST http://mail-api.homeserver.local/api/mailboxes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email":"info",
    "domain":"example.com",
    "password":"SecurePass123!",
    "quota_bytes":2147483648
  }'
```

## Docker Compose

Already included in `docker-compose.mail.yml`.

## Environment Variables

- `MAIL_MYSQL_HOST` - MySQL host (default: mail-mysql)
- `MAIL_MYSQL_USER` - MySQL user (default: root)
- `MAIL_MYSQL_ROOT_PASSWORD` - MySQL password
- `MAIL_MYSQL_DB` - Database name (default: mailu)
- `MAIL_API_TOKEN` - API authentication token