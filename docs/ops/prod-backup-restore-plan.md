---
title: Production backup, restore and deploy safeguards — rollout plan
owner: Documentation Team
audience: both
status: draft
last_updated: 2026-09-29
tags: [ops, deployment, backup, database]
---
# Production backup, restore and deploy safeguards — rollout plan

A step-by-step plan for a human operator and an AI coding agent to work through **together**,
one PR per step, before prod launch. Every step says who does what and how we prove it works.

**How to resume:** open this file, find the first step not marked ✅ in the
[status board](#status-board), and tell the agent: *"Let's do step N of
`docs/ops/prod-backup-restore-plan.md`."*

---

## Why (current state, 2026-09-29)

| Area | Today | Risk |
|------|-------|------|
| DB backups | Only a manual `pg_dump` example in `DEPLOYMENT_DB.md` §7 | No automated backups before launch |
| Deploy safety | `prod-ssh-backend-deploy.sh` runs `migrate.js up` with no snapshot first | A bad migration can only be recovered from the last backup, if there is one |
| Uploaded files | `privateHealthStorage.js` defaults to `<app>/uploads/private_health`, inside the FTP deploy folder | Not in any backup; exposed to deploy mistakes |
| Restore | Never rehearsed; no runbook; no RPO/RTO | Unknown recovery time when it matters |
| Monitoring | Post-deploy smoke only | Silent failure of backups, cron jobs or the site |

Hosting: o2switch shared cPanel (CloudLinux nodevenv), local PostgreSQL, FTP + SSH deploy
driven by `.github/workflows/deploy-prod.yml` and `deploy-uat.yml`.

## Targets

| Metric | Target at launch |
|--------|------------------|
| **RPO** (max data loss) | 24 h (nightly), ~0 for deploys (pre-migration dump) |
| **RTO** (time to restore) | 4 h |
| Off-site copies | Encrypted, EU region, different provider, cannot be deleted by the prod server |
| Restore proof | Automated integrity check nightly + full human drill monthly |

## Principles

1. **UAT first.** Every script and cron job ships to UAT, runs there for a few days, then is enabled on prod.
2. **Automation as code.** Scripts, cron schedules and checks live in the repo and are installed by the deploy workflows — nothing hand-typed on the server that isn't also in git.
3. **Fail loud.** Every automated job pings a dead man's switch; silence alerts you.
4. **The server can write backups but cannot read or delete them.** Encrypt with a public key (private key stays offline); off-site credentials are write-only / object-locked.
5. **Test the code, then test the outcome.** Shell tests in `scripts/ci/*.test.sh` / `*.test.js` for logic; real restores for outcome.
6. **One atomic PR per step** (per `.cursor/rules/atomic-pr.mdc`), each with docs updated in the same PR.

---

## Decisions to take before Step 1 (you)

| # | Decision | Recommendation | Your choice |
|---|----------|----------------|-------------|
| D1 | Off-site storage provider (S3-compatible, EU) | Scaleway Object Storage (Paris) or Hetzner Object Storage — both support object lock | |
| D2 | Encryption tool | `age` (static binary in `~/bin`, public-key only on server); fallback `gpg` if the binary can't run on CloudLinux | |
| D3 | Alerting service (dead man's switch + uptime) | healthchecks.io (EU-hosted) for jobs + Better Stack or UptimeRobot for `/backend/health` | |
| D4 | Retention | 7 daily · 4 weekly · 6 monthly (and update privacy notice to say so) | |
| D5 | Where the private decryption key lives | Password manager + one offline copy (printed / USB in a safe) | |
| D6 | Full automated restore test in CI? | **No** at launch (would copy health data through GitHub, a US processor). Monthly human drill instead; revisit later | |

---

## Status board

| Step | Title | PR | Status |
|------|-------|----|--------|
| 0 | Pre-flight: accounts, keys, repo hygiene | — | ⬜ |
| 1 | Backup script + tests (runs locally/CI) | | ⬜ |
| 2 | Off-site upload + encryption | | ⬜ |
| 3 | Cron-as-code, installed by deploy (UAT) | | ⬜ |
| 4 | Move uploads out of the deploy folder | | ⬜ |
| 5 | Pre-migration dump in deploy workflows | | ⬜ |
| 6 | Restore script + restore runbook | | ⬜ |
| 7 | Nightly integrity check + monitoring | | ⬜ |
| 8 | Enable on prod + first full restore drill | | ⬜ |
| 9 | Least-privilege DB users + secrets escrow | | ⬜ |
| 10 | Deploy & rollback runbook, launch checklist | | ⬜ |

Legend: ⬜ not started · 🟡 in progress · ✅ done (link PR)

---

## Step 0 — Pre-flight (mostly you, ~1 h)

**You**
- [ ] Check `new-key.asc` and `gpg-check.txt` in the repo root. If either contains a **private** key, delete the file, rotate that key, and tell the agent (history cleanup is a separate decision).
- [ ] Take decisions D1–D6 above and fill in the table.
- [ ] Create the storage bucket(s): `agatha-backups-uat`, `agatha-backups-prod`, EU region, **object lock / versioning on**, lifecycle rule matching D4.
- [ ] Create **two** access keys per bucket: *write-only* (for the server) and *read-only* (for restores). Store both in the password manager.
- [ ] Generate the backup key pair on your own machine: `age-keygen -o agatha-backup.key`. Keep the private file offline (D5); give the agent only the `public key:` line.
- [ ] Create healthchecks.io checks: `uat-backup`, `prod-backup`, `prod-audit-retention`, and an uptime monitor on `https://agathatrack.com/backend/health`.
- [ ] Confirm via SSH on o2switch: `pg_dump --version`, `pg_restore --version`, and whether `~/bin` is on `PATH`.

**Agent**
- [ ] List every GitHub environment secret/variable the later steps need, and where each is used.

**Done when:** decisions table filled, secrets stored, tool versions noted in this file.

---

## Step 1 — Backup script (PR 1)

**Agent**
- [ ] `scripts/ops/backup.sh`: `pg_dump -Fc` of the DB + `tar` of the uploads dir → timestamped files in `~/agatha-backups/<env>/`; SHA-256 manifest; strict mode; refuses to run without `APP_ENV`.
- [ ] Verifies the dump before declaring success: `pg_restore --list` must succeed and contain `_migrations`.
- [ ] Local retention pruning (keep last N, configurable).
- [ ] Tests `scripts/ops/backup.test.sh` against the local dev Postgres: happy path, DB unreachable, disk-full simulation, pruning.
- [ ] Document usage in `DEPLOYMENT_DB.md` §7 (replace the plain `pg_dump` example).

**You:** review the PR; run it once by hand on UAT over SSH.

**Done when:** tests green in CI; a manual UAT run produces a dump you can list with `pg_restore --list`.

## Step 2 — Encryption + off-site copy (PR 2)

**Agent**
- [ ] Extend `backup.sh`: encrypt with `age -r <public key>`, upload with `rclone` to the bucket, verify remote checksum, then delete the local plaintext.
- [ ] `scripts/ops/install-tools.sh`: idempotent install of pinned `age` + `rclone` static binaries into `~/bin` with checksum verification.
- [ ] Tests with a local MinIO/fake remote in CI: upload, checksum mismatch → failure, missing key → failure, plaintext never left behind.

**You:** add the write-only bucket key to the UAT GitHub environment; run on UAT; confirm the object appears in the bucket and **that the server key cannot delete it**.

**Done when:** encrypted backup visible in the UAT bucket; a delete attempt with the server key is refused.

## Step 3 — Cron-as-code on UAT (PR 3)

**Agent**
- [ ] `ops/cron/<env>.crontab` in the repo (backup nightly, `audit-retention.js` daily).
- [ ] Deploy step (UAT workflow) installs it idempotently between `# BEGIN agatha` / `# END agatha` markers, keeping any other cron lines untouched; guarded by `scripts/ci/assert-prod-deploy-db-commands.sh` updates.
- [ ] Each job wrapped to ping healthchecks.io start/success/fail.
- [ ] Tests for the crontab merge logic (existing lines preserved, re-run is a no-op).

**You:** check cPanel → Cron Jobs shows the lines; confirm healthchecks turns green after the first night.

**Done when:** 3 consecutive green nightly runs on UAT.

## Step 4 — Uploads outside the deploy folder (PR 4)

**Agent**
- [ ] Set `PRIVATE_HEALTH_UPLOAD_DIR` (and any other upload roots) to `~/agatha-data/<env>/…`; one-off migration script to move existing files; startup check that the dir exists and is writable.
- [ ] Tests in `server/test` for the resolved paths; update `DEPLOYMENT_CPANEL_NODEJS.md`.
- [ ] Read `.cursor/agent-kernel/protocols/private-files.md` and follow it.

**You:** set the env var in cPanel for UAT, restart, upload a test document, confirm it lands in the new dir and is in the next backup.

**Done when:** UAT uploads live outside the app root and appear in the backup archive.

## Step 5 — Pre-migration dump in deploys (PR 5)

**Agent**
- [ ] In `prod-ssh-backend-deploy.sh` (and the UAT equivalent): run `backup.sh --reason pre-deploy --tag <sha>` **before** `migrate.js up`; abort the deploy if it fails; skip the upload when no migration is pending (dump still local).
- [ ] Update the bundle sentinel checks in `prepare-prod-ssh-remote.sh`.
- [ ] Tests: pending-migration detection, failure aborts before migrate.

**You:** trigger a UAT deploy containing a harmless migration; see the pre-deploy dump in the run log and bucket.

**Done when:** a UAT deploy shows `pre-deploy backup OK` before `migrate.js up`.

## Step 6 — Restore script + runbook (PR 6)

**Agent**
- [ ] `scripts/ops/restore.sh`: fetch (read-only key) → decrypt (private key supplied at runtime, never stored) → `pg_restore` into a **named target DB** → restore uploads to a target dir → sanity checks (row counts, `_migrations` head, sample login query). Refuses to target the live prod DB unless `--i-mean-prod` is given and the app is in maintenance.
- [ ] `docs/ops/restore-runbook.md`: scenarios (bad migration, accidental data deletion, server lost, single-user data request), step-by-step commands, expected timings, who to notify (GDPR breach clock if relevant).
- [ ] Tests: restore from a fixture backup into the local Postgres, including a schema-only sanity check.

**You + agent together:** first restore of a real UAT backup into a scratch DB, timing each step (this is our first RTO measurement).

**Done when:** UAT restore succeeds end-to-end and the measured time is recorded in the runbook.

## Step 7 — Integrity checks + monitoring (PR 7)

**Agent**
- [ ] Nightly job verifies: yesterday's object exists off-site, size within ±X % of the previous day, checksum matches manifest; pings healthchecks.
- [ ] Weekly GitHub Actions workflow (no data access) checking healthchecks.io status via API and opening a GitHub issue if a check is down.
- [ ] Update `docs/ops/observability.md` with the new signals.

**You:** configure alert destinations (email + phone) in healthchecks.io and the uptime monitor; test by pausing a check.

**Done when:** a deliberately broken backup produces an alert within 24 h.

## Step 8 — Enable on prod + first drill (PR 8)

**Agent**
- [ ] Add the prod crontab and enable the same steps in `deploy-prod.yml`.
- [ ] Add a "Backups" section to the prod deploy job summary (last backup age, pre-deploy dump name).

**You:** add prod secrets to the PROD environment; set `PRIVATE_HEALTH_UPLOAD_DIR` in prod cPanel; run the first **full restore drill** from the prod bucket into a scratch DB on your machine or UAT (agent guides live).

**Done when:** prod has 3 green nights + one successful drill logged in the runbook.

## Step 9 — Least privilege + secrets escrow (PR 9)

**Agent**
- [ ] Migration adding roles: `agatha_app` (DML only) and `agatha_migrator` (DDL); `migrate.js` reads `MIGRATION_DATABASE_URL` when set. Follow `.cursor/agent-kernel/protocols/database-and-migrations.md`.
- [ ] Startup check warning if the app user can run DDL.
- [ ] `docs/ops/secrets-inventory.md`: every secret, where it lives, how to rotate — **names only, never values**.

**You:** create the DB users in cPanel, update env vars on UAT then prod; put `JWT_SECRET`, `AUDIT_PSEUDONYM_SALT`, DB passwords and the backup private key in the password manager + offline copy.

**Done when:** app runs on UAT and prod with the DML-only user; secrets inventory reviewed.

## Step 10 — Deploy & rollback runbook + launch checklist (PR 10)

**Agent**
- [ ] `docs/ops/deploy-runbook.md`: normal promotion path, rollback of code (re-dispatch `deploy-prod.yml` with the previous `prod` tag), when to restore data vs fix forward, expand-and-contract rules, the manual "Run NPM Install" step as an explicit checklist item, maintenance mode.
- [ ] A rollback rehearsal on UAT (deploy tag N, roll back to N-1, smoke green).
- [ ] `docs/ops/launch-checklist.md` linking everything above; link all new docs from `docs/README.md`.
- [ ] Update privacy notice / `regulatory/DATA_MAP.md` with backup location and retention (D4).

**You:** do one timed rollback rehearsal yourself following only the runbook.

**Done when:** rehearsal passes without help from the agent → **prod-ready for data safety**.

---

## Later (after launch)

- Move to managed EU PostgreSQL with point-in-time recovery (Scaleway / OVH / Neon EU) once there is real user volume: RPO drops from 24 h to minutes.
- Quarterly drill cadence; annual secrets rotation.
- Revisit D6 (automated full restore test) with an EU-hosted runner.

## Related

- [DEPLOYMENT_DB.md](../../DEPLOYMENT_DB.md) · [DEPLOYMENT_CPANEL_NODEJS.md](../../DEPLOYMENT_CPANEL_NODEJS.md)
- [observability.md](observability.md) · [public-access.md](public-access.md)
- `.github/workflows/deploy-prod.yml` · `scripts/ci/prod-ssh-backend-deploy.sh`
