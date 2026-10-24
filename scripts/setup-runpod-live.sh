#!/usr/bin/env bash
# Install on an already-authorized x86 GPU host. This does not rent a machine.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 INSTALL_ROOT (e.g. /workspace/mina-runtime)" >&2
  exit 2
fi
[[ $(uname -m) == x86_64 ]] || {
  echo "This installer targets the tested x86 Runpod image, not Jetson Thor." >&2
  exit 2
}
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# This file contains public pins only; never add credentials to it.
source "$project_root/config/upstream.env.example"
command -v git >/dev/null
command -v ffmpeg >/dev/null
command -v ffprobe >/dev/null
python3 - <<'PY'
import torch
assert torch.__version__.split('+')[0] == '2.8.0', 'Use the documented PyTorch 2.8.0 image'
assert torch.version.cuda == '12.8', 'Expected CUDA 12.8 PyTorch build'
assert torch.cuda.is_available(), 'No CUDA GPU; refusing silent CPU fallback'
PY
mkdir -p "$1"
install_root=$(cd "$1" && pwd)
checkout="$install_root/LivePortrait"
if [[ ! -e "$checkout" ]]; then
  git clone "$LIVEPORTRAIT_REPOSITORY" "$checkout"
  git -C "$checkout" checkout --detach "$LIVEPORTRAIT_REVISION"
else
  [[ $(git -C "$checkout" rev-parse HEAD) == "$LIVEPORTRAIT_REVISION" ]] || {
    echo "Existing checkout has a different revision; use a new install root." >&2
    exit 2
  }
  [[ -z $(git -C "$checkout" status --porcelain --untracked-files=no) ]] || {
    echo "Existing checkout has tracked changes; refusing to overwrite it." >&2
    exit 2
  }
fi
python3 -m venv --system-site-packages "$install_root/venv"
"$install_root/venv/bin/python" -m pip install --disable-pip-version-check \
  -r "$checkout/requirements_base.txt" transformers==4.38.0 onnxruntime-gpu==1.22.0
"$install_root/venv/bin/python" - "$checkout/pretrained_weights" \
  "$LIVEPORTRAIT_MODEL_REPOSITORY" "$LIVEPORTRAIT_MODEL_REVISION" <<'PY'
import sys
from huggingface_hub import snapshot_download
snapshot_download(sys.argv[2], revision=sys.argv[3], local_dir=sys.argv[1],
                  allow_patterns=['liveportrait/*', 'insightface/*'])
PY
"$install_root/venv/bin/python" - <<'PY'
import torch, onnxruntime
assert torch.cuda.is_available()
assert 'CUDAExecutionProvider' in onnxruntime.get_available_providers()
print('Runtime ready:', torch.__version__, onnxruntime.__version__)
PY
printf 'Environment: %s/venv\nLivePortrait: %s\n' "$install_root" "$checkout"
