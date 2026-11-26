# fatto da Vuoler21
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$app  = Join-Path $root 'build_app'

Write-Host "==> Root: $root"
Write-Host "==> Flutter version:"
flutter --version

foreach ($d in @('lib', 'assets', 'android_patch')) {
  if (-not (Test-Path (Join-Path $root $d))) {
    throw "ERRORE: manca la cartella $d/"
  }
}
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
  throw "ERRORE: manca pubspec.yaml"
}

if (-not (Test-Path $app)) {
  Write-Host "==> Creo progetto Flutter (android + windows)..."
  flutter create --platforms=android,windows --org com.vuoler21 --project-name localbeat $app
}

Write-Host "==> Copio lib, assets e pubspec..."
$libDest = Join-Path $app 'lib'
$assetsDest = Join-Path $app 'assets'
if (Test-Path $libDest) { Remove-Item $libDest -Recurse -Force }
if (Test-Path $assetsDest) { Remove-Item $assetsDest -Recurse -Force }
Copy-Item (Join-Path $root 'lib')    $libDest -Recurse -Force
Copy-Item (Join-Path $root 'assets') $assetsDest -Recurse -Force
Copy-Item (Join-Path $root 'pubspec.yaml') (Join-Path $app 'pubspec.yaml') -Force

$kt = Join-Path $app 'android\app\src\main\kotlin\com\vuoler21\localbeat'
New-Item -ItemType Directory -Force $kt | Out-Null
Copy-Item (Join-Path $root 'android_patch\MainActivity.kt') (Join-Path $kt 'MainActivity.kt') -Force
Write-Host "==> MainActivity.kt copiato"

$mf = Join-Path $app 'android\app\src\main\AndroidManifest.xml'
$x  = Get-Content $mf -Raw -Encoding UTF8
if ($x -notmatch 'READ_MEDIA_AUDIO') {
  Write-Host "==> Patch AndroidManifest.xml..."
  $perm = (Get-Content (Join-Path $root 'android_patch\permissions.xml') -Raw -Encoding UTF8).TrimEnd()
  $svc  = (Get-Content (Join-Path $root 'android_patch\service.xml') -Raw -Encoding UTF8).TrimEnd()
  $x = $x.Replace('<application', $perm + "`r`n    <application")
  $x = $x.Replace('</application>', $svc + "`r`n    </application>")
  Set-Content $mf $x -Encoding UTF8 -NoNewline
}

foreach ($g in @('build.gradle', 'build.gradle.kts')) {
  $f = Join-Path $app "android\app\$g"
  if (Test-Path $f) {
    Write-Host "==> Aggiorno minSdk in $g..."
    $content = Get-Content $f -Raw -Encoding UTF8
    $content = $content -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24'
    $content = $content -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24'
    Set-Content $f $content -Encoding UTF8 -NoNewline
  }
}

Push-Location $app
Write-Host "==> flutter pub get..."
flutter pub get
Write-Host "==> Genero icone..."
try { dart run flutter_launcher_icons } catch { Write-Host "Icone: skip ($($_.Exception.Message))" }
Pop-Location

Write-Host "==> Setup completato."
