# Deployment Guide to cPanel Node.js

## Prerequisites Checklist

✅ **Already Configured in cPanel:**
- Node.js 10.24.1 runtime
- Application root: `uat.agathatrack.com/backend`
- Application URL: `uat.agathatrack.com:backend`
- Application startup file: `server`
- Environment variables configured:
  - `PGDATABASE`: your_db_name
  - `PGHOST`: localhost
  - `PGPASSWORD`: your_db_password
  - `PGPORT`: 5432
  - `PGUSER`: your_db_user
  - `PORT`: 3000

## Additional Requirements

### 1. **Install Node.js Dependencies**
Run this on your server via SSH or cPanel terminal:

```bash
cd ~/public_html/uat.agathatrack.com/backend
npm install
```

This will install:
- `express` - Web framework
- `pg` - PostgreSQL client
- `uuid` - UUID generation
- `body-parser` - JSON parsing
- `dotenv` - Environment variable management
- `express-cors` - CORS support

### 2. **Verify Database Migration**
The schema is now managed by the Dart migration runner (`server/bin/migrate.dart`) and the canonical schema file `db/migrations/v3__initial_uuid_schema.sql` (19 application tables + a `_migrations` tracker, all UUID-keyed).

For a brand-new empty database, run the fresh-install command from a machine that has Dart and access to the cPanel Postgres:

```bash
cd server
DATABASE_URL="postgresql://your_db_user:your_db_password@localhost:5432/your_db_name" \
MIGRATE_CONFIRM=DROP_ALL \
dart run bin/migrate.dart fresh
```

For an existing database that just needs pending incremental migrations applied:

```bash
cd server
DATABASE_URL="postgresql://..." dart run bin/migrate.dart up
```

If Dart is not available on the cPanel host, run the migration from your dev machine while pointing `DATABASE_URL` at the remote database (or apply `db/migrations/v3__initial_uuid_schema.sql` directly via `psql` against an empty DB).

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

### 4. **Verify Application Startup File**
Your application startup file is named `server`, which cPanel will run as:
```bash
node server
```

**But the actual Node.js entry point is `bin/server.js`.**

**Solution**: Create a file named `server` (no extension) in your application root:

```bash
#!/usr/bin/env node
require('./bin/server.js');
```

**Or, update cPanel's "Application startup file" to: `bin/server.js`**

### 5. **Set Correct File Permissions**
Ensure proper permissions on key files:

```bash
chmod 755 ~/public_html/uat.agathatrack.com/backend/bin/server.js
chmod 644 ~/public_html/uat.agathatrack.com/backend/.env
chmod 644 ~/public_html/uat.agathatrack.com/backend/package.json
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

Then verify: `curl -X GET http://uat.agathatrack.com:3000/health`

Expected response: `{"status":"OK"}`

## Troubleshooting

### Application won't start?
1. Check Node.js error logs in cPanel: **Error and Debug Logs**
2. Verify `.env` file exists and has correct credentials
3. Verify PostgreSQL connection:
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

## Dart vs Node.js Backends

The repository ships **two interchangeable backends** that share the same Postgres schema and expose the same routes:

- **Dart / Shelf** (`server/bin/server.dart`) — used by the Replit workflow and the AOT-compiled production binary
- **Node.js / Express** (`server/bin/server.js`) — used here on cPanel because cPanel Node.js hosting doesn't support a Dart runtime

Both are kept in sync (parity is enforced by the test suites — ~338 Jest tests for Node.js, plus Dart `shelf` tests). Either can serve any database created by `migrate.dart`.
