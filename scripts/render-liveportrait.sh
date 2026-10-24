#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: render-liveportrait.sh SOURCE DRIVING OUTPUT_DIR [cpu|gpu]

SOURCE may be an image or video. DRIVING may be a video or a previously
generated private .pkl motion template. The default backend is cpu.

Environment:
  LIVEPORTRAIT_DIR  Path to a pinned LivePortrait checkout.
EOF
}

if [[ $# -lt 3 || $# -gt 4 ]]; then
  usage >&2
  exit 2
fi

source_media=$1
driving_media=$2
output_dir=$3
backend=${4:-cpu}
liveportrait_dir=${LIVEPORTRAIT_DIR:-}

[[ -n "$liveportrait_dir" ]] || {
  echo "ERROR: LIVEPORTRAIT_DIR is required" >&2
  exit 2
}
[[ -d "$liveportrait_dir" ]] || {
  echo "ERROR: LivePortrait checkout not found: $liveportrait_dir" >&2
  exit 2
}
[[ -f "$source_media" ]] || {
  echo "ERROR: source does not exist: $source_media" >&2
  exit 2
}
[[ -f "$driving_media" ]] || {
  echo "ERROR: driving input does not exist: $driving_media" >&2
  exit 2
}
[[ -s "$driving_media" ]] || {
  echo "ERROR: driving input is empty; use the original video to regenerate an interrupted motion template" >&2
  exit 2
}

mkdir -p "$output_dir"

args=(
  inference.py
  --source "$source_media"
  --driving "$driving_media"
  --output-dir "$output_dir"
)

if [[ "$driving_media" != *.pkl ]]; then
  args+=(--flag-crop-driving-video)
fi

case "$backend" in
  cpu)
    args+=(--flag-force-cpu --no-flag-use-half-precision)
    ;;
  gpu)
    ;;
  *)
    echo "ERROR: backend must be cpu or gpu" >&2
    exit 2
    ;;
esac

cd "$liveportrait_dir"
exec python "${args[@]}"
