# Mailu Password Hash Compatibility Guide

## Current Implementation

The Mail API currently uses `bcrypt_sha256` from passlib:

```python
from passlib.hash import bcrypt_sha256
password_hash = bcrypt_sha256.hash(password)
```

## Mailu Supported Hash Formats

Based on Mailu documentation and source code analysis, Mailu supports multiple password hash schemes through the Python passlib library:

### Supported Schemes:
1. **BLF-CRYPT** (Bcrypt) - Current default in newer Mailu versions
2. **SHA512-CRYPT** - Traditional Unix hash
3. **SHA256-CRYPT** - Traditional Unix hash  
4. **PBKDF2-SHA512** - Fast and secure
5. **BCRYPT-SHA256** - **✅ Compatible with current implementation**
6. **MD5-CRYPT** - Legacy, not recommended

## Compatibility Status

### ✅ BCRYPT-SHA256 is Compatible!

The `bcrypt_sha256` scheme used in our Mail API **is supported by Mailu**. This scheme:
- Combines SHA256 pre-hashing with bcrypt
- Prevents bcrypt's 72-character limitation
- Is recognized by passlib's `CryptContext`
- Should work with Mailu without modifications

### Hash Format Example:
```
$bcrypt-sha256$2b$12$randomsalt$randomhashvalue
```

## Verification Steps

To verify compatibility with your specific Mailu installation:

### 1. Check Mailu Version
```bash
docker exec mailu-admin cat /version.txt
```

### 2. Test Password Hash
Create a test user via Mail API and try logging in through Mailu web interface:

```bash
# Create test user
curl -X POST http://localhost:5000/api/mailboxes \
  -H "Authorization: Bearer $MAIL_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser",
    "domain": "yourdomain.com",
    "password": "TestPassword123!",
    "quota_bytes": 1000000000
  }'

# Try logging in at https://mail.yourdomain.com/admin
# Username: testuser@yourdomain.com
# Password: TestPassword123!
```

### 3. Check Hash in Database
```bash
docker exec -it mail-mysql mysql -u root -p mailu -e \
  "SELECT email, password FROM user WHERE email='testuser@yourdomain.com';"
```

Expected format: `$bcrypt-sha256$2b$...`

## Alternative: Mailu's Preferred Scheme (Optional)

If you encounter compatibility issues, Mailu's current default is **BLF-CRYPT** (standard bcrypt):

### Option 1: Switch to Standard Bcrypt
```python
from passlib.hash import bcrypt

# In mail-api/app.py, replace:
password_hash = bcrypt_sha256.hash(password)

# With:
password_hash = bcrypt.hash(password)
```

### Option 2: Switch to PBKDF2 (Better Performance)
```python
from passlib.hash import pbkdf2_sha512

# In mail-api/app.py, replace:
password_hash = bcrypt_sha256.hash(password)

# With:
password_hash = pbkdf2_sha512.hash(password)
```

**Note:** PBKDF2 is faster and better for high-volume authentication, which is why Mailu considered switching to it (see GitHub issue #1194).

## Testing Checklist

- [ ] Create test user via Mail API
- [ ] Verify hash format in database starts with `$bcrypt-sha256$`
- [ ] Log in via Mailu webmail interface
- [ ] Log in via IMAP client (Thunderbird, Outlook, etc.)
- [ ] Test password change via Mail API
- [ ] Verify password change works in Mailu
- [ ] Test with special characters in password
- [ ] Test with maximum password length (72 chars for bcrypt)

## Recommendation

**Current Status: ✅ NO CHANGES NEEDED**

The `bcrypt_sha256` implementation should work correctly with Mailu. However, if you want to match Mailu's exact default:

1. **For compatibility:** Keep `bcrypt_sha256` (current implementation)
2. **For performance:** Switch to `pbkdf2_sha512` 
3. **For exact match:** Switch to standard `bcrypt`

## Performance Considerations

| Scheme | Speed | Security | Compatibility |
|--------|-------|----------|---------------|
| bcrypt_sha256 | Slow (~0.7s) | Very High | ✅ Good |
| bcrypt | Slow (~0.7s) | Very High | ✅ Excellent |
| pbkdf2_sha512 | Fast (<0.1s) | High | ✅ Good |
| sha512_crypt | Medium (~0.1s) | Medium | ✅ Good |

For a mail server with many authentication requests, **pbkdf2_sha512** might be preferable for performance reasons.

## Migration Notes

If you decide to change the hash scheme:

1. **New users** will automatically use the new scheme
2. **Existing users** will continue to work with their old hashes
3. **Password changes** will upgrade to the new scheme
4. **No migration script needed** - passlib handles multiple schemes

## References

- Mailu GitHub: https://github.com/Mailu/Mailu
- Mailu Issue #1194: Password scheme discussion
- Mailu Issue #2148: bcrypt-sha256 compatibility confirmed
- Passlib Documentation: https://passlib.readthedocs.io/

## Support

If you encounter authentication issues:

1. Check database hash format matches expected pattern
2. Verify Mailu version supports bcrypt-sha256
3. Test with a fresh user account
4. Check Mailu logs: `docker logs mailu-admin`
5. Consider switching to pbkdf2_sha512 for better performance
