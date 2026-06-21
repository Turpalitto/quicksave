Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$iconDir = Join-Path $root 'icons'
New-Item -ItemType Directory -Force -Path $iconDir | Out-Null
foreach ($size in @(16, 48, 128)) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $graphics = [System.Drawing.Graphics]::FromImage($bmp)
  $graphics.Clear([System.Drawing.Color]::FromArgb(103, 80, 164))
  $graphics.Dispose()
  $out = Join-Path $iconDir "icon$size.png"
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}
Write-Host "Icons written to $iconDir"
