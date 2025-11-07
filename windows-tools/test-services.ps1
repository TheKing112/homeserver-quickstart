# Service Health Checker for Windows

param(
    [string]$ServerIP = "192.168.1.100"
)

$Services = @(
    @{Name="Dashboard"; URL="http://home.homeserver.local"},
    @{Name="Portainer"; URL="http://portainer.homeserver.local"},
    @{Name="Traefik"; URL="http://traefik.homeserver.local:8080"},
    @{Name="Vaultwarden"; URL="http://vault.homeserver.local"},
    @{Name="Gitea"; URL="http://git.homeserver.local"},
    @{Name="Code Server"; URL="http://code.homeserver.local"},
    @{Name="Grafana"; URL="http://grafana.homeserver.local"},
    @{Name="Netdata"; URL="http://netdata.homeserver.local"},
    @{Name="Webmail"; URL="http://mail.homeserver.local/webmail"},
    @{Name="Mail API"; URL="http://${ServerIP}:5000/health"}
)

Write-Host @"
+===========================================================+
|              HOMESERVER SERVICE TESTER                    |
+===========================================================+
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "Testing services on $ServerIP..." -ForegroundColor Yellow
Write-Host ""

$Results = @()

foreach ($Service in $Services) {
    Write-Host "Testing $($Service.Name)..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Service.URL -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host " OK OK" -ForegroundColor Green
            $Results += [PSCustomObject]@{
                Service = $Service.Name
                Status = "Online"
                Code = $response.StatusCode
            }
        } else {
            Write-Host " WARNING  Unexpected code: $($response.StatusCode)" -ForegroundColor Yellow
            $Results += [PSCustomObject]@{
                Service = $Service.Name
                Status = "Warning"
                Code = $response.StatusCode
            }
        }
    }
    catch {
        Write-Host " ERROR OFFLINE" -ForegroundColor Red
        $Results += [PSCustomObject]@{
            Service = $Service.Name
            Status = "Offline"
            Code = "-"
        }
    }
}

Write-Host ""
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”" -ForegroundColor Cyan
$Results | Format-Table -AutoSize
Write-Host ""

$Online = ($Results | Where-Object {$_.Status -eq "Online"}).Count
$Total = $Results.Count
$Percentage = [math]::Round(($Online / $Total) * 100, 2)

Write-Host "Services Online: $Online / $Total ($Percentage%)" -ForegroundColor $(
    if ($Percentage -eq 100) { "Green" }
    elseif ($Percentage -ge 80) { "Yellow" }
    else { "Red" }
)
Write-Host ""