# UAT backend `node_modules` runbook (CloudLinux / o2switch)

Operational contract for **Agatha Track UAT** (`uat.agathatrack.com`).

## Invariant

`~/uat.agathatrack.com/backend/node_modules` **must be a symlink** into:

`~/nodevenv/uat.agathatrack.com/backend/<node-version>/lib/node_modules`

Never a real directory in `backend/`.

## Forbidden on UAT

| Action | Why |
|--------|-----|
| `npm ci` or `npm install` in `backend/` without nodevenv activate | Creates real `backend/node_modules/` |
| Deleting `backend/.htaccess` | Breaks Passenger |
| Uploading `backend/.htaccess` via FTP | Overwrites cPanel Passenger config |
| FTP-uploading `node_modules/` | Breaks CloudLinux symlink model |
| `rm -rf ~/uat.agathatrack.com/backend` | Destroys Passenger config + symlink |

## Manual recovery (one-time or after drift)

1. **cPanel → File Manager** → show hidden files → `uat.agathatrack.com/backend/`
2. If `node_modules` is a **folder** (not `->` symlink), **delete it**.
3. **cPanel → Setup Node.js App**
   - Application root: `uat.agathatrack.com/backend`
   - Startup file: `bin/start.js`
4. Click **Run NPM Install** (creates the nodevenv symlink).
5. Click **Restart**.
6. Verify over SSH:
   ```bash
   ls -la ~/uat.agathatrack.com/backend/node_modules
   curl -sk https://uat.agathatrack.com/backend/health
   ```

## CI automation (deploy-uat.yml)

**Requires `UAT_SSH_ENABLED=true`** and `appleboy/ssh-action` pinned to **full commit SHA ≥ v1.2.2** (`script_path`; v1.0.x silently no-ops). Guard: `scripts/ci/check-uat-ssh-action-pin.sh`.

Remote script prints log sentinels **`UAT_SSH_DEPLOY_BEGIN`** / **`UAT_SSH_DEPLOY_END`** and writes proof fields to `~/.uat-deploy-state.env`.

When enabled:

1. FTP deploys code only (never `node_modules` or `backend/.htaccess`).
2. SSH runs `scripts/ci/uat-ssh-backend-deploy.sh` (bundled):
   - **Pre-restart:** `assert-node-modules-symlink` (blocking)
   - `touch tmp/restart.txt`
   - **Post-restart:** invariant with 3 retries / 10s (~30s)
3. Deploy **fails** on exit codes:
   - `10` — missing
   - `11` — real directory
   - `12` — broken symlink / wrong target

When **disabled:** symlink checks are skipped (`node_modules_kind=not_verified`, `ssh_invariant_enforced=false`, `deploy_verification=unverified`). Manual `workflow_dispatch` deploys fail unless `allow_unverified_deploy=true`. Push deploys warn in the Actions summary.

**Summary signals (distinct):**

| Field | Meaning |
|-------|---------|
| `ssh_invariant_enforced` | Policy — `UAT_SSH_ENABLED=true` |
| `ssh_invariant` | Execution — `passed` / `failed` / `skipped` (whitelist, SSH, or invariant) |
| `deploy_verification` | `verified` only when **all** proofs pass: `ssh_invariant=passed`, `node_modules_kind=symlink`, `passenger_htaccess_ok=true`, `state_collected=true`, `ssh_deploy_end=true`, fresh `restart_txt_epoch` |
| `pre_smoke_ok` | Job output — smoke blocked when `false` and SSH enforced |
| `ssh_proofs_ok` | Aggregate proof gate result |

Deploy summary records: `deploy_verification`, `ssh_proofs_ok`, `state_collected`, `ssh_invariant_enforced`, `ssh_invariant`, `node_modules_kind`, `restart_txt_epoch`, fingerprint fields.

**Proof failures:** `workflow_dispatch` deploys **fail** when SSH ran but proofs are missing; push deploys **warn** and block smoke via `pre_smoke_ok=false`.

## Emergency bypass (`allow_unverified_deploy`)

Use only for **incidents** when SSH automation is temporarily unavailable and a manual deploy cannot wait.

**Who:** release owner or on-call with explicit sign-off (note in the linked issue or deploy thread).

**When allowed** (`workflow_dispatch` + `allow_unverified_deploy=true`):

1. Complete the deploy knowing `deploy_verification=unverified`.
2. **Required follow-up before calling UAT healthy:**
   - SSH to UAT (or cPanel File Manager) and verify symlink:
     ```bash
     ls -la ~/uat.agathatrack.com/backend/node_modules
     ```
   - `curl -sk https://uat.agathatrack.com/backend/health` → HTTP 200
   - If `server/package*.json` changed: cPanel → **Run NPM Install** → **Restart**
3. Restore `UAT_SSH_ENABLED=true` and re-run a normal deploy to obtain `deploy_verification=verified`.
4. Record what broke (whitelist, secrets, connectivity) and fix root cause.

**Policy after rollout stabilizes:** once **3 consecutive** UAT deploys show `deploy_verification=verified`, treat `allow_unverified_deploy=true` as **incident-only** — do not use for convenience deploys.

## When `server/package*.json` changes

Until Phase 3 (`cloudlinux-selector`) is enabled:

1. Complete the deploy (code FTP + restart).
2. **Manually:** cPanel → **Run NPM Install** → **Restart**.
3. Re-run deploy or verify health.

The workflow writes a **Dependencies changed** banner in the Actions summary.

## Diagnostics

On the server:

```bash
bash scripts/uat-diagnose.sh
# or
UAT_APP_DIR=~/uat.agathatrack.com/backend bash scripts/ci/assert-node-modules-symlink.sh --phase post
```

## Related docs

- `docs/github-issue-workflow.md` — UAT CD notes
- `DEPLOYMENT_CPANEL_NODEJS.md` — cPanel setup
- `docs/ci-cd-gates.md` — deploy gates
