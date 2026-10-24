# Architecture and code map

```text
Browser camera or public sample video
  -> canvas downscale (at most 640 x 480)
  -> JPEG quality 80
  -> POST /frame (one request at a time)
  -> localhost:18765 SSH tunnel -> GPU loopback:8765
  -> JPEG decode, face crop, motion extraction
  -> first-frame-relative pose/expression/scale/translation
  -> stitching + source lip normalization
  -> warp/decode + pasteback onto cached portrait
  -> JPEG quality 80 response
  -> browser image decode and canvas draw
```

The source image is loaded once and resized to a maximum dimension of 960.
Source features/keypoints and the pasteback transform remain resident. The
first driving frame's motion remains in process memory until reset/restart.
No input/output frame is written by the live service. The source portrait and
model files are still disk files. Provider-level retention is outside this
application's guarantees.

## Components

| Path | Responsibility |
| --- | --- |
| `live/server.py:PortraitEngine` | GPU setup, source cache, relative animation |
| `live/server.py:DemoServer` | Shared single-client state and nonblocking GPU lock |
| `live/server.py:Handler` | HTTP bounds, origin checks, response timing, no access logs |
| `live/index.html` | Camera permission, frame capture, backpressure, Stop and timing UI |
| `scripts/setup-runpod-live.sh` | Pinned upstream/environment/model preparation on an already rented x86 GPU host |
| `scripts/render-liveportrait.sh` | Offline upstream invocation; CPU default and empty-input rejection |
| `tests/test-live-http.py` | Fake-engine HTTP boundary tests |
| `tests/browser-smoke.cjs` | Real-server fake-camera Start/Stop check, no private camera |

## HTTP contract

- `GET /`: browser page.
- `GET /health`: ready after model initialization, camera UI flag, app source label.
  `source: Mina` is an app label, not image-identity attestation.
- `GET /sample.mp4`: configured public sample file.
- `POST /frame`: JPEG bytes with `Content-Type: application/octet-stream`;
  returns `image/jpeg`, `X-Inference-Ms`, and `X-Server-Ms`.
- `POST /reset`: empty binary body; clears the first-frame motion reference.
- `POST /echo`: binary transport probe without inference.

Requests are bounded to 2 MiB; decoded dimensions must be 64–1280 on both axes.
Chunked uploads are rejected. The browser uses Content-Length through fetch.
A failed origin check returns 403; unsupported content type 415; malformed/large
length 413; invalid/no-face image 422; occupied GPU lock 429; unexpected inference
failure 500. Responses use `Cache-Control: no-store`. The server does not log
request bodies, images, or access lines. Generic 500 messages intentionally do
not dump input data; diagnosing a failure needs a controlled non-private test.

Only localhost origins on port 18765 are accepted when an Origin header exists.
Native clients without Origin are allowed. This is not authentication; security
relies on the loopback bind and authenticated SSH tunnel. Do not broaden binds
or CORS to expose this unmodified prototype publicly.

## Lifetimes and cancellation

The browser's generation counter prevents a stopped/old request from drawing
into a new run. Stop aborts the current fetch, releases media tracks, and pauses
the sample. It does not preempt GPU execution. The nonblocking server lock
rejects competing work instead of queuing it. Models stay loaded until the
process ends; the cloud resource keeps billing until stopped/terminated.

The current source is a lightweight adaptation of the pinned upstream image
pipeline. It deliberately redetects each driving frame instead of using the
upstream full-video landmark tracker. It therefore needs its own temporal
quality validation and must not be described as bit-identical to offline output.
