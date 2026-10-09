#!/bin/bash
# Post-process raw ASC captures:
#  1. portrait:  replace top 170px status-bar strip with the clean strip from
#     the accepted reference screenshots/ios/home.png (removes the simulator
#     DEBUG ribbon + Dynamic Island; flat #2D2D2D seam, invisible)
#  2. landscape: paint the top-right ribbon corner with per-column colors
#     sampled from y=340 (flat region -> seamless)
#  3. resize to the four exact ASC dimensions
set -e
# Resolve the repo root from THIS script, not a hardcoded path: the campaign
# also runs from a git worktree (e.g. /private/tmp/mamadera-120), and a
# hardcoded path would silently write the campaign into the other checkout.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RAW=screenshots/ios/asc/raw
CLEAN=screenshots/ios/asc/clean
REF=screenshots/ios/home.png
mkdir -p "$CLEAN"

# v1.2.0: `growth` joins the set (7 screens) — the growth screen is the
# release's headline feature and must not be silently omitted downstream.
SCREENS="home feeding sleep diaper history menu growth"

for n in $SCREENS; do
  swift screenshots/ios/asc/Patch.swift portrait "$RAW/$n.png" "$CLEAN/$n.png" "$REF"
done
for n in $SCREENS; do
  swift screenshots/ios/asc/Patch.swift landscape "$RAW/${n}_landscape.png" "$CLEAN/${n}_landscape.png"
done

declare -a DIM
# No associative array here on purpose: /bin/bash on macOS is 3.2.57, which
# has no `declare -A` (`value too great for base`), while a brew bash on PATH
# is 5.x — so `./postprocess.sh` and `bash postprocess.sh` would disagree.
# A plain case on the folder name works in any shell.
for size in 1242x2688 2688x1242 1284x2778 2778x1284; do
  IFS='x' read -r W H <<< "$size"
  dir="screenshots/ios/asc/$size"
  mkdir -p "$dir"
  DIM+=("$dir")
  case "$size" in
    1242x2688|1284x2778) names="$SCREENS" ;;
    2688x1242|2778x1284) names="home_landscape feeding_landscape sleep_landscape diaper_landscape history_landscape menu_landscape growth_landscape" ;;
  esac
  for n in $names; do
    base="${n%_landscape}"
    # sips -z takes HEIGHT then WIDTH
    sips -z "$H" "$W" "$CLEAN/$n.png" --out "$dir/$base.png" >/dev/null
  done
done
echo "=== FINAL TREE ==="
find screenshots/ios/asc -name "*.png" -not -path "*/raw/*" -not -path "*/clean/*" | sort
echo "=== DIMENSION + ALPHA CHECK (28 files) ==="
# ASC rejects wrong dimensions AND any alpha channel (even fully opaque).
# DIM must be populated by the resize loop above — an empty array here made
# this whole check iterate over nothing and print OK unconditionally.
[[ ${#DIM[@]} -eq 4 ]] || { echo "INTERNAL: DIM has ${#DIM[@]} entries, expected 4"; exit 1; }
dim_ok=1; alpha_ok=1; count=0
for d in "${DIM[@]}"; do
  for f in "$d"/*.png; do
    w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
    # ${d##*/} — the folder NAME is the expected WxH; $d is the full path, and
    # comparing "1242x2688" against "screenshots/ios/asc/1242x2688" never
    # matches (that is why this check was silent while DIM was undefined).
    [[ "${w}x${h}" != "${d##*/}" ]] && { echo "DIM MISMATCH: ${f} = ${w}x${h}"; dim_ok=0; }
    a=$(sips -g hasAlpha "$f" | tail -1 | awk '{print $2}')
    [[ "${a}" != "no" ]] && { echo "ALPHA CHANNEL: ${f}"; alpha_ok=0; }
    count=$((count + 1))
  done
done
if [[ $dim_ok -eq 1 && $alpha_ok -eq 1 && $count -eq 28 ]]; then
  echo "OK: $count files, exact sizes, RGB (no alpha) — ready to upload"
else
  echo "FAILED validation ($count files checked)"; exit 1
fi
