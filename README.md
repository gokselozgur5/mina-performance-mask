# Mina Performance Mask

Mina Performance Mask transfers a consenting performer's head pose and facial
expressions onto a fixed Mina portrait. The live prototype captures camera
frames in a browser, processes them on a Runpod GPU, and returns Mina frames
to the same page. An offline CPU path is also available.

## Start here — humans and fresh AI sessions

Read [AGENTS.md](AGENTS.md), then [current status](docs/STATUS.md).
The complete [live runbook](docs/RUNPOD_LIVE.md) covers deployment, browser
opening, verification, and cleanup. [Architecture](docs/ARCHITECTURE.md)
explains the code and HTTP contract.

**Latest state (2026-10-24): the live app was demonstrated, then all paid
resources were closed at the owner's request.** This repository is the source
and handoff, not an always-running hosted website. Recheck cloud state before
resuming. Private source portraits and credentials are intentionally absent.

A new AI can start with this prompt:

> Continue Mina Performance Mask from this repository. Read AGENTS.md and
> docs/STATUS.md first, then the linked runbook. Explain the current state and
> next step before changing infrastructure. Preserve the privacy boundary.
> Do not create paid resources unless my current request authorizes deployment.
> If I ask to run the app, deliver the actual working browser page, not a
> screenshot or benchmark alone, and report what remains billing.

## Pipeline

```text
Browser camera -> JPEG -> HTTP over SSH -> resident Runpod LivePortrait
                                             + fixed source portrait
Browser Mina canvas <- JPEG <---------------+
```

The performer supplies motion; Mina remains the output identity. The application
does not record live frames. Inputs, model weights, logs, templates, and outputs
stay outside Git. The browser demo is single-client and loopback-only.

## Verified baseline

- Thor CPU: full 16-second / 400-frame offline render completed. Visual anomalies
  remain to be characterized. Thor GPU inference reset the board in both MAXN
  and 120 W modes; do not retry that path.
- Runpod RTX 4090: public offline animation about 37 FPS; full MP4 processing
  about 20 FPS. HTTP browser delivery about 4.75 FPS / 194 ms median capture to
  canvas on the tested client/network.
- Runpod RTX 5090: Mina source with a public fake-camera smoke test returned
  512 x 960 frames; 175 ms median capture to canvas over 20 frames. The owner
  responded positively after delivery; this is not a recorded
  physical-camera latency measurement or proof of sustained 25 FPS.

See [status and limitations](docs/STATUS.md), [timing definitions](docs/HTTP_LATENCY.md),
and [offline CPU recovery](docs/CPU_RENDER.md). Source and model revisions are
pinned in [config/upstream.env.example](config/upstream.env.example).

## Checks without renting a GPU

```bash
make test
```

Requires Python 3, FFmpeg, and FFprobe. Browser/GPU smoke tests are separate;
see [the live runbook](docs/RUNPOD_LIVE.md). Do not rent a machine only to read
or edit this repository.

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
