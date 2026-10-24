#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 INPUT_VIDEO OUTPUT_MP4 [MAX_SECONDS]" >&2
  exit 2
fi

input=$1
output=$2
max_seconds=${3:-15}

command -v ffmpeg >/dev/null || { echo "ffmpeg is required" >&2; exit 1; }
[[ -f "$input" ]] || { echo "input not found: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -hide_banner -loglevel error -y \
  -i "$input" -t "$max_seconds" -an \
  -vf "fps=25,scale='min(720,iw)':-2:flags=lanczos" \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
  -movflags +faststart "$output"

[[ -s "$output" ]] || { echo "normalization produced no video" >&2; exit 1; }
echo "wrote $output"
