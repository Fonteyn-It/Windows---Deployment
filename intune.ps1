# 1. Set Execution Policy for this session
Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. Install Get-WindowsAutopilotInfo if not present
if (-not (Get-Command -Name Get-WindowsAutoPilotInfo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Microsoft Autopilot script..."
    Install-Script -Name Get-WindowsAutoPilotInfo -Force -Scope CurrentUser
}

# 3. Run the script to collect and upload hash (requires login)
Write-Host "Uploading device hash to Intune with Order ID: fonteyn..."
Get-WindowsAutoPilotInfo -Online -OrderIdentifier "fonteyn"

# 4. Prompt restart
Write-Host "`n✅ Upload complete. Restarting workstation..."
Start-Sleep -Seconds 5
Restart-Computer -Force
