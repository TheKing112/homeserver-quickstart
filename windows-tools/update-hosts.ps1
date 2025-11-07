# Update Windows Hosts File (Run as Administrator!)

#Requires -RunAsAdministrator

param(
    [string]$ServerIP = "192.168.1.100"
)

$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$Marker = "# Homeserver entries"

$Entries = @"

$Marker
$ServerIP homeserver.local home.homeserver.local
$ServerIP portainer.homeserver.local traefik.homeserver.local
$ServerIP vault.homeserver.local git.homeserver.local
$ServerIP code.homeserver.local db.homeserver.local
$ServerIP grafana.homeserver.local netdata.homeserver.local
$ServerIP prometheus.homeserver.local mail.homeserver.local
$ServerIP drone.homeserver.local registry.homeserver.local
$ServerIP registry-ui.homeserver.local mcp.homeserver.local
$ServerIP mcp-fs.homeserver.local mcp-docker.homeserver.local
$ServerIP mcp-db.homeserver.local mcp-http.homeserver.local
$ServerIP redis.homeserver.local www.homeserver.local
"@

Write-Host "DIR Updating Windows hosts file..." -ForegroundColor Cyan
Write-Host ""

# Backup
$BackupPath = "$HostsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $HostsPath $BackupPath
Write-Host "OK Backup created: $BackupPath" -ForegroundColor Green

# Remove old entries
$HostsContent = Get-Content $HostsPath
$NewContent = $HostsContent | Where-Object { $_ -notmatch "homeserver.local" }

# Add new entries
$NewContent += $Entries

# Write back
$NewContent | Out-File -FilePath $HostsPath -Encoding ASCII

Write-Host "OK Hosts file updated!" -ForegroundColor Green
Write-Host ""
Write-Host "Added entries for:" -ForegroundColor Yellow
Write-Host "  - Dashboard, Portainer, Traefik"
Write-Host "  - Development tools (Gitea, Drone, Code Server)"
Write-Host "  - Databases, Monitoring, Mail"
Write-Host "  - MCP servers"
Write-Host ""
Write-Host "You can now access services at http://home.homeserver.local" -ForegroundColor Green
Write-Host ""