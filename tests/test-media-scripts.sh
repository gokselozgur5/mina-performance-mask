#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/mina-mask-test.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i testsrc2=size=512x960:rate=30 -t 1 \
  -c:v libx264 -pix_fmt yuv420p "$work_dir/input.mp4"

"$project_root/scripts/extract-source.sh" \
  "$work_dir/input.mp4" "$work_dir/source.png" 0.1
"$project_root/scripts/normalize-driving.sh" \
  "$work_dir/input.mp4" "$work_dir/driving.mp4" 1
"$project_root/scripts/verify-inputs.sh" \
  "$work_dir/source.png" "$work_dir/driving.mp4"

echo "media script tests passed"
