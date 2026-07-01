# Run as Administrator: right-click PowerShell -> Run as administrator
New-NetFirewallRule -DisplayName "QuickSave Backend TCP 3000" `
  -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
Write-Host "Firewall rule added. Test from phone browser: http://192.168.1.248:3000/health"
