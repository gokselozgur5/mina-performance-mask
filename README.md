# Mina Performance Mask

Mina Performance Mask transfers a consenting performer's head pose and facial
expressions onto a fixed Mina portrait. The first milestone renders a recorded
driving clip locally. A later milestone replaces that clip with a webcam stream.

## Pipeline

```text
Mina portrait/video -> canonical source portrait ----+
                                                    |
performer clip -> normalized driving video ---------+-> portrait animation -> MP4
```

The performer supplies motion only. Mina remains the visible identity. Inputs,
model weights, and rendered videos stay outside Git.

## Current milestone

The reproducible preparation and host-preflight layer is complete. The target
Jetson AGX Thor was verified with L4T R38.4, CUDA 13.0, and native CUDA-enabled
PyTorch 2.12.1. A 50-frame CPU diagnostic render completed with the official
PyTorch LivePortrait path. A full 16-second CPU render subsequently completed
with 400 frames at 25 fps and a 512 x 960 H.264 output. Full decoding and a
source/destination checksum match verified the private transfer. The owner
considered it a promising first result but reported visual anomalies; detailed
quality review remains open. This is an offline milestone, not a real-time
performance claim. See [the CPU runbook](docs/CPU_RENDER.md) for execution,
recovery, and output verification. The same diagnostic workload reproducibly reset the board on
the current GPU path in both MAXN and 120 W modes, so GPU execution is not yet
declared safe. FasterLivePortrait's documented TensorRT 8.x path is not
installed because Thor ships TensorRT 10; acceleration remains a separate,
measured compatibility phase.

## Prepare the two inputs

Requires FFmpeg and FFprobe.

```bash
make source \
  MINA_VIDEO=/path/to/mina.mp4 \
  MINA_SOURCE=artifacts/mina-source.png

make driving \
  DRIVING_VIDEO=/path/to/performer.mov \
  NORMALIZED_DRIVING=artifacts/driving.mp4

make verify \
  MINA_SOURCE=artifacts/mina-source.png \
  NORMALIZED_DRIVING=artifacts/driving.mp4
```

Record the driving clip in diffuse front light, with one face, no cuts, and no
hands crossing the face. Start neutral, then turn left/right, look up/down,
blink, smile, and speak naturally. Ten to fifteen seconds is enough for the
first test.

## Thor handoff

Run the read-only preflight on Thor:

```bash
./scripts/preflight-thor.sh
```

Then render with a pinned LivePortrait checkout and an activated Python
environment. CPU is deliberately the safe default:

```bash
export LIVEPORTRAIT_DIR=/path/to/LivePortrait
./scripts/render-liveportrait.sh \
  /private/input/mina-source.png \
  /private/input/driving.mp4 \
  /private/output \
  cpu
```

LivePortrait also writes a private `.pkl` motion template beside a driving
video. Supplying that template on later runs avoids reading the raw performer
video again. Do not select the `gpu` backend on an unverified Thor software
stack: a successful CUDA import is not proof that every model kernel is safe.

## Safety and provenance

- Only animate images and performances that you own or have permission to use.
- Keep raw camera footage private by default.
- Private source and driving media belong under ignored local artifact folders
  and must never be committed.
- Mark shared renders as AI-generated.
- Do not use the pipeline to impersonate another person or misrepresent a real
  recording.

## License

The orchestration code in this repository is MIT licensed. LivePortrait,
FasterLivePortrait, model weights, and generated media remain subject to their
respective licenses and permissions.
