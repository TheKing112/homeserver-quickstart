# PowerShell Mail Manager for Windows

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('add-domain','add-mailbox','list-mailboxes','add-alias','stats')]
    [string]$Action,
    
    [string]$ServerIP = "192.168.1.100",
    [string]$Domain,
    [string]$Email,
    [string]$Password,
    [int]$QuotaMB = 1000,
    [string]$Destination
)

$ErrorActionPreference = "Stop"

# Load .env
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

$API_TOKEN = $env:MAIL_API_TOKEN
$API_URL = "http://$ServerIP:5000/api"

if (-not $API_TOKEN) {
    Write-Host "ERROR MAIL_API_TOKEN not found in .env" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $API_TOKEN"
    "Content-Type" = "application/json"
}

Write-Host "DIR MAIL MANAGER" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    'add-domain' {
        Write-Host "Adding domain: $Domain" -ForegroundColor Yellow
        $body = @{ domain = $Domain } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$API_URL/domains" -Method Post -Headers $headers -Body $body
        Write-Host "OK Domain added: $Domain" -ForegroundColor Green
    }
    
    'add-mailbox' {
        Write-Host "Creating mailbox: $Email@$Domain" -ForegroundColor Yellow
        $body = @{
            email = $Email
            domain = $Domain
            password = $Password
            quota_bytes = $QuotaMB * 1048576
        } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$API_URL/mailboxes" -Method Post -Headers $headers -Body $body
        Write-Host "OK Mailbox created: $Email@$Domain" -ForegroundColor Green
        Write-Host "   Quota: $QuotaMB MB" -ForegroundColor Gray
    }
    
    'list-mailboxes' {
        Write-Host "Listing mailboxes..." -ForegroundColor Yellow
        $uri = "$API_URL/mailboxes"
        if ($Domain) { $uri += "?domain=$Domain" }
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        Write-Host ""
        $response.mailboxes | Format-Table -Property email, @{
            Label="Quota (MB)"; Expression={[math]::Round($_.quota_bytes / 1048576, 2)}
        }, @{
            Label="Used (MB)"; Expression={[math]::Round($_.quota_bytes_used / 1048576, 2)}
        }
    }
    
    'add-alias' {
        Write-Host "Creating alias: $Email@$Domain -> $Destination" -ForegroundColor Yellow
        $body = @{
            alias = $Email
            domain = $Domain
            destination = $Destination
        } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$API_URL/aliases" -Method Post -Headers $headers -Body $body
        Write-Host "OK Alias created" -ForegroundColor Green
    }
    
    'stats' {
        Write-Host "Fetching statistics..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$API_URL/stats" -Method Get -Headers $headers
        Write-Host ""
        Write-Host "STAT Mail Server Statistics" -ForegroundColor Cyan
        Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Cyan
        Write-Host "Domains:    $($response.domains)" -ForegroundColor White
        Write-Host "Mailboxes:  $($response.mailboxes)" -ForegroundColor White
        Write-Host "Aliases:    $($response.aliases)" -ForegroundColor White
        Write-Host "Total Quota: $($response.total_quota_gb) GB" -ForegroundColor White
        Write-Host "Used:       $($response.total_used_gb) GB ($($response.usage_percent)%)" -ForegroundColor White
    }
}

Write-Host ""