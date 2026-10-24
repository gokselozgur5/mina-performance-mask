#!/usr/bin/env bash
set -euo pipefail

echo "architecture=$(uname -m)"
echo "kernel=$(uname -r)"

if [[ -r /etc/nv_tegra_release ]]; then
  echo "l4t=$(head -n 1 /etc/nv_tegra_release)"
else
  echo "l4t=unavailable"
fi

if command -v nvcc >/dev/null; then
  echo "nvcc=$(nvcc --version | tail -n 1)"
else
  echo "nvcc=unavailable"
fi

if command -v docker >/dev/null; then
  echo "docker=$(docker --version)"
  runtime=$(docker info --format '{{json .Runtimes}}' 2>/dev/null || true)
  echo "docker_runtimes=${runtime:-unavailable}"
else
  echo "docker=unavailable"
fi

if command -v ffmpeg >/dev/null; then
  echo "ffmpeg=$(ffmpeg -version | head -n 1)"
else
  echo "ffmpeg=unavailable"
fi

available_kib=$(df -Pk . | awk 'NR==2 {print $4}')
echo "workspace_free_kib=$available_kib"

fail=0
[[ "$(uname -m)" == "aarch64" ]] || { echo "ERROR: expected aarch64 Thor host" >&2; fail=1; }
[[ -r /etc/nv_tegra_release ]] || { echo "ERROR: L4T release is unavailable" >&2; fail=1; }
command -v docker >/dev/null || { echo "ERROR: Docker is required" >&2; fail=1; }
command -v ffmpeg >/dev/null || { echo "ERROR: FFmpeg is required" >&2; fail=1; }
(( available_kib >= 31457280 )) || { echo "ERROR: at least 30 GiB free space is required" >&2; fail=1; }

exit "$fail"
