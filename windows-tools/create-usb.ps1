# USB Bootable Creator Helper for Windows

param(
    [string]$IsoPath,
    [string]$UsbDrive
)

Write-Host @"
+===========================================================+
|           USB BOOTABLE INSTALLER CREATOR                  |
+===========================================================+
"@ -ForegroundColor Cyan

Write-Host ""

if (-not $IsoPath) {
    Write-Host "DIR Download Ubuntu Server 24.04 LTS ISO from:" -ForegroundColor Yellow
    Write-Host "   https://ubuntu.com/download/server" -ForegroundColor Cyan
    Write-Host ""
    $IsoPath = Read-Host "Enter path to ISO file"
}

if (-not (Test-Path $IsoPath)) {
    Write-Host "ERROR ISO file not found: $IsoPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Available drives:" -ForegroundColor Yellow
Get-Volume | Where-Object {$_.DriveType -eq 'Removable'} | Format-Table -Property DriveLetter, FileSystemLabel, Size

if (-not $UsbDrive) {
    $UsbDrive = Read-Host "Enter USB drive letter (e.g., D)"
}

Write-Host ""
Write-Host "WARNING  WARNING: This will ERASE all data on drive $UsbDrive!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "DIR INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Download and install Rufus:" -ForegroundColor White
Write-Host "   https://rufus.ie" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Run Rufus with these settings:" -ForegroundColor White
Write-Host "   â€¢ Device: $UsbDrive" -ForegroundColor Gray
Write-Host "   â€¢ Boot selection: $IsoPath" -ForegroundColor Gray
Write-Host "   â€¢ Partition scheme: GPT" -ForegroundColor Gray
Write-Host "   â€¢ Target system: UEFI" -ForegroundColor Gray
Write-Host "   â€¢ Click START" -ForegroundColor Gray
Write-Host ""
Write-Host "3. After Rufus completes:" -ForegroundColor White
Write-Host "   â€¢ Copy 'autoinstall' folder to USB root" -ForegroundColor Gray
Write-Host "   â€¢ Rename folder to 'nocloud-ubuntu'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Boot server from USB!" -ForegroundColor White
Write-Host ""
Write-Host "Alternative: Use Etcher (https://etcher.balena.io)" -ForegroundColor Yellow
Write-Host ""