# Delivery plan

## Phase 1: recorded performance

- Extract one canonical Mina source portrait from the existing asset.
- Normalize a private 10-15 second performer clip.
- Run portrait animation on Thor.
- Review identity stability, eyes, teeth, lips, jaw, hair, and background.

Exit condition: Mina visibly follows the recorded performance without identity
drift or a failed face boundary.

Status: the two-second diagnostic and a full 16-second, 400-frame CPU render
completed. The full output passed decoding and transfer-integrity checks. The
owner accepted it as a promising starting point while reporting visual
anomalies; the visual-quality exit condition remains open. Next, identify the
affected timestamps and evaluate eyes, mouth, face boundaries, and identity
stability. Media remains private. See [CPU render steps](CPU_RENDER.md).
Native GPU inference reset the board in MAXN and 120 W modes; do not rerun it
on this stack.

## Phase 2: latency baseline

- Measure decode, face analysis, inference, composition, and encode separately.
- Review existing reset evidence and runtime compatibility without GPU inference.
  GPU execution remains blocked until a separate recovery plan is explicitly
  authorized; this plan does not authorize another reset reproduction.
- Convert only supported networks with a Thor-compatible TensorRT 10 path.
- Select a resolution and quality preset from measured results.

Exit condition: a repeatable benchmark report and an interactive preview with
measured end-to-end latency.

## Phase 3: live mirror

- Replace the driving file with a webcam capture ring buffer.
- Add bounded queues and stale-frame dropping.
- Add start/stop recording and a visible AI-generated indicator.

Exit condition: a five-minute local session without growing latency, memory, or
temperature.

## Phase 4: optional voice

- Capture microphone audio independently from video.
- Add a local voice-conversion backend only after the visual path is stable.
- Resynchronize audio and video against measured timestamps.

Exit condition: speech, lip motion, and output audio remain synchronized during
interruptions and natural pauses.
