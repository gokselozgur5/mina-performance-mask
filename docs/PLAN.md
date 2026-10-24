# Delivery plan

Read [current status](STATUS.md) for the latest handoff. Paid resources are
currently closed at the owner's request; deployment requires a new authorized run.

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

Status: cloud offline and browser/SSH baselines measured on 4090 and 5090;
see [timings](HTTP_LATENCY.md). Sustained physical-camera timing remains open.

- Measure decode, face analysis, inference, composition, and encode separately.
- Review existing reset evidence and runtime compatibility without GPU inference.
  GPU execution remains blocked until a separate recovery plan is explicitly
  authorized; this plan does not authorize another reset reproduction.
- Convert only supported networks with a Thor-compatible TensorRT 10 path.
- Select a resolution and quality preset from measured results.

Exit condition: a repeatable benchmark report and an interactive preview with
measured end-to-end latency.

## Phase 3: live mirror

Status: browser camera → Runpod → Mina prototype delivered and positively
received by the owner. It was then shut down on request. Current implementation
uses one in-flight HTTP frame and drops stale capture opportunities.

- Improve the implemented webcam path with bounded streaming transport.
- Add bounded queues and stale-frame dropping.
- Preserve Start/Stop capture and no-recording behavior; add a visible
  AI-generated label. Recording is out of scope without explicit authorization.

Exit condition: a five-minute local session without growing latency, memory, or
temperature.

## Phase 4: optional voice

- Capture microphone audio independently from video.
- Add a local voice-conversion backend only after the visual path is stable.
- Resynchronize audio and video against measured timestamps.

Exit condition: speech, lip motion, and output audio remain synchronized during
interruptions and natural pauses.
