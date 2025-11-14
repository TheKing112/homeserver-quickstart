#!/usr/bin/env python3
"""
Homeserver Mail Management API
RESTful API for managing Mailu mail server
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import mysql.connector
import mysql.connector.pooling
from passlib.hash import bcrypt_sha256
import os
from functools import wraps
import re
import secrets

app = Flask(__name__)

# Parse and trim CORS origins
ALLOWED_ORIGINS = [origin.strip() for origin in os.getenv('MAIL_API_ALLOWED_ORIGINS', 'http://localhost:3000,http://localhost').split(',')]
CORS(app, origins=ALLOWED_ORIGINS, supports_credentials=False)

# Configure rate limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://",
    strategy="fixed-window"
)

# Configuration
MYSQL_HOST = os.getenv('MAIL_MYSQL_HOST', 'mariadb')
MYSQL_USER = os.getenv('MAIL_MYSQL_USER', 'mailu_api')
MYSQL_PASSWORD = os.getenv('MAIL_MYSQL_PASSWORD')
MYSQL_DB = os.getenv('MAIL_MYSQL_DB', 'mailu')
API_TOKEN = os.getenv('MAIL_API_TOKEN')

# Validate required configuration at startup
if not API_TOKEN or API_TOKEN.strip() == '':
    raise RuntimeError('FATAL: MAIL_API_TOKEN environment variable must be set and not empty')

if not MYSQL_PASSWORD:
    raise RuntimeError('FATAL: MAIL_MYSQL_PASSWORD environment variable must be set')

# Input validation patterns
EMAIL_REGEX = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
DOMAIN_REGEX = re.compile(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
USERNAME_REGEX = re.compile(r'^[a-zA-Z0-9._%+-]+$')

def validate_email(email):
    """Validate email format"""
    return EMAIL_REGEX.match(email) is not None

def validate_domain(domain):
    """Validate domain format"""
    return DOMAIN_REGEX.match(domain) is not None

def validate_username(username):
    """Validate username format"""
    return USERNAME_REGEX.match(username) is not None

def validate_json_request():
    """Validate that request contains valid JSON"""
    if not request.is_json:
        return None, (jsonify({'error': 'Content-Type must be application/json'}), 400)
    
    try:
        data = request.get_json()
        if data is None:
            return None, (jsonify({'error': 'Invalid JSON body'}), 400)
        return data, None
    except Exception:
        return None, (jsonify({'error': 'Malformed JSON'}), 400)

def validate_quota(quota_bytes):
    """Validate quota value"""
    if not isinstance(quota_bytes, int):
        try:
            quota_bytes = int(quota_bytes)
        except (ValueError, TypeError):
            return None, 'Quota must be an integer'
    
    if quota_bytes < 0:
        return None, 'Quota cannot be negative'
    
    if quota_bytes > 10737418240:  # 10GB
        return None, 'Quota exceeds maximum allowed (10GB)'
    
    return quota_bytes, None

# Database connection pool
db_pool = mysql.connector.pooling.MySQLConnectionPool(
    pool_name="mail_api_pool",
    pool_size=10,
    host=MYSQL_HOST,
    user=MYSQL_USER,
    password=MYSQL_PASSWORD,
    database=MYSQL_DB
)

# Database connection
def get_db():
    return db_pool.get_connection()

# Authentication decorator
def require_api_token(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        expected_header = f'Bearer {API_TOKEN}'
        
        # Timing-safe comparison to prevent timing attacks
        if not auth_header or not secrets.compare_digest(auth_header, expected_header):
            return jsonify({'error': 'Unauthorized'}), 401
        return f(*args, **kwargs)
    return decorated_function

# ========================================
# HEALTH & INFO
# ========================================

@app.route('/health', methods=['GET'])
def health():
    """Simple health check endpoint - no authentication"""
    return jsonify({'status': 'healthy'}), 200

@app.route('/api/health/detailed', methods=['GET'])
@require_api_token
def health_detailed():
    """Detailed health check endpoint - requires authentication"""
    db = None
    try:
        db = get_db()
        db.close()
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'version': '1.0.0'
        }), 200
    except Exception as e:
        app.logger.error(f'Health check failed: {str(e)}')
        return jsonify({'status': 'unhealthy'}), 500
    finally:
        if db and db.is_connected():
            db.close()

@app.route('/api/info', methods=['GET'])
@require_api_token
def info():
    """Get API information"""
    return jsonify({
        'name': 'Homeserver Mail API',
        'version': '1.0.0',
        'endpoints': {
            'domains': '/api/domains',
            'mailboxes': '/api/mailboxes',
            'aliases': '/api/aliases',
            'stats': '/api/stats'
        }
    })

# ========================================
# DOMAINS
# ========================================

@app.route('/api/domains', methods=['GET'])
@require_api_token
@limiter.limit("30 per minute")
def get_domains():
    """List all domains"""
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT * FROM domain")
        domains = cursor.fetchall()
        return jsonify({'domains': domains}), 200
    except Exception as e:
        app.logger.error(f'Error fetching domains: {str(e)}')
        return jsonify({'error': 'Failed to fetch domains'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

@app.route('/api/domains', methods=['POST'])
@require_api_token
@limiter.limit("10 per minute")
def add_domain():
    """Add a new domain"""
    # Validate JSON request
    data, error = validate_json_request()
    if error:
        return error
    
    domain = data.get('domain', '').strip().lower()
    
    if not domain:
        return jsonify({'error': 'Domain required'}), 400
    
    if not validate_domain(domain):
        return jsonify({'error': 'Invalid domain format'}), 400
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO domain (name) VALUES (%s)",
            (domain,)
        )
        db.commit()
        return jsonify({
            'message': f'Domain {domain} added successfully',
            'domain': domain
        }), 201
    except mysql.connector.IntegrityError:
        return jsonify({'error': 'Domain already exists'}), 409
    except Exception as e:
        app.logger.error(f'Error adding domain: {str(e)}')
        return jsonify({'error': 'Failed to add domain'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

@app.route('/api/domains/<domain>', methods=['DELETE'])
@require_api_token
def delete_domain(domain):
    """Delete a domain"""
    # Validate domain parameter
    if not validate_domain(domain):
        return jsonify({'error': 'Invalid domain format'}), 400
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("DELETE FROM domain WHERE name = %s", (domain,))
        db.commit()
        
        if cursor.rowcount == 0:
            return jsonify({'error': 'Domain not found'}), 404
        
        return jsonify({'message': f'Domain {domain} deleted'}), 200
    except Exception as e:
        app.logger.error(f'Error deleting domain: {str(e)}')
        return jsonify({'error': 'Failed to delete domain'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

# ========================================
# MAILBOXES
# ========================================

@app.route('/api/mailboxes', methods=['GET'])
@require_api_token
def get_mailboxes():
    """List all mailboxes"""
    domain = request.args.get('domain')
    
    # Validate domain parameter if provided
    if domain and not validate_domain(domain):
        return jsonify({'error': 'Invalid domain format'}), 400
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        
        if domain:
            cursor.execute(
                "SELECT email, quota_bytes, quota_bytes_used FROM user WHERE email LIKE %s",
                (f'%@{domain}',)
            )
        else:
            cursor.execute("SELECT email, quota_bytes, quota_bytes_used FROM user")
        
        mailboxes = cursor.fetchall()
        return jsonify({'mailboxes': mailboxes}), 200
    except Exception as e:
        app.logger.error(f'Error fetching mailboxes: {str(e)}')
        return jsonify({'error': 'Failed to fetch mailboxes'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

@app.route('/api/mailboxes', methods=['POST'])
@require_api_token
@limiter.limit("10 per minute")
def add_mailbox():
    """Create a new mailbox"""
    # Validate JSON request
    data, error = validate_json_request()
    if error:
        return error
    
    email = data.get('email', '').strip().lower()
    domain = data.get('domain', '').strip().lower()
    password = data.get('password', '').strip()
    quota_bytes = data.get('quota_bytes', 1000000000)
    
    if not all([email, domain, password]):
        return jsonify({'error': 'Email, domain, and password required'}), 400
    
    if not validate_username(email):
        return jsonify({'error': 'Invalid email username format'}), 400
    
    if not validate_domain(domain):
        return jsonify({'error': 'Invalid domain format'}), 400
    
    if len(password) < 8:
        return jsonify({'error': 'Password must be at least 8 characters'}), 400
    
    full_email = f"{email}@{domain}"
    
    if not validate_email(full_email):
        return jsonify({'error': 'Invalid email format'}), 400
    
    # Validate quota
    quota_bytes, quota_error = validate_quota(quota_bytes)
    if quota_error:
        return jsonify({'error': quota_error}), 400
    
    password_hash = bcrypt_sha256.hash(password)
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            """INSERT INTO user (email, password, quota_bytes, enabled)
               VALUES (%s, %s, %s, 1)""",
            (full_email, password_hash, quota_bytes)
        )
        db.commit()
        return jsonify({
            'message': f'Mailbox {full_email} created',
            'email': full_email,
            'quota_mb': quota_bytes / 1048576
        }), 201
    except mysql.connector.IntegrityError:
        return jsonify({'error': 'Mailbox already exists'}), 409
    except Exception as e:
        app.logger.error(f'Error creating mailbox: {str(e)}')
        return jsonify({'error': 'Failed to create mailbox'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

@app.route('/api/mailboxes/<email>', methods=['DELETE'])
@require_api_token
def delete_mailbox(email):
    """Delete a mailbox"""
    # Validate email parameter
    if not validate_email(email):
        return jsonify({'error': 'Invalid email format'}), 400
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("DELETE FROM user WHERE email = %s", (email,))
        db.commit()
        
        if cursor.rowcount == 0:
            return jsonify({'error': 'Mailbox not found'}), 404
        
        return jsonify({'message': f'Mailbox {email} deleted'}), 200
    except Exception as e:
        app.logger.error(f'Error deleting mailbox: {str(e)}')
        return jsonify({'error': 'Failed to delete mailbox'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

@app.route('/api/mailboxes/<email>/password', methods=['PUT'])
@require_api_token
@limiter.limit("5 per minute")
def change_password(email):
    """Change mailbox password"""
    # Validate email parameter
    if not validate_email(email):
        return jsonify({'error': 'Invalid email format'}), 400
    
    # Validate JSON request
    data, error = validate_json_request()
    if error:
        return error
    
    new_password = data.get('password', '').strip()
    
    if not new_password:
        return jsonify({'error': 'Password required'}), 400
    
    if len(new_password) < 8:
        return jsonify({'error': 'Password must be at least 8 characters'}), 400
    
    password_hash = bcrypt_sha256.hash(new_password)
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "UPDATE user SET password = %s WHERE email = %s",
            (password_hash, email)
        )
        db.commit()
        
        if cursor.rowcount == 0:
            return jsonify({'error': 'Mailbox not found'}), 404
        
        return jsonify({'message': f'Password changed for {email}'}), 200
    except Exception as e:
        app.logger.error(f'Error changing password: {str(e)}')
        return jsonify({'error': 'Failed to change password'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

# ========================================
# ALIASES
# ========================================

@app.route('/api/aliases', methods=['GET'])
@require_api_token
def get_aliases():
    """List all aliases"""
    domain = request.args.get('domain')
    
    # Validate domain parameter if provided
    if domain and not validate_domain(domain):
        return jsonify({'error': 'Invalid domain format'}), 400
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        
        if domain:
            cursor.execute(
                "SELECT * FROM alias WHERE email LIKE %s",
                (f'%@{domain}',)
            )
        else:
            cursor.execute("SELECT * FROM alias")
        
        aliases = cursor.fetchall()
        return jsonify({'aliases': aliases}), 200
    except Exception as e:
        app.logger.error(f'Error fetching aliases: {str(e)}')
        return jsonify({'error': 'Failed to fetch aliases'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

@app.route('/api/aliases', methods=['POST'])
@require_api_token
def add_alias():
    """Create an alias"""
    # Validate JSON request
    data, error = validate_json_request()
    if error:
        return error
    
    alias = data.get('alias', '').strip().lower()
    domain = data.get('domain', '').strip().lower()
    destination = data.get('destination', '').strip().lower()
    
    if not all([alias, domain, destination]):
        return jsonify({'error': 'Alias, domain, and destination required'}), 400
    
    if not validate_username(alias):
        return jsonify({'error': 'Invalid alias username format'}), 400
    
    if not validate_domain(domain):
        return jsonify({'error': 'Invalid domain format'}), 400
    
    full_alias = f"{alias}@{domain}"
    
    if not validate_email(full_alias):
        return jsonify({'error': 'Invalid alias email format'}), 400
    
    if not validate_email(destination):
        return jsonify({'error': 'Invalid destination email format'}), 400
    
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO alias (email, destination) VALUES (%s, %s)",
            (full_alias, destination)
        )
        db.commit()
        return jsonify({
            'message': f'Alias {full_alias} -> {destination} created',
            'alias': full_alias,
            'destination': destination
        }), 201
    except mysql.connector.IntegrityError:
        return jsonify({'error': 'Alias already exists'}), 409
    except Exception as e:
        app.logger.error(f'Error creating alias: {str(e)}')
        return jsonify({'error': 'Failed to create alias'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

# ========================================
# STATISTICS
# ========================================

@app.route('/api/stats', methods=['GET'])
@require_api_token
def get_stats():
    """Get mail server statistics"""
    db = None
    cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM domain")
        domain_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM user")
        mailbox_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM alias")
        alias_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT SUM(quota_bytes), SUM(quota_bytes_used) FROM user")
        total_quota, total_used = cursor.fetchone()
        
        return jsonify({
            'domains': domain_count,
            'mailboxes': mailbox_count,
            'aliases': alias_count,
            'total_quota_gb': round((total_quota or 0) / 1073741824, 2),
            'total_used_gb': round((total_used or 0) / 1073741824, 2),
            'usage_percent': round(((total_used or 0) / (total_quota or 1)) * 100, 2)
        }), 200
    except Exception as e:
        app.logger.error(f'Error fetching stats: {str(e)}')
        return jsonify({'error': 'Failed to fetch statistics'}), 500
    finally:
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

# ========================================
# ERROR HANDLERS
# ========================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

# ========================================
# MAIN
# ========================================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)