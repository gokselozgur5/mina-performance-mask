#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 MINA_VIDEO OUTPUT_PNG [TIMESTAMP_SECONDS]" >&2
  exit 2
fi

input=$1
output=$2
timestamp=${3:-0.20}

command -v ffmpeg >/dev/null || { echo "ffmpeg is required" >&2; exit 1; }
[[ -f "$input" ]] || { echo "input not found: $input" >&2; exit 1; }
mkdir -p "$(dirname "$output")"

ffmpeg -hide_banner -loglevel error -y \
  -ss "$timestamp" -i "$input" -frames:v 1 \
  -vf "scale='min(1024,iw)':-2:flags=lanczos" \
  "$output"

[[ -s "$output" ]] || { echo "source extraction produced no image" >&2; exit 1; }
echo "wrote $output"
