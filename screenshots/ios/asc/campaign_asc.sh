#!/usr/bin/env bash
# App Store screenshot campaign: one `flutter drive` per listing locale, then
# postprocess, then copy — **interleaved**, because every stage of this pipeline
# overwrites the previous run in place.
#
#   bash screenshots/ios/asc/campaign_asc.sh [fr es en]
#   VERSION=1.3.1 bash screenshots/ios/asc/campaign_asc.sh
#
# Why this script exists (both failure modes measured 2026-11-01):
#
# 1. `--dart-define` reaches the app, NOT the driver script. The asc driver read
#    `String.fromEnvironment('APP_LOCALE')`, so an `es` run drove a Spanish app
#    with French finders, timed out two screenshots in, and left `raw/` holding one
#    Spanish frame and five French ones. `postprocess.sh` then resized and renamed
#    that mixture and printed "ready to upload". The driver now reads APP_LOCALE
#    from the environment too; this script sets BOTH channels.
#
# 2. `screenshots/ios/asc/{raw,clean,<size>}/` hold whichever locale ran last, with
#    no marker in the filename or the folder. Copying them for three locales in one
#    go (what `capture.sh --asc-only` does) therefore produces three identical sets
#    with different prefixes. Locale must be part of the filename — that is the rule
#    in AGENTS.md — and the only way to get it right is run → postprocess → copy,
#    per locale, which is what the loop below does.
#
# A locale that does not refresh ALL 14 raws (7 portrait + 7 landscape) is treated
# as FAILED and the campaign stops: a partial set is worse than no set, because it
# looks finished.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERSION="${VERSION:-$(grep -m1 '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)}"
PKG="store/v${VERSION}"
RAW=screenshots/ios/asc/raw
SIZES="1242x2688 2688x1242 1284x2778 2778x1284"
EXPECTED_RAW=14
DEVICE="${DEVICE:-iPhone 17}"
LOCALES="${*:-fr es en}"

command -v flutter >/dev/null || { echo "flutter not on PATH" >&2; exit 1; }
xcrun simctl list devices booted 2>/dev/null | grep -q "$DEVICE (" || {
  echo "simulator '$DEVICE' is not booted — xcrun simctl boot '$DEVICE'" >&2; exit 1;
}

for loc in $LOCALES; do
  echo "=== $loc: drive on '$DEVICE'"
  # BSD find has no `-newermt "@epoch"` (GNU-ism, measured 2026-11-01): a marker file
  # is portable and says the same thing.
  marker="$(mktemp -t ascmark)"
  touch "$marker"; sleep 1
  if ! APP_LOCALE="$loc" flutter drive \
      --target=lib/asc_driver_main.dart \
      --driver=test_driver/asc_screenshots.dart \
      -d "$DEVICE" \
      --dart-define="APP_LOCALE=$loc"; then
    echo "!!! $loc drive FAILED — raw/ now mixes locales, do not postprocess" >&2
    exit 1
  fi

  fresh=$(find "$RAW" -name '*.png' -newer "$marker" | wc -l | tr -d ' ')
  if [ "$fresh" != "$EXPECTED_RAW" ]; then
    echo "!!! $loc refreshed $fresh of $EXPECTED_RAW raws — partial capture, stopping" >&2
    find "$RAW" -name '*.png' -newer "$marker" -exec basename {} \; | sed 's/^/    fresh: /' >&2
    rm -f "$marker"; exit 1
  fi
  echo "=== $loc: $fresh/$EXPECTED_RAW raws refreshed"

  bash screenshots/ios/asc/postprocess.sh | tail -1

  copied=0
  for size in $SIZES; do
    out="$PKG/screenshots/asc/$loc/$size"
    mkdir -p "$out"
    rm -f "$out"/*.png
    for f in "screenshots/ios/asc/$size"/*.png; do
      [ -e "$f" ] || continue
      cp "$f" "$out/${loc}-$(basename "$f")"
      copied=$((copied + 1))
    done
  done
  echo "=== $loc: $copied files -> $PKG/screenshots/asc/$loc"
  rm -f "$marker"
done

# The check that the old pipeline had no way to pass: three locales must not be the
# same pixels. Identical hashes across locales means the copy was not interleaved.
echo "=== cross-locale difference check"
bad=0
for size in $SIZES; do
  for f in "$PKG/screenshots/asc/fr/$size"/fr-*.png; do
    [ -e "$f" ] || continue
    base="$(basename "$f" | sed 's/^fr-//')"
    h_fr=$(md5 -q "$f")
    for loc in $LOCALES; do
      [ "$loc" = "fr" ] && continue
      other="$PKG/screenshots/asc/$loc/$size/$loc-$base"
      if [ ! -e "$other" ]; then
        echo "!!! missing $other" >&2; bad=1; continue
      fi
      if [ "$(md5 -q "$other")" = "$h_fr" ]; then
        echo "!!! IDENTICAL pixels fr vs $loc: $size/$base — a locale did not re-render" >&2
        bad=1
      fi
    done
  done
done
[ "$bad" = "0" ] && echo "    all locale sets are distinct"

python3 "$PKG/check.py"
