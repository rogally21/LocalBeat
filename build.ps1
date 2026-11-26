# fatto da Vuoler21
param([string]$Target = 'all')   # all | android | windows
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$app  = Join-Path $root 'build_app'
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null

if (-not (Test-Path $app)) {
  throw "ERRORE: esegui prima setup.ps1 / setup.bat"
}

Push-Location $app

if ($Target -in @('all', 'android')) {
  Write-Host "==> Build APK release..."
  flutter build apk --release --split-per-abi
  Copy-Item "build\app\outputs\flutter-apk\*-release.apk" $dist -Force
  Write-Host "==> APK copiati in $dist"
}

if ($Target -in @('all', 'windows')) {
  Write-Host "==> Build Windows release..."
  flutter build windows --release
  $win = Join-Path $dist 'LocalBeat-Windows'
  if (Test-Path $win) { Remove-Item $win -Recurse -Force }
  Copy-Item "build\windows\x64\runner\Release" $win -Recurse
  Write-Host "==> Windows build in $win"
}

Pop-Location
Write-Host "==> Fatto. Output in: $dist"
Get-ChildItem $dist
