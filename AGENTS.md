# Agent entrypoint

This public repository is the portable handoff for Mina Performance Mask.
Read these files in order before making changes:

1. `docs/STATUS.md`: latest dated state, measured results, and next actions.
2. `docs/RUNPOD_LIVE.md`: rebuild, start, connect, verify, and clean up.
3. `docs/ARCHITECTURE.md`: request flow, state ownership, and code map.
4. `docs/HTTP_LATENCY.md`: timing definitions and measurement limitations.
5. `docs/CPU_RENDER.md` only when working on the offline/Thor path.

## Intended product

The owner wants a working browser page: camera in, Mina animation returned
from a Runpod GPU, side by side. A screenshot, benchmark report, or public
sample alone does not satisfy a request to run the live app. When asked to
open the app, open the actual browser URL after checking health. Leave the
service available for the user's session, unless they request cleanup or the
agreed run is explicitly a disposable benchmark. Always state the hourly cost.
A Stop button stops camera transmission; it does not stop GPU billing.

## Current-state discipline

- Git documentation is a dated snapshot, not proof a cloud resource still exists.
  Read the live account before provisioning or assuming a previous URL works.
- The latest owner instruction was to shut down paid resources. Do not reopen
  compute merely to inspect this repo, update docs, or run CPU-only tests.
- On an explicit resume/deploy request, check available credentials and account
  resources first, then current stock, image, price, and the user's budget.
- Never assume a stored IP, Pod ID, or SSH mapping is still current. This public
  repo intentionally contains no private live deployment inventory.
- Persist a new handoff in `docs/STATUS.md` after a material change. Replace stale
  current state; keep the distinction between measured evidence, user feedback,
  and future work. Record what was checked, not only what was intended.
- Update runbooks when behavior changes. A fresh agent should not need chat logs.

## Privacy and permission boundaries

- Publish code and English technical documentation only. UI strings may retain
  the owner's Turkish interface. No media, model weights, motion templates,
  logs, account credentials, private host details, or user recordings in Git.
- Raw performer/Photo Booth videos, their faces in concat outputs, and private
  motion PKLs must never be uploaded to GitHub or another external service.
- The owner explicitly authorized live camera processing and transfer of the
  synthetic Mina source portrait to the specific live Runpod server used on
  2026-10-24. That is not permission to publish media or upload old recordings.
  The server was subsequently deleted. Before a new destination/session,
  establish the current user's media scope from the current request; do not
  treat a public handoff as blanket authorization for somebody else's media.
- Keep live frames in memory; do not add recording, screenshots of the owner,
  frame logging, or third-party forwarding without explicit authorization.
- Inspect staged paths, tracked tree, and content before every commit/push.
  Run `python3 scripts/audit-public-tree.py` after staging; manually review the
  diff too (signature scanning cannot prove the absence of every secret).
  Ignore rules alone are insufficient, especially after `git add -f`.
- Never print tokens or place credentials in commands, logs, commits, or docs.
  Use an existing credential provider or process environment.

## Execution constraints

- Do not retry GPU inference on the tested Jetson AGX Thor stack. It reset the
  board at MAXN and 120 W. CUDA import success does not establish model safety.
  A separate explicit recovery task is required before revisiting this.
- The verified live deployment uses an x86 Runpod CUDA GPU, not Thor CPU.
- Keep the demo server on loopback and reach it via SSH. It is single-client,
  has shared motion reference state, and is not an authenticated public service.
- Respect existing user changes and other cloud resources. Record resources
  created for your task; do not infer ownership from their names.
- Do not leave a disposable test billing. For a user-facing live server, report
  what remains running and how to close it; do not delete it before the user can
  use it. An explicit cleanup request overrides the keep-running instruction.

## Validation and publication

Run `make test` with FFmpeg/FFprobe and Python 3 installed. The HTTP tests use a
fake engine and do not prove CUDA or image quality. `tests/browser-smoke.cjs`
exercises a real running server using public sample media through a fake camera;
it needs Playwright/Chrome and an explicitly authorized running GPU service.
Do not create paid infrastructure only to run this test after cleanup.

The owner's requested GitHub CLI account is `gokselozgur5`; verify `gh api user`
before publication. Do not change another contributor's authored text.
See `docs/STATUS.md` for pending improvements instead of improvising new scope.
