# Deployment Guide to cPanel Node.js

## Prerequisites Checklist

✅ **Already Configured in cPanel (o2switch / CloudLinux nodevenv):**
- Node.js 22.x runtime (e.g. 22.22.3)
- Application root: `uat.agathatrack.com/backend` (on disk: `~/uat.agathatrack.com/backend`)
- Application URL: `uat.agathatrack.com`
- Application startup file: **`bin/start.js`** (see §4 — do **not** use `bin/server.js` on cPanel)
- Environment variables configured:
  - `PGDATABASE`: your_db_name
  - `PGHOST`: localhost
  - `PGPASSWORD`: your_db_password
  - `PGPORT`: 5432
  - `PGUSER`: your_db_user
  - `PORT`: 3000

## Additional Requirements

### 1. **Install Node.js Dependencies**

On o2switch / CloudLinux, **do not** run bare `npm install` in the application root.

Use **cPanel → Setup Node.js App → Run NPM Install** (creates `backend/node_modules` as a symlink into `~/nodevenv/...`).

See `docs/uat-backend-node-modules-runbook.md` for recovery steps and forbidden commands.

### 2. **Verify Database Migration**
The schema is managed by the Node.js migration runner (`server/scripts/migrate.js`) and the canonical schema file `db/migrations/v3__initial_uuid_schema.sql` (19 application tables + a `_migrations` tracker, all UUID-keyed).

For an existing database that needs pending incremental migrations applied:

```bash
cd server
DATABASE_URL="postgresql://..." node scripts/migrate.js up
```

For a brand-new empty database, apply `db/migrations/v3__initial_uuid_schema.sql` directly via `psql`, then mark all incremental migrations as applied via `node scripts/migrate.js up`.

### 3. **Create `.env` File**
cPanel should read environment variables, but create `.env` in your application root as backup:

```
PGUSER=your_db_user
PGPASSWORD=your_db_password
PGHOST=localhost
PGPORT=5432
PGDATABASE=your_db_name
PORT=3000
NODE_ENV=production
JWT_SECRET=change-me-to-a-long-random-string
```

> The Node.js backend resolves the JWT signing key as `JWT_SECRET || SESSION_SECRET`. When `NODE_ENV=production`, the server **refuses to start** if neither is set (no insecure built-in default) — so `JWT_SECRET` must be configured here in the cPanel Node.js app environment. Generate a strong value with `openssl rand -hex 32`. Outside production a dev/test fallback is used so local runs and CI work without extra setup.

### 3b. **Password reset email (SMTP)**

When `NODE_ENV=production`, forgot-password **must** send the 6-digit reset code by email. If SMTP is misconfigured, `POST /backend/api/auth/forgot-password` returns **500** with `{"error":"Request failed"}` for known email addresses (the reset token is rolled back).

Create a sender mailbox in cPanel (**Email Accounts**), then add these variables to the Node.js app environment (or `.env`):

```
UAT_SMTP_HOST=your-server.o2switch.net
UAT_SMTP_PORT=465
UAT_SMTP_SECURE=true
UAT_MAIL_USER=noreply@uat.agathatrack.com
UAT_MAIL_PASS=your-email-account-password
UAT_MAIL_FROM=Agatha Track <noreply@uat.agathatrack.com>
APP_PUBLIC_URL=https://uat.agathatrack.com
```

- `APP_PUBLIC_URL` is the public site URL (no trailing slash) used in branded email links and footers.

**o2switch notes:**
- Use the server hostname from your “Bienvenue chez o2switch” email (`*.o2switch.net`), not always `mail.yourdomain.com`, to avoid SSL certificate errors.
- Port **465** requires `UAT_SMTP_SECURE=true`. If `UAT_SMTP_SECURE` is omitted, the app defaults to secure when the port is 465.
- `UAT_MAIL_USER` must be the **full email address**; the password is the mailbox password (not your cPanel login).
- Legacy names `UAT_mail_user` / `UAT_mail_pass` still work if already set.

After changing these values, **Restart** the Node.js app. Check cPanel error logs for `Password reset email failed` — the underlying SMTP error is logged there.

### 4. **Application startup file (important)**

On o2switch/cPanel, CloudLinux runs the startup file as a **script** (`node <startup-file>`). Use:

