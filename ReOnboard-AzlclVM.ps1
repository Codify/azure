# MOC Guest Agent reset script
# For Hyper-V Generation 2 VMs only

Write-Host "Stopping MOC Guest Agent service..." -ForegroundColor Cyan

try {
    Stop-Service -Name "mocguestagent" -Force -ErrorAction Stop
    Write-Host "Service stopped."
}
catch {
    Write-Warning "Service not running or failed to stop."
}

Write-Host "Deleting service..." -ForegroundColor Cyan
sc.exe delete "MOCGuestAgent" | Out-Null
Start-Sleep -Seconds 2

# Remove agent folder
$folderPath = "C:\ProgramData\mocguestagent"
if (Test-Path $folderPath) {
    Write-Host "Removing folder $folderPath..." -ForegroundColor Cyan
    Remove-Item -Path $folderPath -Recurse -Force
}
else {
    Write-Warning "Folder not found."
}

# Remove event log key
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\mocguestagent"

if (Test-Path $regPath) {
    Write-Host "Removing registry key..." -ForegroundColor Cyan
    Remove-Item -Path $regPath -Recurse -Force
}
else {
    Write-Warning "Registry key not found."
}

Write-Host ""
Write-Host "============================================"
Write-Host "MANUAL STEP REQUIRED"
Write-Host "Mount mocguestagentprov.iso from ClusterStorage to this VM."
Write-Host "Press any key once mounted to continue..."
Write-Host "============================================"
Pause

# Run installer from mounted ISO
$d = Get-Volume -FileSystemLabel mocguestagentprov
$p = Join-Path ($d.DriveLetter + ':\') 'install.ps1'
powershell $p
# Wait before status check
Start-Sleep -Seconds 5

# Check service status
Write-Host "Checking service status..." -ForegroundColor Cyan
$svc = Get-Service -Name "mocguestagent" -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "Service Status: $($svc.Status)" -ForegroundColor Green
}
else {
    Write-Warning "Service not found after install."
}

# Show final CLI command
$hostname = $env:COMPUTERNAME
Write-Host ""
Write-Host "============================================"
Write-Host "NEXT STEP (Run manually):" -ForegroundColor Yellow
Write-Host "az stack-hci-vm update --name `"$hostname`" --enable-agent true --resource-group `"<rgName>`""
Write-Host "============================================"

# Final exit prompt
Write-Host ""
Write-Host "Script complete. Press any key to exit..." -ForegroundColor Cyan
Pause
