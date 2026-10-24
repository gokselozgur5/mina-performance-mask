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

if command -v python3 >/dev/null; then
  python3 - <<'PY'
try:
    import torch
except ImportError:
    print("torch=unavailable")
else:
    print(f"torch={torch.__version__}")
    print(f"torch_cuda_available={torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"torch_cuda_device={torch.cuda.get_device_name(0)}")
PY
else
  echo "python3=unavailable"
fi

if command -v nvpmodel >/dev/null; then
  power_mode=$(nvpmodel -q 2>/dev/null | head -n 1 || true)
  echo "power_mode=${power_mode:-unavailable}"
else
  echo "power_mode=unavailable"
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
command -v python3 >/dev/null || { echo "ERROR: Python 3 is required" >&2; fail=1; }
command -v ffmpeg >/dev/null || { echo "ERROR: FFmpeg is required" >&2; fail=1; }
(( available_kib >= 31457280 )) || { echo "ERROR: at least 30 GiB free space is required" >&2; fail=1; }

exit "$fail"
