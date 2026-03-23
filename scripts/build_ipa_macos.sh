#!/usr/bin/env bash
# Сборка release IPA на macOS (аналог: flutter build apk --release на Windows).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Этот скрипт рассчитан на macOS. На Windows IPA не собрать — см. docs/build_ios_ipa.md"
  exit 1
fi

command -v flutter >/dev/null 2>&1 || { echo "Flutter не найден в PATH"; exit 1; }

flutter pub get
( cd ios && pod install )
flutter build ipa --release

echo ""
echo "Готово. IPA: $ROOT/build/ios/ipa/"
