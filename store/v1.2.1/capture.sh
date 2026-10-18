#!/usr/bin/env bash
# Recapture the Play store screenshots for every listing locale.
#
#   store/v1.2.1/capture.sh [device]        # default emulator-5554
#
# Each run rebuilds a debug APK, pumps the seeded fixture in that locale and writes
# screenshots/android/. The size/ribbon verifier must pass before anything is copied —
# a DEBUG ribbon or a wrong size is a rejected upload. The EN run is LAST on purpose:
# screenshots/android/ keeps the English set, which is what its README documents as
# canonical, while all three land in store/v1.2.1/screenshots/play/<locale>/.
set -euo pipefail

cd "$(dirname "$0")/../.."
DEVICE="${1:-emulator-5554}"

if ! adb -s "$DEVICE" get-state >/dev/null 2>&1; then
  echo "device $DEVICE is not online — start it: emulator -avd Pixel_10_Pro &" >&2
  exit 1
fi

for locale in fr es en; do
  echo "=== capturing $locale on $DEVICE"
  if ! flutter drive \
    --target=integration_test/screenshot_capture.dart \
    --driver=test_driver/screenshot_capture.driver.dart \
    -d "$DEVICE" \
    --dart-define="APP_LOCALE=$locale"; then
    # A locale that fails must not silently skip the ones after it: record it,
    # carry on, exit non-zero at the end.
    echo "!!! $locale capture FAILED" >&2
    failed="$failed $locale"
    continue
  fi
  /usr/bin/python3 screenshots/android/verify_android.py
  out="store/v1.2.1/screenshots/play/$locale"
  mkdir -p "$out"
  # NOT *.png alone: the pipeline leaves _debug_*.png artifacts in
  # screenshots/android/ that DO carry the DEBUG ribbon. A directory
  # dragged to Play Console with one of those in it is a rejected upload.
  rm -f "$out"/*.png
  for f in home history menu feeding_dialog sleep_diagram diaper_dialog health_diagram growth; do
    cp "screenshots/android/$f.png" "$out/"
  done
  echo "=== $locale → $out ($(ls "$out" | wc -l | tr -d ' ') png)"
done

if [ -n "${failed:-}" ]; then
  echo "FAILED locales:$failed — those slots have no 1.2.1 shots, do not upload the old ones" >&2
  exit 1
fi

echo
echo "iOS (App Store) is a separate pipeline — simulator, not emulator:"
echo "  flutter drive --target=lib/asc_driver_main.dart --driver=test_driver/asc_screenshots.dart \\"
echo "    -d 'iPhone 17' --dart-define=APP_LOCALE=fr          # then es, then en"
echo "  bash screenshots/ios/asc/postprocess.sh"
echo "  # copy the four size folders per locale into store/v1.2.1/screenshots/asc/<locale>/"
echo
python3 store/v1.2.1/check.py
