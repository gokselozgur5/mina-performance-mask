# Current handoff — 2026-10-24

## Where we stopped

**The browser camera → Runpod GPU → Mina portrait flow works as a prototype.**
The owner praised the result and requested a public, self-contained AI handoff.
The owner then explicitly requested that paid resources be closed.

**Infrastructure is now OFF.** The live Pod was terminated and fresh account
reads returned zero Pods, Serverless endpoints, network volumes, global volumes,
and clusters. The old localhost page needs a newly authorized deployment and
SSH tunnel; it is not a currently hosted public website. Do not silently
provision a new machine just because you read this repository.

The source portrait, original performer videos, weights, logs, and rendered
media are deliberately absent. A fresh clone can use public upstream samples;
reproducing the actual Mina identity needs the owner's local portrait and an
appropriate transfer authorization. Credentials must come from the operator's
existing environment or credential provider, never this repo.

## What exists

- `live/server.py`: resident GPU model, cached source features, frame-at-a-time
  relative animation, JPEG response, loopback HTTP server.
- `live/index.html`: camera/sample input, side-by-side Mina output, Start/Stop,
  live timing display, numerical timing export, bounded history, one in-flight
  frame. The current UI is Turkish, with some English diagnostic labels.
- Preparation scripts and safe-default CPU offline rendering.
- Rebuild instructions and a setup script pinned to the tested upstream source
  and official model revision.
- Eight CPU-only HTTP boundary tests plus synthetic media tests; a portable
  fake-camera browser smoke test for an already-running GPU service.

## Evidence and its limits

| Test | Observed result | Scope |
| --- | --- | --- |
| Thor CPU offline | 16 seconds, 400 frames, 512 x 960; decode/checksum passed | Owner liked the first result but reported unspecified visual anomalies |
| RTX 4090 offline | Warm animation ~36.8 FPS; full MP4 processing ~20 FPS | Public 78-frame clip, includes encoding/concat in total; not live network FPS |
| RTX 4090 HTTP browser | Capture-to-canvas 194.0 ms median / 199.5 ms p95; 4.75 delivered FPS | 100 public sample frames, 540 x 960 output, single-request HTTP over SSH |
| RTX 5090 camera-path smoke | Capture-to-canvas 175.1 ms median / 184.0 ms p95; 4.52 delivered FPS | 20 public fake-camera frames driving Mina, 512 x 960; excludes physical camera/display timing |

The 5090 smoke recorded zero errors/page errors, live camera tracks while
running, and ended tracks after Stop. The actual page was opened in Chrome for
the owner. The owner then responded positively. No instrumented recording of
the owner's physical camera session was taken; do not replace that distinction
with a claim of measured physical-camera latency or sustained 25 FPS.

The tested cloud image was
`runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`: Python 3.12.3,
PyTorch 2.8.0+cu128, ONNX Runtime GPU 1.22.0, official LivePortrait weights.
The 4090 and 5090 test hosts used driver 595.91.07 / CUDA host compatibility
13.2. The software inside the image used CUDA 12.8. Prices observed that day
were $0.89/hour and $1.19/hour respectively; re-read prices and stock before
renting. These are historical rates, not current quotes or total spend.

## Known limitations

- One HTTP request in flight bounds queue growth but limits delivered FPS by
  round-trip latency. The ~37 offline animation FPS is not browser throughput.
- Face detection repeats for every frame; there is no temporal landmark
  tracking, WebRTC, audio, voice conversion, multi-user isolation, or recording.
- First-frame pose/expression is the motion reference. Start facing forward.
  Missing faces (422) and a busy engine (429) are retried by the UI.
- There is one shared reference per server, so use one active browser client.
  Stop aborts browser fetching and ends camera tracks; an already-running GPU
  frame can finish. Stop does not stop or delete the cloud machine.
- `--allow-camera` enables the UI, not a server-side media provenance check.
  The server cannot determine whether a JPEG is a sample or a live camera frame.
- The server is a loopback-only prototype without public authentication. Do not
  expose port 8765 directly to the internet.
- Numerical timing history retains 2,000 frames. The present FPS display divides
  retained frame count by elapsed run time, so it underreports after the cap;
  exported FPS also changes if read long after stopping. Fix this before relying
  on long-session throughput reports. Short recorded tests were below the cap.
- Torch/CUDA/ONNX runtime compatibility is verified only for the tested stack.
  Requirements include transitive dependencies that are not fully locked.
- Thor GPU inference reset the board in MAXN and 120 W modes. Root cause is not
  proven. Do not retry it as part of ordinary continuation.

## Next work, in priority order

1. Preserve the working baseline and the owner's media boundary. If asked to
   resume, follow `RUNPOD_LIVE.md`, open the actual page, and leave it usable.
2. Correct long-session FPS accounting and add a regression for stop/history
   rollover before a sustained test.
3. Obtain specific timestamps/descriptions for the reported visual artifacts;
   do not guess that a quality issue is a transport issue.
4. Measure and improve bounded streaming throughput (e.g. WebRTC or controlled
   overlapping frame transport) while preserving frame freshness and no-storage
   behavior. Compare end-to-end latency and delivered FPS on the same setup.
5. Run a consented five-minute session; check memory, reconnects, face loss,
   multiple tabs, cancellation, and end-to-end latency. Do not claim this passed.

## Update contract

After the next meaningful change, replace the stale state above: active/off,
what code is deployed, exact tests, measured limitations, and next action.
Keep credentials, private runtime IDs/addresses, and media in ignored local
operator state. Refresh the live cloud inventory before making cost claims.
