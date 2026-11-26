#!/usr/bin/env bash
# fatto da Vuoler21
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build_app"
DIST="$ROOT/dist"
mkdir -p "$DIST"

if [ ! -d "$APP" ]; then
  echo "ERRORE: esegui prima setup.sh"
  exit 1
fi

cd "$APP"
echo "==> Build APK release (split per ABI)..."
flutter build apk --release --split-per-abi

echo "==> Copio APK in dist/..."
cp -v build/app/outputs/flutter-apk/*-release.apk "$DIST/"

echo "==> APK pronti in $DIST"
ls -la "$DIST"
