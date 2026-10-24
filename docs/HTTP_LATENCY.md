# HTTP frame latency experiment

See [STATUS.md](STATUS.md) for the current deployment state and
[RUNPOD_LIVE.md](RUNPOD_LIVE.md) for complete setup/camera instructions.

This prototype receives one JPEG frame at a time and returns an animated JPEG.
Models and source features remain loaded. The client allows one in-flight
request, capturing the newest video frame only after the previous reply. It
therefore skips stale frames rather than building an unbounded queue.

This is a single-client experiment, not a production service. It redetects the
face in every frame, uses the first frame as the relative-motion reference,
and applies pose, expression, scale, translation, stitching, lip normalization,
and source-image pasteback. It does not implement temporal landmark tracking,
WebRTC, audio, or multi-user session isolation. Its performance and visual
behavior need independent verification; offline benchmark FPS is not a promise.

## Run through an SSH tunnel

Use the pinned LivePortrait checkout, official weights, and the GPU environment
verified by the offline runbook. On the GPU host:

```bash
python live/server.py \
  --upstream /workspace/LivePortrait \
  --source /workspace/LivePortrait/assets/examples/source/s9.jpg \
  --sample /workspace/LivePortrait/assets/examples/driving/d0.mp4
```

The server binds only `127.0.0.1:8765`; expose SSH only. From the client machine:

```bash
ssh -N -L 127.0.0.1:18765:127.0.0.1:8765 USER@GPU_HOST -p SSH_PORT
```

Open `http://127.0.0.1:18765`. Local HTTP travels inside the encrypted SSH
connection to the GPU. This measures that transport, not the Runpod public HTTP
proxy or a WebRTC connection. Do not bind the service publicly: it has no
production authentication and shares one source/reference state.

Camera access is disabled by default. Use `--allow-camera` only after explicit
permission to send live face frames to the remote machine. Permission to run a
public-sample benchmark is not permission to upload private driving videos,
private motion templates, or camera images. The example command above uses an upstream public portrait. The later owner
session used the separately approved Mina source portrait. The application writes no input/output frames to
disk and disables request logging. This describes application behavior, not a
cloud-provider retention guarantee. Timings contain no image data.

## Measurements

- **HTTP round trip:** client fetch start to full response body received.
- **Capture to canvas:** canvas capture, input JPEG encoding, HTTP round trip,
  output JPEG decoding, and canvas drawing. This is not physical
  camera-to-display latency: camera exposure/buffering and screen presentation
  are not directly measured.
- **Server:** request handling including body reading, decoding, face analysis,
  inference, pasteback, and JPEG encoding; excludes response delivery.
- **Inference:** face crop, motion extraction, synthesis, pasteback, and GPU
  synchronization; excludes input/output JPEG coding and transport.
- Summary medians/p95 exclude the first five responses. The FPS display covers
  the current run including startup. Browser timings are bounded to 2000 frames.

`Download timings` exports only numerical measurements. Compare repeated public
sample runs before drawing conclusions about a physical camera or sustained
interactive use. Stop releases the camera tracks and aborts the in-flight fetch.

## Checks

```bash
python3 tests/test-live-http.py
```

These tests use a fake inference engine to exercise request size/origin/content
checks, backpressure, error recovery, echo, and reset. They do not validate CUDA
inference or visual quality; those require a real GPU request and decoded output.

## Observed public-sample result (2026-10-24)

A short headless Chrome test on the client Mac used the encrypted SSH tunnel to
an RTX 4090 in EU-RO-1. The animated output was 540 x 960; the source was the public
Mona Lisa portrait, not Mina. Each of two runs delivered 100 frames. The second
run, without a concurrent echo test, measured:

| Metric | Median | p95 |
| --- | ---: | ---: |
| HTTP round trip |184.2ms|187.6ms|
| Capture to canvas draw |194.0ms|199.5ms|
| Server request handling |41.7ms| — |

Delivered throughput including startup was 4.75 FPS. The first run measured
194.3ms median/261.6ms p95 capture-to-canvas and 4.41 FPS. A separate 16 KiB echo
probe measured 127.3 ms median, but overlapped the first browser run; do not
interpret subtracting medians as an exact network-only decomposition.

Camera remained disabled. This proves remote frame transformation and gives a
short-run client/network latency baseline; it does not validate physical-camera
latency, long-session stability, or smooth 25 FPS playback. Browser Stop/restart
checks passed, no page errors were recorded, and all eight HTTP boundary tests
passed. The initial upstream Cropper keyword-argument mismatch was corrected
before the successful measurements.

## Mina camera-path smoke on RTX 5090 (2026-10-24)

An independently created EU-RO-1 RTX 5090 served the approved Mina source.
A Chrome fake-camera test used public prerecorded input, passed 20 frames with
zero errors, and returned 512 x 960 Mina output. Capture-to-canvas was 175.1 ms
median/184.0 ms p95; HTTP round trip 169.2/172.2 ms,server median 31.3 ms,delivered
4.52 FPS including startup. Stop ended the fake-camera tracks; no page errors.
The actual browser page was then opened for the owner, who responded positively.
No physical-camera latency recording was made. The owner later requested
cleanup; that Pod and its ephemeral files were deleted.
