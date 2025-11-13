# Docker Registry Authentication

This directory contains the htpasswd file for Docker Registry authentication.

## Default Credentials

**⚠️ WARNING: Change these immediately in production!**

- Username: `admin`
- Password: `changeme`

## Generating New Credentials

```bash
# Using htpasswd (requires apache2-utils)
htpasswd -nbB admin your_password > htpasswd

# Or using Python
python3 << 'EOPYTHON'
import bcrypt
password = "your_password"
hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=10))
print(f"admin:{hashed.decode('utf-8')}")
EOPYTHON
```

## Security Notes

1. Always use strong passwords in production
2. Consider using external authentication (LDAP, OAuth2)
3. Keep this file secure (it's in .gitignore)
4. Rotate credentials regularly