| File | Role |
|------|------|
| **`bin/start.js`** | **cPanel startup file** — loads env, imports the Express app, calls `listen()` on `PORT` |
| `bin/server.js` | App module (routes, `/backend/health`) — used by Jest and `start.js`; **not** a cPanel startup file |

Set **Fichier de démarrage** to **`bin/start.js`**.

**Do not** point cPanel at `bin/server.js`: it only exports the Express app (ESM `export default`) and never calls `listen()`, so Passenger/nodevenv will hang or fail to spawn.

**Production mode** in cPanel is fine with `bin/start.js` — it sets `NODE_ENV=production` for error redaction, JWT enforcement, and SMTP.

### 5. **Set Correct File Permissions**
Ensure proper permissions on key files:

```bash
chmod 755 ~/uat.agathatrack.com/backend/bin/start.js
chmod 644 ~/uat.agathatrack.com/backend/.env
chmod 644 ~/uat.agathatrack.com/backend/package.json
```

### 6. **CORS Configuration**
The server includes CORS headers for browser requests. Ensure your Flutter web app can reach:
- `http://uat.agathatrack.com:3000` or configured domain

### 7. **SSL/TLS (HTTPS)**
If using HTTPS, cPanel typically handles this. The backend should work with or without SSL.

### 8. **Restart the Application**
In cPanel, click "Restart":
- Go to **Node.js App Manager**
- Select your application
- Click **Restart**

Then verify:

```bash
curl -sk https://uat.agathatrack.com/backend/health
```

Expected response: `{"status":"OK"}`

### 9. **GitHub Actions SSH (optional)**

When `UAT_SSH_ENABLED=true`, the deploy workflow:

