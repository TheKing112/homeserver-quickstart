#!/usr/bin/env python3
"""
Homeserver Mail Management API
RESTful API for managing Mailu mail server
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from passlib.hash import bcrypt_sha256
import os
import requests
from functools import wraps

app = Flask(__name__)
CORS(app)

# Configuration
MYSQL_HOST = os.getenv('MAIL_MYSQL_HOST', 'mail-mysql')
MYSQL_USER = os.getenv('MAIL_MYSQL_USER', 'root')
MYSQL_PASSWORD = os.getenv('MAIL_MYSQL_ROOT_PASSWORD')
MYSQL_DB = os.getenv('MAIL_MYSQL_DB', 'mailu')
API_TOKEN = os.getenv('MAIL_API_TOKEN')
MAILU_ADMIN_URL = os.getenv('MAILU_ADMIN_URL', 'http://mail-admin:80')

# Database connection
def get_db():
    return mysql.connector.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DB
    )

# Authentication decorator
def require_api_token(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token or token != f'Bearer {API_TOKEN}':
            return jsonify({'error': 'Unauthorized'}), 401
        return f(*args, **kwargs)
    return decorated_function

# ========================================
# HEALTH & INFO
# ========================================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        db = get_db()
        db.close()
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'version': '1.0.0'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

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
def get_domains():
    """List all domains"""
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT * FROM domain")
        domains = cursor.fetchall()
        db.close()
        return jsonify({'domains': domains}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/domains', methods=['POST'])
@require_api_token
def add_domain():
    """Add a new domain"""
    data = request.get_json()
    domain = data.get('domain')
    
    if not domain:
        return jsonify({'error': 'Domain required'}), 400
    
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO domain (name) VALUES (%s)",
            (domain,)
        )
        db.commit()
        db.close()
        return jsonify({
            'message': f'Domain {domain} added successfully',
            'domain': domain
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/domains/<domain>', methods=['DELETE'])
@require_api_token
def delete_domain(domain):
    """Delete a domain"""
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("DELETE FROM domain WHERE name = %s", (domain,))
        db.commit()
        db.close()
        return jsonify({'message': f'Domain {domain} deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========================================
# MAILBOXES
# ========================================

@app.route('/api/mailboxes', methods=['GET'])
@require_api_token
def get_mailboxes():
    """List all mailboxes"""
    domain = request.args.get('domain')
    
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
        db.close()
        return jsonify({'mailboxes': mailboxes}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mailboxes', methods=['POST'])
@require_api_token
def add_mailbox():
    """Create a new mailbox"""
    data = request.get_json()
    email = data.get('email')
    domain = data.get('domain')
    password = data.get('password')
    quota_bytes = data.get('quota_bytes', 1000000000)  # Default 1GB
    
    if not all([email, domain, password]):
        return jsonify({'error': 'Email, domain, and password required'}), 400
    
    full_email = f"{email}@{domain}"
    password_hash = bcrypt_sha256.hash(password)
    
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            """INSERT INTO user (email, password, quota_bytes, enabled)
               VALUES (%s, %s, %s, 1)""",
            (full_email, password_hash, quota_bytes)
        )
        db.commit()
        db.close()
        return jsonify({
            'message': f'Mailbox {full_email} created',
            'email': full_email,
            'quota_mb': quota_bytes / 1048576
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mailboxes/<email>', methods=['DELETE'])
@require_api_token
def delete_mailbox(email):
    """Delete a mailbox"""
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("DELETE FROM user WHERE email = %s", (email,))
        db.commit()
        db.close()
        return jsonify({'message': f'Mailbox {email} deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mailboxes/<email>/password', methods=['PUT'])
@require_api_token
def change_password(email):
    """Change mailbox password"""
    data = request.get_json()
    new_password = data.get('password')
    
    if not new_password:
        return jsonify({'error': 'Password required'}), 400
    
    password_hash = bcrypt_sha256.hash(new_password)
    
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "UPDATE user SET password = %s WHERE email = %s",
            (password_hash, email)
        )
        db.commit()
        db.close()
        return jsonify({'message': f'Password changed for {email}'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========================================
# ALIASES
# ========================================

@app.route('/api/aliases', methods=['GET'])
@require_api_token
def get_aliases():
    """List all aliases"""
    domain = request.args.get('domain')
    
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
        db.close()
        return jsonify({'aliases': aliases}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/aliases', methods=['POST'])
@require_api_token
def add_alias():
    """Create an alias"""
    data = request.get_json()
    alias = data.get('alias')
    domain = data.get('domain')
    destination = data.get('destination')
    
    if not all([alias, domain, destination]):
        return jsonify({'error': 'Alias, domain, and destination required'}), 400
    
    full_alias = f"{alias}@{domain}"
    
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO alias (email, destination) VALUES (%s, %s)",
            (full_alias, destination)
        )
        db.commit()
        db.close()
        return jsonify({
            'message': f'Alias {full_alias} -> {destination} created',
            'alias': full_alias,
            'destination': destination
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========================================
# STATISTICS
# ========================================

@app.route('/api/stats', methods=['GET'])
@require_api_token
def get_stats():
    """Get mail server statistics"""
    try:
        db = get_db()
        cursor = db.cursor()
        
        # Count domains
        cursor.execute("SELECT COUNT(*) FROM domain")
        domain_count = cursor.fetchone()[0]
        
        # Count mailboxes
        cursor.execute("SELECT COUNT(*) FROM user")
        mailbox_count = cursor.fetchone()[0]
        
        # Count aliases
        cursor.execute("SELECT COUNT(*) FROM alias")
        alias_count = cursor.fetchone()[0]
        
        # Total quota
        cursor.execute("SELECT SUM(quota_bytes), SUM(quota_bytes_used) FROM user")
        total_quota, total_used = cursor.fetchone()
        
        db.close()
        
        return jsonify({
            'domains': domain_count,
            'mailboxes': mailbox_count,
            'aliases': alias_count,
            'total_quota_gb': round((total_quota or 0) / 1073741824, 2),
            'total_used_gb': round((total_used or 0) / 1073741824, 2),
            'usage_percent': round(((total_used or 0) / (total_quota or 1)) * 100, 2)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

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