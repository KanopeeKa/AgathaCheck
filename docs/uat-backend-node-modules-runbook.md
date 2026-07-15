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

When `UAT_SSH_ENABLED=true`:

1. FTP deploys code only (never `node_modules` or `backend/.htaccess`).
2. SSH runs `scripts/ci/uat-ssh-backend-deploy.sh` (bundled):
   - **Pre-restart:** `assert-node-modules-symlink` (blocking)
   - `touch tmp/restart.txt`
   - **Post-restart:** invariant with 3 retries / 10s (~30s)
3. Deploy **fails** on exit codes:
   - `10` — missing
   - `11` — real directory
   - `12` — broken symlink / wrong target

Deploy summary records: `node_modules_kind`, `node_modules_target`, `passenger_htaccess_ok`, `server_hostname`, `node_major`, `app_root`.

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