1. Whitelists the GitHub runner IP via o2switch **SshWhitelist** API ([docs](https://faq.o2switch.fr/cpanel/outils/exception-parefeu/))
2. Runs `touch tmp/restart.txt` over SSH (Passenger restart trigger)
3. Removes the runner IP from the whitelist when the job finishes

**Do not** run `npm ci` over SSH on o2switch — it creates a real `backend/node_modules` folder and breaks CloudLinux's symlink. When `package.json` / `package-lock.json` change, use cPanel **Exécuter NPM Install** after deploy.

**PROD environment secrets required for SSH (o2switch firewall whitelist):**

| Secret | Where to get it |
|--------|-----------------|
| `PROD_CPANEL_API_TOKEN` | cPanel → **Security → Manage API Tokens** → Create (copy once) |
| `PROD_SSH_HOST` | Server hostname (e.g. `grenouille.o2switch.net`) |
| `PROD_SSH_USER` | cPanel username (e.g. `bixo5840`) |
| `PROD_SSH_PRIVATE_KEY` | Deploy SSH private key |
| `PROD_SSH_PASSPHRASE` | Optional (only if key has passphrase) |
| `PROD_SSH_PORT` | Optional (default `22`) |

Add these under **GitHub → Settings → Environments → PROD → Environment secrets**.

When `deploy-prod.yml` runs with `PROD_DEPLOY_ENABLED=true`, the workflow:

1. Whitelists the GitHub runner IP via o2switch **SshWhitelist** API ([docs](https://faq.o2switch.fr/cpanel/outils/exception-parefeu/))
2. Runs `node scripts/migrate.js up` and `touch tmp/restart.txt` over SSH (no `npm ci` on CloudLinux)
3. Removes the runner IP from the whitelist when the job finishes

**Do not** run `npm ci` over SSH on o2switch — use cPanel **Run NPM Install** when `package.json` changes.

**Note:** `remove_all` at deploy start clears existing SSH whitelist entries in the cPanel tool (max 5 slots). Re-add your home IP manually in **Exception pare-feu** if you rely on it outside CI.

**Production (agathatrack.com) cPanel layout** — mirrors UAT addon-domain paths:

| Setting | Value |
|---------|-------|
| Application root | `agathatrack.com/backend` (on disk: `~/agathatrack.com/backend`) |
| Application URL | `agathatrack.com` |
| Startup file | `bin/start.js` |
| FTP account directory | `~/agathatrack.com` (FTP login root — **not** a nested subfolder under the domain) |
| FTP frontend target | `./` (relative to FTP root) |
| FTP backend target | `./backend/` |
| SSH site root (on disk) | `~/agathatrack.com` |

**PROD FTP credentials (GitHub → Environments → PROD):**

| Secret | Requirement |
|--------|-------------|
| `PROD_FTP_SERVER` | Same host as UAT (e.g. `grenouille.o2switch.net` or `ftp.agathatrack.com`) |
| `PROD_FTP_USERNAME` | FTP account whose **directory** in cPanel is `agathatrack.com` / `~/agathatrack.com` |
| `PROD_FTP_PASSWORD` | That FTP account's password |

cPanel → **FTP Accounts** → create or edit the prod account so **Directory** is `/home/<cpanel-user>/agathatrack.com` (mirror UAT: UAT FTP logs into `~/uat.agathatrack.com/`, prod into `~/agathatrack.com/`).

**Do not** use an FTP account jailed to a subfolder (e.g. `~/agathatrack.com/PROD_user/`). With `server-dir: ./`, files land in that subfolder — Node/cPanel expect `~/agathatrack.com/backend/package.json`. SSH deploy now fails fast if `package.json` is missing at the app root.

**One-time cleanup after a misplaced deploy:** move `PROD_user/*` (or nested `agathatrack.com/*`) into `~/agathatrack.com/`, fix the FTP account directory, then re-run prod deploy.

**UAT environment secrets required for SSH:**

| Secret | Where to get it |
|--------|-----------------|
| `UAT_CPANEL_API_TOKEN` | cPanel → **Security → Manage API Tokens** → Create (copy once) |
| `UAT_SSH_HOST` | Server hostname (e.g. `grenouille.o2switch.net`) |
| `UAT_SSH_USER` | cPanel username (e.g. `bixo5840`) |
| `UAT_SSH_PRIVATE_KEY` | Deploy SSH private key |
| `UAT_SSH_PASSPHRASE` | Optional (only if key has passphrase) |
| `UAT_SSH_PORT` | Optional (default `22`) |

Add these under **GitHub → Settings → Environments → UAT → Environment secrets** (not repository-level secrets — the deploy job uses `environment: UAT`).

**Note:** `remove_all` at deploy start clears existing SSH whitelist entries in the cPanel tool (max 5 slots). Re-add your home IP manually if you rely on it outside CI.

The SSH step uses `continue-on-error` — FTP deploy still gates smoke/E2E if SSH fails.

## Troubleshooting

### Application won't start?
1. Check Node.js error logs in cPanel: **Error and Debug Logs**
2. **Startup file must be `bin/start.js`** — `bin/server.js` will not listen on cPanel
3. **Environment variables** in cPanel must be `KEY=value` (no bare emails). Values with spaces or `<>` (e.g. `UAT_MAIL_FROM`) can break the CloudLinux `nodevenv` wrapper — use a plain address like `noreply@uat.agathatrack.com` first
4. Verify `.env` file exists and has correct credentials (backup; cPanel env vars are what nodevenv uses at spawn)
5. Verify PostgreSQL connection:
   ```bash
   psql -U your_db_user -h localhost -d your_db_name -c "SELECT 1;"
   ```

### Port conflicts?
- Change `PORT` in `.env` to an available port (3001, 3002, etc.)
- Update cPanel application URL accordingly

### Database connection fails?
- Verify PostgreSQL is running
- Check credentials in `.env`
- Test manually: `psql -U your_db_user -h localhost -d your_db_name`

## API Endpoints

Once deployed, your API will be accessible at:

- **Health Check**: `GET http://uat.agathatrack.com:3000/health`
- **List Pets**: `GET http://uat.agathatrack.com:3000/api/pets`
- **Get Pet**: `GET http://uat.agathatrack.com:3000/api/pets/{id}`
- **Create Pet**: `POST http://uat.agathatrack.com:3000/api/pets` (with JSON body)
- **Update Pet**: `PUT http://uat.agathatrack.com:3000/api/pets/{id}` (with JSON body)
- **Delete Pet**: `DELETE http://uat.agathatrack.com:3000/api/pets/{id}`

## Backend

The repository ships a single **Node.js / Express** backend (`server/bin/start.js`) that serves the API and the Flutter web build.
