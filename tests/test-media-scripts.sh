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

bash -n "$project_root/scripts/render-liveportrait.sh"
if "$project_root/scripts/render-liveportrait.sh" >/dev/null 2>&1; then
  echo "render script accepted missing arguments" >&2
  exit 1
fi

# An interrupted template must fail before Python runs or output is created.
: > "$work_dir/empty.pkl"
status=0
LIVEPORTRAIT_DIR="$work_dir" "$project_root/scripts/render-liveportrait.sh" \
  "$work_dir/source.png" "$work_dir/empty.pkl" "$work_dir/rejected-output" \
  > "$work_dir/rejection.log" 2>&1 || status=$?
if [[ "$status" -ne 2 || -d "$work_dir/rejected-output" ]] ||
   ! grep -q 'driving input is empty' "$work_dir/rejection.log"; then
  echo "empty driving template was not rejected before inference" >&2
  exit 1
fi

echo "media script tests passed"
