---
title: Cursor Cloud environment
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-13
tags: [agent, engineering, cursor, environment]
---

# Cursor Cloud environment

Cursor Cloud Agents only. Shared toolchain and commands: [`AGENTS.md`](../../AGENTS.md) §Toolchain.

- Flutter 3.44.0 at `/opt/flutter/bin`, provisioned by `.cursor/Dockerfile`
- Environment: `.cursor/environment.json` + `.cursor/Dockerfile` — install/start via `.cursor/scripts/cloud-*.sh`

If a Cloud Agent pod reports missing `flutter` or `pg_ctlcluster`, confirm the repo uses Dockerfile mode (no `snapshot`
field in `.cursor/environment.json`) and rebuild — see below.

## Rebuild after a toolchain bump

The Flutter SDK is baked into the image via `.cursor/Dockerfile` (`FLUTTER_VERSION=3.44.0`). After a toolchain bump,
**new pods must rebuild** from that Dockerfile — `cloud-install.sh` only runs `pub get` / `npm ci`, it does not upgrade
`/opt/flutter`.

**Operator steps** (when agents still show Flutter 3.32 or `cloud-install.sh` fails the version gate):

1. Open [Cloud Agents → Environments](https://cursor.com/dashboard/cloud-agents#environments) for this repo.
2. Delete the saved environment for AgathaCheck, **or** create a fresh environment from the repo (do not use the
   interactive wizard snapshot — it ignores `build.dockerfile`).
3. Confirm `.cursor/environment.json` has `build.dockerfile` only — **no** `snapshot` field.
4. Start a new Cloud Agent from `main` (or a branch that includes the latest `.cursor/Dockerfile`).
5. Verify: `flutter --version` → **3.44.0** and `dart --version` → **3.12.x**.

`cloud-install.sh` fails fast when `/opt/flutter` exists but is the wrong version, with the message above.
