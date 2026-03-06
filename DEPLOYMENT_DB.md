# Agatha Track — Database Deployment Guide

## Overview

Agatha Track uses PostgreSQL as its primary database. The application is designed to be database-portable: all connection details come from environment variables, so the same codebase can point to different databases (dev / staging / prod) with no code changes.

## Prerequisites

- PostgreSQL 14 or newer
- Dart SDK 3.x
- The `DATABASE_URL` environment variable set

## 1. Provision a New Database

### Option A: Managed PostgreSQL (recommended for production)

Choose any managed PostgreSQL provider (e.g. Neon, Supabase, AWS RDS, Google Cloud SQL, Azure Database for PostgreSQL, DigitalOcean). Create a database instance and note the connection string.

### Option B: Self-hosted

```bash
sudo apt install postgresql
sudo -u postgres createuser agatha_user -P
sudo -u postgres createdb agatha_track -O agatha_user
```

## 2. Set Environment Variables

The application reads connection details from a single environment variable:

```bash
export DATABASE_URL="postgresql://user:password@host:5432/database_name"
```

For SSL connections (e.g. Neon, or any provider requiring SSL):

```bash
export DATABASE_URL="postgresql://user:password@host:5432/database_name?sslmode=require"
```

Additional required variable:

```bash
export SESSION_SECRET="your-secure-random-secret-here"
```

Optional (the app reads from DATABASE_URL first, falls back to these):

```bash
export PORT=5000  # Server port, defaults to 5000
```

## 3. Run Migrations

### Apply the schema (up)

```bash
dart run bin/migrate.dart up
```

This will:
- Create the `_migrations` tracking table if it does not exist
- Apply any pending migration files from `db/migrations/`
- Skip migrations that have already been applied

### Tear down the schema (down) — DESTRUCTIVE

```bash
dart run bin/migrate.dart down
```

This drops all tables. Use only for dev/test environments.

### Migration files

Migration files live in `db/migrations/` and follow this naming convention:

```
001_initial_schema.sql       — Up migration
001_initial_schema_down.sql  — Down migration
```

To add a new migration, create the next numbered pair (e.g. `002_add_feature.sql` / `002_add_feature_down.sql`).

## 4. Start the Server

```bash
dart run bin/server.dart
```

The server will:
- Parse `DATABASE_URL` to connect to PostgreSQL
- Run inline schema checks (safe `CREATE TABLE IF NOT EXISTS` / `ALTER TABLE ADD COLUMN IF NOT EXISTS`) to ensure the database is up to date
- Serve the Flutter web app from `deploy/public/`
- Listen on the port specified by `PORT` (default 5000)

## 5. Environments

### Development (Replit)

Replit automatically provides `DATABASE_URL` pointing to the built-in PostgreSQL instance. Set `SESSION_SECRET` in Replit Secrets.

### Staging / Production

Set `DATABASE_URL` and `SESSION_SECRET` in your deployment platform's environment configuration. Run `dart run bin/migrate.dart up` before starting the server.

### CI/CD Pipeline

```yaml
steps:
  - name: Run migrations
    env:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
    run: dart run bin/migrate.dart up

  - name: Start server
    env:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
      SESSION_SECRET: ${{ secrets.SESSION_SECRET }}
    run: dart run bin/server.dart
```

## 6. Docker Compose (Local Development)

```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: agatha
      POSTGRES_PASSWORD: agatha_dev
      POSTGRES_DB: agatha_track
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      DATABASE_URL: postgresql://agatha:agatha_dev@db:5432/agatha_track
      SESSION_SECRET: dev-secret-change-me
      PORT: "5000"
    depends_on:
      - db

volumes:
  pgdata:
```

## 7. Backup & Restore

```bash
# Backup
pg_dump "$DATABASE_URL" > backup_$(date +%Y%m%d).sql

# Restore
psql "$DATABASE_URL" < backup_20260306.sql
```

## Security Notes

- Never commit `DATABASE_URL` or `SESSION_SECRET` to version control
- Use strong, unique passwords for production databases
- Enable SSL for all production connections
- Restrict database access to application servers only (firewall / VPC)
- For EU compliance, host the database in an EU region
