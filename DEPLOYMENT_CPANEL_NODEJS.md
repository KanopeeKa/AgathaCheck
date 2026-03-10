# Deployment Guide to cPanel Node.js

## Prerequisites Checklist

✅ **Already Configured in cPanel:**
- Node.js 10.24.1 runtime
- Application root: `uat.agathatrack.com/backend`
- Application URL: `uat.agathatrack.com:backend`
- Application startup file: `server`
- Environment variables configured:
  - `PGDATABASE`: bixo5840_agathatrack_uat
  - `PGHOST`: localhost
  - `PGPASSWORD`: btTdQ@g0tTf#C$jr7r@
  - `PGPORT`: 5432
  - `PGUSER`: bixo5840_pg_uat
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
Ensure the PostgreSQL database has the required schema:

```sql
-- The pets table should exist with these columns:
-- id (VARCHAR), user_id (INTEGER), name (VARCHAR), species (VARCHAR),
-- breed (VARCHAR), age (DOUBLE), date_of_birth (DATE), weight (DOUBLE),
-- gender (VARCHAR), created_at (TIMESTAMPTZ), updated_at (TIMESTAMPTZ)
```

Run the migration if not applied:
```bash
psql -U bixo5840_pg_uat -h localhost -d bixo5840_agathatrack_uat < ../../../db/migrations/v1__initial.sql
```

### 3. **Create `.env` File**
cPanel should read environment variables, but create `.env` in your application root as backup:

```
PGUSER=bixo5840_pg_uat
PGPASSWORD=btTdQ@g0tTf#C$jr7r@
PGHOST=localhost
PGPORT=5432
PGDATABASE=bixo5840_agathatrack_uat
PORT=3000
NODE_ENV=production
```

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
   psql -U bixo5840_pg_uat -h localhost -d bixo5840_agathatrack_uat -c "SELECT 1;"
   ```

### Port conflicts?
- Change `PORT` in `.env` to an available port (3001, 3002, etc.)
- Update cPanel application URL accordingly

### Database connection fails?
- Verify PostgreSQL is running
- Check credentials in `.env`
- Test manually: `psql -U bixo5840_pg_uat -h localhost -d bixo5840_agathatrack_uat`

## API Endpoints

Once deployed, your API will be accessible at:

- **Health Check**: `GET http://uat.agathatrack.com:3000/health`
- **List Pets**: `GET http://uat.agathatrack.com:3000/api/pets`
- **Get Pet**: `GET http://uat.agathatrack.com:3000/api/pets/{id}`
- **Create Pet**: `POST http://uat.agathatrack.com:3000/api/pets` (with JSON body)
- **Update Pet**: `PUT http://uat.agathatrack.com:3000/api/pets/{id}` (with JSON body)
- **Delete Pet**: `DELETE http://uat.agathatrack.com:3000/api/pets/{id}`

## What Changed from Dart to Node.js?

The original Dart/Shelf server was converted to Node.js/Express because:
1. cPanel Node.js hosting doesn't support Dart runtime
2. Node.js is more widely available on shared hosting
3. All endpoints and functionality remain identical
4. Database schema and queries are compatible
5. Environment variables configuration matches exactly

Both implementations maintain 100% feature parity.
