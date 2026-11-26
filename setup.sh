#!/usr/bin/env bash
# fatto da Vuoler21
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build_app"

echo "==> Root: $ROOT"
echo "==> Flutter version:"
flutter --version

for d in lib assets android_patch; do
  if [ ! -d "$ROOT/$d" ]; then
    echo "ERRORE: manca la cartella $d/"
    exit 1
  fi
done

if [ ! -f "$ROOT/pubspec.yaml" ]; then
  echo "ERRORE: manca pubspec.yaml"
  exit 1
fi

if [ ! -d "$APP" ]; then
  echo "==> Creo progetto Flutter (android + windows)..."
  flutter create --platforms=android,windows --org com.vuoler21 --project-name localbeat "$APP"
fi

echo "==> Copio lib, assets e pubspec..."
rm -rf "$APP/lib" "$APP/assets"
cp -r "$ROOT/lib" "$APP/lib"
cp -r "$ROOT/assets" "$APP/assets"
cp "$ROOT/pubspec.yaml" "$APP/pubspec.yaml"

KT_DIR="$APP/android/app/src/main/kotlin/com/vuoler21/localbeat"
mkdir -p "$KT_DIR"
cp "$ROOT/android_patch/MainActivity.kt" "$KT_DIR/MainActivity.kt"
echo "==> MainActivity.kt copiato"

MF="$APP/android/app/src/main/AndroidManifest.xml"
if [ -f "$MF" ] && ! grep -q "READ_MEDIA_AUDIO" "$MF"; then
  echo "==> Patch AndroidManifest.xml..."
  python3 - "$MF" "$ROOT/android_patch" <<'PY'
import sys
mf_path, patch_dir = sys.argv[1], sys.argv[2]
text = open(mf_path, encoding="utf-8").read()
perms = open(f"{patch_dir}/permissions.xml", encoding="utf-8").read().rstrip()
service = open(f"{patch_dir}/service.xml", encoding="utf-8").read().rstrip()
text = text.replace("<application", perms + "\n    <application", 1)
text = text.replace("</application>", service + "\n    </application>", 1)
open(mf_path, "w", encoding="utf-8").write(text)
print("AndroidManifest patchato")
PY
fi

for f in "$APP/android/app/build.gradle" "$APP/android/app/build.gradle.kts"; do
  if [ -f "$f" ]; then
    echo "==> Aggiorno minSdk in $(basename "$f")..."
    sed -i -E \
      -e 's/minSdk(Version)?[[:space:]]*=?[[:space:]]*flutter\.minSdkVersion/minSdk = 24/' \
      -e 's/minSdkVersion[[:space:]]+flutter\.minSdkVersion/minSdkVersion 24/' \
      "$f"
  fi
done

echo "==> flutter pub get..."
cd "$APP"
flutter pub get

echo "==> Genero icone..."
dart run flutter_launcher_icons || true

echo "==> Setup completato."
