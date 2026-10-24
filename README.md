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
Jetson AGX Thor was verified with L4T R38.4, CUDA 13.0, native CUDA-enabled
PyTorch 2.12.1, and MAXN mode. The first offline render uses the official
PyTorch LivePortrait path. FasterLivePortrait's documented TensorRT 8.x path is
not installed because it is incompatible with Thor's current software stack;
live acceleration remains a separate measured phase.

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

Run the read-only preflight after SSH access is available:

```bash
./scripts/preflight-thor.sh
```

The inference backend will be pinned only after that report confirms L4T,
CUDA, GPU architecture, Docker runtime, and free disk space. The intended
backend is FasterLivePortrait with TensorRT, using the official LivePortrait
motion-transfer model.

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
