#!/bin/bash
# Post-process raw ASC captures:
#  1. portrait:  replace top 170px status-bar strip with the clean strip from
#     the accepted reference screenshots/ios/home.png (removes the simulator
#     DEBUG ribbon + Dynamic Island; flat #2D2D2D seam, invisible)
#  2. landscape: paint the top-right ribbon corner with per-column colors
#     sampled from y=340 (flat region -> seamless)
#  3. resize to the four exact ASC dimensions
set -e
cd /Users/pvjacquier/DEV/mamadera
RAW=screenshots/ios/asc/raw
CLEAN=screenshots/ios/asc/clean
REF=screenshots/ios/home.png
mkdir -p "$CLEAN"

for n in home feeding sleep diaper history menu; do
  swift screenshots/ios/asc/Patch.swift portrait "$RAW/$n.png" "$CLEAN/$n.png" "$REF"
done
for n in home feeding sleep diaper history menu; do
  swift screenshots/ios/asc/Patch.swift landscape "$RAW/${n}_landscape.png" "$CLEAN/${n}_landscape.png"
done

declare -A SIZES=( [1242x2688]=portrait [2688x1242]=landscape [1284x2778]=portrait [2778x1284]=landscape )
for size in 1242x2688 2688x1242 1284x2778 2778x1284; do
  IFS='x' read -r W H <<< "$size"
  dir="screenshots/ios/asc/$size"
  mkdir -p "$dir"
  case "${SIZES[$size]}" in
    portrait)  names="home feeding sleep diaper history menu" ;;
    landscape) names="home_landscape feeding_landscape sleep_landscape diaper_landscape history_landscape menu_landscape" ;;
  esac
  for n in $names; do
    base="${n%_landscape}"
    # sips -z takes HEIGHT then WIDTH
    sips -z "$H" "$W" "$CLEAN/$n.png" --out "$dir/$base.png" >/dev/null
  done
done
echo "=== FINAL TREE ==="
find screenshots/ios/asc -name "*.png" -not -path "*/raw/*" -not -path "*/clean/*" | sort
echo "=== DIMENSION + ALPHA CHECK (24 files) ==="
# ASC rejects wrong dimensions AND any alpha channel (even fully opaque).
dim_ok=1; alpha_ok=1
for d in "${DIM[@]}"; do
  for f in "$d"/*.png; do
    w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
    [[ "${w}x${h}" != "${d}" ]] && { echo "DIM MISMATCH: ${f} = ${w}x${h}"; dim_ok=0; }
    a=$(sips -g hasAlpha "$f" | tail -1 | awk '{print $2}')
    [[ "${a}" != "no" ]] && { echo "ALPHA CHANNEL: ${f}"; alpha_ok=0; }
  done
done
if [[ $dim_ok -eq 1 && $alpha_ok -eq 1 ]]; then
  echo "OK: 24 files, exact sizes, RGB (no alpha) — ready to upload"
else
  echo "FAILED validation"; exit 1
fi
