# PowerShell Secrets Generator for Windows

$ErrorActionPreference = "Stop"

Write-Host @"
+===========================================================+
|           TOOLS HOMESERVER SECRETS GENERATOR                 |
+===========================================================+
"@ -ForegroundColor Cyan

Write-Host ""

function New-RandomPassword {
    param([int]$Length = 32)
    $bytes = New-Object Byte[] $Length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    return [Convert]::ToBase64String($bytes).Substring(0, $Length) -replace '[+/=]', ''
}

function New-RandomToken {
    param([int]$Length = 64)
    $bytes = New-Object Byte[] ($Length / 2)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    return [BitConverter]::ToString($bytes).Replace("-", "").ToLower()
}

if (Test-Path ".env") {
    Write-Host "WARNING  .env file already exists!" -ForegroundColor Yellow
    $confirm = Read-Host "Overwrite? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Red
        exit
    }
}

Write-Host "Generating secure secrets..." -ForegroundColor Cyan
Write-Host ""

$Config = @{
    POSTGRES_PASSWORD = New-RandomPassword 32
    MYSQL_ROOT_PASSWORD = New-RandomPassword 32
    MYSQL_PASSWORD = New-RandomPassword 32
    REDIS_PASSWORD = New-RandomPassword 32
    MAIL_SECRET_KEY = New-RandomToken 32
    MAIL_MYSQL_ROOT_PASSWORD = New-RandomPassword 32
    MAIL_MYSQL_PASSWORD = New-RandomPassword 32
    MAIL_API_TOKEN = New-RandomToken 64
    DRONE_RPC_SECRET = New-RandomToken 32
    CODE_SERVER_PASSWORD = New-RandomPassword 24
    GRAFANA_ADMIN_PASSWORD = New-RandomPassword 24
    RESTIC_PASSWORD = New-RandomPassword 32
    VAULTWARDEN_ADMIN_TOKEN = New-RandomToken 64
}

$EnvContent = @"
# ================================
# HOMESERVER CONFIGURATION
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# ================================

# Project
COMPOSE_PROJECT_NAME=homeserver
TZ=Europe/Berlin

# Network
SERVER_IP=192.168.1.100

# ================================
# DATABASE PASSWORDS
# ================================
POSTGRES_USER=admin
POSTGRES_PASSWORD=$($Config.POSTGRES_PASSWORD)
POSTGRES_DB=homeserver

MYSQL_ROOT_PASSWORD=$($Config.MYSQL_ROOT_PASSWORD)
MYSQL_DATABASE=homeserver
MYSQL_USER=admin
MYSQL_PASSWORD=$($Config.MYSQL_PASSWORD)

REDIS_PASSWORD=$($Config.REDIS_PASSWORD)

# ================================
# MAIL SERVER
# ================================
MAIL_PRIMARY_DOMAIN=homeserver.local
MAIL_DOMAINS=homeserver.local
MAIL_SECRET_KEY=$($Config.MAIL_SECRET_KEY)
MAIL_MYSQL_ROOT_PASSWORD=$($Config.MAIL_MYSQL_ROOT_PASSWORD)
MAIL_MYSQL_PASSWORD=$($Config.MAIL_MYSQL_PASSWORD)
MAIL_API_TOKEN=$($Config.MAIL_API_TOKEN)

# Email notifications (CONFIGURE THIS!)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-gmail-app-password

# ================================
# DEVELOPMENT TOOLS
# ================================
GITEA_OAUTH_CLIENT_ID=
GITEA_OAUTH_CLIENT_SECRET=

DRONE_RPC_SECRET=$($Config.DRONE_RPC_SECRET)
CODE_SERVER_PASSWORD=$($Config.CODE_SERVER_PASSWORD)

# ================================
# MONITORING
# ================================
GRAFANA_ADMIN_PASSWORD=$($Config.GRAFANA_ADMIN_PASSWORD)

# ================================
# BACKUP
# ================================
RESTIC_PASSWORD=$($Config.RESTIC_PASSWORD)
BACKUP_SCHEDULE=0 2 * * *

# ================================
# SECURITY
# ================================
VAULTWARDEN_ADMIN_TOKEN=$($Config.VAULTWARDEN_ADMIN_TOKEN)
"@

$EnvContent | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline

Write-Host "OK Secrets generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Cyan
Write-Host "DIR IMPORTANT PASSWORDS (save to password manager!)" -ForegroundColor Yellow
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Cyan
Write-Host ""
Write-Host "Databases:" -ForegroundColor Yellow
Write-Host "  PostgreSQL: $($Config.POSTGRES_PASSWORD)"
Write-Host "  MySQL Root: $($Config.MYSQL_ROOT_PASSWORD)"
Write-Host "  Redis:      $($Config.REDIS_PASSWORD)"
Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  Code Server: $($Config.CODE_SERVER_PASSWORD)"
Write-Host "  Grafana:     $($Config.GRAFANA_ADMIN_PASSWORD)"
Write-Host "  Mail API:    $($Config.MAIL_API_TOKEN)"
Write-Host ""
Write-Host "Backup:" -ForegroundColor Yellow
Write-Host "  Restic: $($Config.RESTIC_PASSWORD)"
Write-Host ""
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING  NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Edit .env and configure:" -ForegroundColor Green
Write-Host "   - SMTP_USER and SMTP_PASSWORD"
Write-Host "   - MAIL_DOMAINS (your real domains)"
Write-Host "   - SERVER_IP (if different)"
Write-Host ""
Write-Host "2. Save all passwords to your password manager" -ForegroundColor Green
Write-Host ""
Write-Host "3. Ready to install!" -ForegroundColor Green
Write-Host ""