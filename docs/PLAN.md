# Delivery plan

## Phase 1: recorded performance

- Extract one canonical Mina source portrait from the existing asset.
- Normalize a private 10-15 second performer clip.
- Run portrait animation on Thor.
- Review identity stability, eyes, teeth, lips, jaw, hair, and background.

Exit condition: Mina visibly follows the recorded performance without identity
drift or a failed face boundary.

Status: a two-second, 50-frame CPU diagnostic completed. The full private
driving clip is being evaluated separately from the public repository. Native
PyTorch GPU inference currently resets the Thor board and is blocked pending a
compatible runtime or engine.

## Phase 2: latency baseline

- Measure decode, face analysis, inference, composition, and encode separately.
- Reproduce the native GPU reset with persistent system logs or a minimal model
  probe before running another full workload.
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
