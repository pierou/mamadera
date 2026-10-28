#!/usr/bin/env bash
# Recapture the store screenshots for every listing locale.
#
#   store/v<version>/capture.sh [device]              # Play, on the emulator
#   store/v<version>/capture.sh --asc-only            # App Store copies, from the simulator output
#
# NAME CONVENTION — the locale is part of the filename, not just the folder:
#
#     screenshots/play/fr/fr-home.png        asc/fr/1284x2778/fr-home.png
#
# Why: `screenshots/android/` and `screenshots/ios/asc/<size>/` are overwritten by
# every run and hold whichever language ran LAST, with no marker at all. A bare
# `home.png` is unidentifiable the moment it leaves its folder, and a French shot
# dropped into the English listing is indistinguishable from a correct one — in the
# console, in a zip, in a Finder window, and to the reviewer. `fr-home.png` says
# what it is wherever it lands. `check.py` fails the package on a bare name.
#
# Each Play run rebuilds a debug APK, pumps the seeded fixture in that locale and
# writes screenshots/android/ (bare names — that is what the driver emits and what
# verify_android.py checks). The verifier must pass before anything is copied: a
# DEBUG ribbon or a wrong size is a rejected upload. EN runs LAST so the canonical
# directory keeps the English set its README documents.
set -euo pipefail

cd "$(dirname "$0")/../.."
VERSION="${VERSION:-$(grep -m1 '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)}"
PKG="store/v${VERSION}"
# The eight uploadable Play screens. Order is the listing order; growth joined the set in
# v1.2.0 and must never be dropped from it.
SCREENS="home history menu feeding_dialog sleep_diagram diaper_dialog health_diagram growth"

copy_asc_locale() {
  local locale="$1" copied=0
  for size in 1242x2688 2688x1242 1284x2778 2778x1284; do
    local src="screenshots/ios/asc/$size"
    [ -d "$src" ] || continue
    local out="$PKG/screenshots/asc/$locale/$size"
    mkdir -p "$out"
    rm -f "$out"/*.png
    for f in "$src"/*.png; do
      [ -e "$f" ] || continue
      cp "$f" "$out/${locale}-$(basename "$f")"
      copied=$((copied + 1))
    done
    echo "=== asc ${locale} ${size} → ${out}"
  done
  if [ "$copied" = "0" ]; then
    echo "!!! no simulator output under screenshots/ios/asc/ — run the asc pipeline first:" >&2
    echo "    flutter drive --target=lib/asc_driver_main.dart --driver=test_driver/asc_screenshots.dart \\" >&2
    echo "      -d 'iPhone 17' --dart-define=APP_LOCALE=${locale}" >&2
    echo "    bash screenshots/ios/asc/postprocess.sh" >&2
    return 1
  fi
}

if [ "${1:-}" = "--asc-only" ]; then
  fail=0
  for locale in fr es en; do copy_asc_locale "$locale" || fail=1; done
  python3 "$PKG/check.py"
  exit $?
fi

DEVICE="${1:-emulator-5554}"
if ! adb -s "$DEVICE" get-state >/dev/null 2>&1; then
  echo "device $DEVICE is not online — start it: emulator -avd Pixel_10_Pro &" >&2
  exit 1
fi

failed=""
for locale in fr es en; do
  echo "=== capturing $locale on $DEVICE"
  if ! flutter drive \
    --target=integration_test/screenshot_capture.dart \
    --driver=test_driver/screenshot_capture.driver.dart \
    -d "$DEVICE" \
    --dart-define="APP_LOCALE=$locale"; then
    # A locale that fails must not silently skip the ones after it.
    echo "!!! $locale capture FAILED" >&2
    failed="$failed $locale"
    continue
  fi
  /usr/bin/python3 screenshots/android/verify_android.py
  out="$PKG/screenshots/play/$locale"
  mkdir -p "$out"
  rm -f "$out"/*.png
  # Copy with the locale prefix, and never *.png wholesale: _debug_*.png artifacts
  # sit in screenshots/android/ carrying the DEBUG ribbon.
  for f in $SCREENS; do
    cp "screenshots/android/$f.png" "$out/${locale}-${f}.png"
  done
  # Verify the UPLOAD set too, not just the raw capture: this is the copy that goes to
  # the console, and it is the one whose names must carry the locale.
  /usr/bin/python3 screenshots/android/verify_android.py --locale="$locale"
  echo "=== $locale → $out ($(ls "$out" | wc -l | tr -d ' ') png)"
done

if [ -n "$failed" ]; then
  echo "FAILED locales:$failed — those slots have no $VERSION shots, do not upload the old ones" >&2
  exit 1
fi

echo
echo "App Store shots come from the simulator, then copy them in locale-prefixed:"
echo "  flutter drive --target=lib/asc_driver_main.dart --driver=test_driver/asc_screenshots.dart \\"
echo "    -d 'iPhone 17' --dart-define=APP_LOCALE=fr          # then es, then en"
echo "  bash screenshots/ios/asc/postprocess.sh"
echo "  VERSION=$VERSION bash store/v$VERSION/capture.sh --asc-only"
echo
python3 "$PKG/check.py"
