# Run, resume, and close Mina Live

Read `STATUS.md` first. The last deployment was deleted at the owner's request.
This runbook is a procedure, not authorization to spend or transfer private media.

## 1. Check the account before renting

Use the configured Runpod MCP or current `runpodctl`. Check existing credentials
without printing their values. Do not paste a token into a command or this repo.
Read the account balance, existing resources, current GPU availability by data
center, hourly price, and official image catalog. Respect the user's budget.

The tested baseline was one Secure Cloud RTX 4090 or RTX 5090 in EU-RO-1,
30 GB ephemeral container disk, no network volume, SSH port 22 only, and
`runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`. Revalidate availability and the
image before create. The SSH public key must be registered or injected at create;
keep the private key on the client. Do not expose Jupyter or a public web port.

For an authorized deployment, this CLI shape was checked against runpodctl 3.0.1
help (refresh help if using another release):

```bash
runpodctl pod create \
  --name mina-live-camera \
  --cloud-type SECURE \
  --image runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404 \
  --gpu-id 'NVIDIA GeForce RTX 5090' --gpu-count 1 \
  --min-cuda-version 12.8 \
  --data-center-ids EU-RO-1 \
  --container-disk-in-gb 30 \
  --ports 22/tcp --ssh --wait
```

Use the GPU/region verified in the fresh stock read. Do not blindly retry create
on failure: a timeout can leave a billable Pod. Record its ID privately and read
it back. Get its current SSH mapping; validate the host-key fingerprint against
the Pod's boot log before sending an approved portrait. A Running state alone
is not application readiness.

## 2. Prepare the code and models on the GPU host

Connect over SSH. Clone only public source code:

```bash
cd /workspace
git clone https://github.com/gokselozgur5/mina-performance-mask.git
cd mina-performance-mask
git rev-parse HEAD  # record the deployed application commit in private operator state
./scripts/setup-runpod-live.sh /workspace/mina-runtime
```

The installer uses `config/upstream.env.example`, pins the upstream source and
model revisions, retains the image's PyTorch, and creates an isolated environment
with system packages visible. It refuses a mismatched/modified existing checkout
rather than overwriting it. It targets x86_64 and must not be used to retry Thor
GPU inference. Core pins match the tested manual setup, but transitive Python
packages are not fully locked. The packaged installer was syntax-checked and the portable browser harness
passed against a local CPU echo fixture; neither is a new GPU performance test. No
new paid deployment was created solely to retest packaging after cleanup.

Allow several minutes for first installation and model download. On the tested
5090, first face-analysis warmup took about 23 seconds; do not declare failure
because health is unavailable before the READY log line.

## 3. Select the source without leaking media

For an initial check, use the public upstream portrait:

```bash
export MINA_SOURCE=/workspace/mina-runtime/LivePortrait/assets/examples/source/s9.jpg
```

For Mina, obtain the owner's synthetic source portrait locally. Transfer only
that specifically approved file over SSH to a private path, then point
`MINA_SOURCE` at it. Do not copy an entire artifacts directory or use a wildcard:
that directory can also contain the owner's raw face video and concat output.
Do not upload historical performer videos or motion PKLs for this live demo.
The portrait is intentionally absent from Git; do not replace it with an
invented character and claim it is the same Mina.

## 4. Start the server

Public sample mode, camera disabled:

```bash
cd /workspace/mina-performance-mask
/workspace/mina-runtime/venv/bin/python live/server.py \
  --upstream /workspace/mina-runtime/LivePortrait \
  --source "$MINA_SOURCE" \
  --sample /workspace/mina-runtime/LivePortrait/assets/examples/driving/d0.mp4
```

After explicit permission for live camera processing, add `--allow-camera`.
Use tmux or nohup for a persistent server; keep startup logs private and do not
add frame/body logging. For example, with MINA_SOURCE exported:

```bash
nohup /workspace/mina-runtime/venv/bin/python live/server.py \
  --upstream /workspace/mina-runtime/LivePortrait \
  --source "$MINA_SOURCE" \
  --sample /workspace/mina-runtime/LivePortrait/assets/examples/driving/d0.mp4 \
  --allow-camera > /workspace/mina-server.log 2>&1 < /dev/null &
```

Wait for `READY 127.0.0.1:8765`, then check on the host:

```bash
curl --fail http://127.0.0.1:8765/health
```

Unexpected startup/inference failure: inspect the private startup log and test
with the public sample. Do not use private camera screenshots for diagnostics.

## 5. Connect the user's browser

On the user's Mac, use the freshly read host, port, and matching SSH key:

```bash
ssh -N -L 127.0.0.1:18765:127.0.0.1:8765 \
  -i /path/to/private-key \
  -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
  USER@GPU_HOST -p SSH_PORT
```

Keep this tunnel alive in a separate terminal or local tmux session. Check
`http://127.0.0.1:18765/health` from the client. Then open the actual page:

```bash
open -a 'Google Chrome' http://127.0.0.1:18765
```

Click **Kamerayı başlat** (Start camera) and grant the browser's camera permission.
Face forward for the first frame. **Durdur** (Stop) ends capture/transmission.
The camera API needs a secure context; localhost works. Do not replace localhost
with an arbitrary plain-HTTP LAN IP. This SSH design serves this client's browser,
not a public URL usable from any device. The tunnel is encrypted even though
its loopback URLs use HTTP.

A health 200 is necessary but insufficient: prove one rendered public frame and
check that Stop ends media tracks. `tests/browser-smoke.cjs` can do this with a
public fake camera and an installed Playwright/Chrome; no user's face is needed.

## 6. Handoff or cleanup

For a requested live session, leave the verified server/tunnel available. Return
the actual URL, cloud resource ID privately, hourly cost, and camera-start action.
Do not substitute an image of the UI or destroy the Pod before the user tries it.

When the owner says to close paid resources, terminate the task's Pod:

```bash
runpodctl pod delete POD_ID
runpodctl pod list
```

Termination removes that Pod's ephemeral installation/source file. Retrieve only
needed code/numerical evidence first; never collect the owner's camera frames.
Stop alone can retain billable disk; independent volumes survive Pod deletion.
Check Pods, endpoints, volumes, and clusters by fresh reads. Only change resources
within the user's authorization. Close the local tunnel and update `STATUS.md`
to OFF. An open localhost tab is not proof anything is still billing.

## Optional repeatable browser smoke

On the client, with Chrome and Node available, prepare only the upstream public
sample as a fake camera. For example, after obtaining upstream `d0.mp4`:

```bash
mkdir -p runtime
ffmpeg -i /path/to/public/d0.mp4 -vf scale=640:480 \
  -pix_fmt yuv420p -f yuv4mpegpipe runtime/public-camera.y4m
npm install --prefix runtime/browser-tools playwright@1.64.1
PLAYWRIGHT_MODULE="$PWD/runtime/browser-tools/node_modules/playwright" \
  node tests/browser-smoke.cjs \
  --fake-camera runtime/public-camera.y4m \
  --output runtime/browser-smoke.json
```

The already-running server must have `--allow-camera`; the test grants camera
permission only to a separate headless browser using the specified public fake
camera. It checks 20 returned frames and Stop, and saves numerical data only.
No physical-camera fallback is allowed. Use a fresh output filename if evidence
must be preserved. These steps do not start or stop any cloud resource.
