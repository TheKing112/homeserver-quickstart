# Mail Server Setup Guide

Complete guide to configuring your mail server.

## Overview

The homeserver includes a full-featured mail server powered by Mailu:

- SMTP (sending mail)
- IMAP/POP3 (receiving mail)
- Webmail interface
- Admin panel
- REST API
- Spam filtering (Rspamd)
- Antivirus (ClamAV)
- DKIM, SPF, DMARC support

## Quick Setup

### 1. Configure Domain

Edit `.env`:
```bash
MAIL_PRIMARY_DOMAIN=example.com
MAIL_DOMAINS=example.com,example2.com
```

### 2. DNS Configuration

Configure these DNS records:
```dns
; A Record
@       IN A     YOUR_PUBLIC_IP
mail    IN A     YOUR_PUBLIC_IP

; MX Record
@       IN MX 10 mail.example.com.

; SPF Record
@       IN TXT   "v=spf1 mx ~all"

; DMARC Record
_dmarc  IN TXT   "v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com"
```

### 3. Create Admin Account
```bash
# From server
./scripts/mail-manager.sh add-domain example.com
./scripts/mail-manager.sh add-mailbox admin example.com "SecurePassword123!" 5000

# From Windows
.\windows-tools\mail-manager.ps1 -Action add-mailbox `
    -Email admin -Domain example.com `
    -Password "SecurePassword123!" -QuotaMB 5000
```

### 4. Configure DKIM

1. Visit http://mail.homeserver.local/admin
2. Login with admin@example.com
3. Go to "Mail domains"
4. Click on your domain
5. Click "Regenerate keys"
6. Copy the DKIM public key

Add to DNS:
```dns
dkim._domainkey  IN TXT  "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY..."
```

### 5. Configure Reverse DNS (PTR)

Contact your ISP or hosting provider to set:
```
YOUR_PUBLIC_IP â†’ mail.example.com
```

## Detailed Configuration

### Port Forwarding

Forward these ports in your router:

| Port | Protocol | Service |
|------|----------|---------|
| 25 | TCP | SMTP |
| 465 | TCP | SMTPS (SSL) |
| 587 | TCP | Submission (STARTTLS) |
| 143 | TCP | IMAP |
| 993 | TCP | IMAPS (SSL) |
| 110 | TCP | POP3 |
| 995 | TCP | POP3S (SSL) |

### Email Client Setup

**IMAP (Recommended):**
- Server: mail.example.com
- Port: 993
- Security: SSL/TLS
- Username: user@example.com
- Password: your_password

**SMTP:**
- Server: mail.example.com
- Port: 587
- Security: STARTTLS
- Authentication: Required

### Admin Panel

Access: http://mail.homeserver.local/admin

**Features:**
- User management
- Domain configuration
- Alias management
- DKIM key generation
- Spam filter settings
- Webmail access

### Webmail

Access: http://mail.homeserver.local/webmail

Full-featured webmail client (Roundcube).

## Mail Management API

RESTful API for programmatic management.

**Base URL:** `http://192.168.1.100:5000/api`

**Authentication:** Bearer token (from `.env`)

### Examples

**Add domain:**
```bash
curl -X POST http://192.168.1.100:5000/api/domains \
  -H "Authorization: Bearer $MAIL_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"domain":"example.com"}'
```

**Create mailbox:**
```bash
curl -X POST http://192.168.1.100:5000/api/mailboxes \
  -H "Authorization: Bearer $MAIL_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email":"user",
    "domain":"example.com",
    "password":"SecurePass123!",
    "quota_bytes":1073741824
  }'
```

**Get statistics:**
```bash
curl -X GET http://192.168.1.100:5000/api/stats \
  -H "Authorization: Bearer $MAIL_API_TOKEN"
```

See [API Reference](api-reference.md) for complete documentation.

## Testing Your Mail Server

### Send Test Email
```bash
# Install mailutils
sudo apt install mailutils

# Send test
echo "Test email body" | mail -s "Test Subject" recipient@example.com
```

### Check Deliverability

Test your mail server configuration:

1. [MXToolbox](https://mxtoolbox.com/)
2. [Mail-tester](https://www.mail-tester.com/)
3. [DKIM Validator](https://dkimvalidator.com/)

### Monitor Logs
```bash
# Postfix logs
docker compose -f docker-compose.mail.yml logs -f mail-front

# Spam filter logs
docker compose -f docker-compose.mail.yml logs -f mail-rspamd
```

## Spam Management

### Adjust Spam Threshold

1. Visit http://mail.homeserver.local/admin
2. Settings â†’ Antispam
3. Adjust threshold (default: 5.0)

### Whitelist/Blacklist

Add to Rspamd configuration:
```bash
docker exec mail-rspamd nano /etc/rspamd/local.d/whitelist.conf
```

## Troubleshooting

### Email Not Sending

**Check logs:**
```bash
docker compose -f docker-compose.mail.yml logs mail-front
```

**Common issues:**
- Port 25 blocked by ISP
- Incorrect DNS records
- Missing reverse DNS (PTR)

### Email Marked as Spam

**Checklist:**
- OK SPF record configured
- OK DKIM configured and published
- OK DMARC record present
- OK Reverse DNS (PTR) set
- OK Not on blacklists

**Test:** https://www.mail-tester.com/

### Can't Access Webmail
```bash
# Check service status
docker compose -f docker-compose.mail.yml ps

# Restart webmail
docker compose -f docker-compose.mail.yml restart mail-webmail
```

## Security Best Practices

1. **Strong passwords** - Use 16+ character passwords
2. **2FA** - Enable in Roundcube
3. **Regular updates** - Keep Mailu updated
4. **Monitor logs** - Watch for suspicious activity
5. **Backup** - Include mail data in backups

## Advanced Topics

### Catch-All Email

In admin panel:
1. Aliases
2. Create new: `@example.com` â†’ `catchall@example.com`

### Email Forwarding
```bash
./scripts/mail-manager.sh add-alias sales example.com sales@example.com,support@example.com
```

### Multiple Domains

Add to `.env`:
```bash
MAIL_DOMAINS=domain1.com,domain2.com,domain3.com
```

Each domain needs its own DNS configuration.

## See Also

- [API Reference](api-reference.md)
- [Troubleshooting](troubleshooting.md)
- [Security Guide](security.md)