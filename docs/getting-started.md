# Getting Started

This guide walks through running FitTrack Pro locally on Windows with Node.js (no Docker required for app services).

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 20 LTS | Backend services |
| PostgreSQL | 16+ | Primary database |
| PostGIS | 3.4+ | Spatial extensions |
| Redis | 7.x | Activity queue + cache |
| Flutter | 3.10+ | Mobile app (optional) |

### Installing PostgreSQL + PostGIS (Windows)

1. Download PostgreSQL from [postgresql.org/download/windows](https://www.postgresql.org/download/windows/).
2. During or after install, enable the PostGIS extension via Stack Builder, or run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```
3. Create the database and user:
   ```sql
   CREATE USER fittrack WITH PASSWORD 'strongpassword';
   CREATE DATABASE fittrack_db OWNER fittrack;
   GRANT ALL PRIVILEGES ON DATABASE fittrack_db TO fittrack;
   ```

### Installing Redis (Windows)

Use [Memurai](https://www.memurai.com/) (Redis-compatible) or run Redis inside WSL2:

```bash
sudo apt install redis-server
sudo service redis-server start
```

Verify: `redis-cli ping` should return `PONG`.

## Step 1: Clone and Configure

```powershell
cd strava-clone
copy .env.example .env
```

Edit `.env` and set at minimum:
- `DATABASE_URL` — your PostgreSQL connection string
- `JWT_SECRET` — a random 256-bit secret
- `REDIS_URL` — `redis://localhost:6379`

See [Environment Variables](environment-variables.md) for the full list.

## Step 2: Install Dependencies

```powershell
# Root (Prisma client)
npm install

# Each microservice
cd auth-user-service; npm install; cd ..
cd activity-ingestion-api; npm install; cd ..
cd spatial-processing-worker; npm install; cd ..
cd analytics-service; npm install; cd ..
cd dev-gateway; npm install; cd ..
```

## Step 3: Database Setup

```powershell
npm run prisma:migrate
```

Apply PostGIS indexes:

```powershell
psql $env:DATABASE_URL -f prisma/migrations/postgis_indexes.sql
```

If `psql` is not in PATH, use pgAdmin or connect manually and run the SQL file contents.

## Step 4: Start Backend Services

Open **five separate terminals** from the repo root:

```powershell
npm run dev:auth       # Terminal 1 — port 5001
npm run dev:ingest     # Terminal 2 — port 5002
npm run dev:analytics  # Terminal 3 — port 5003
npm run dev:worker     # Terminal 4 — spatial worker
npm run dev:gateway    # Terminal 5 — port 8080
```

Verify health:

```powershell
curl http://localhost:8080/health
curl http://localhost:5001/health
```

## Step 5: Flutter Mobile App

```powershell
cd strava_alternative_app
flutter pub get
flutter run
```

### API Base URL

Edit `lib/core/constants.dart`:

| Target | `baseUrl` |
|--------|-----------|
| Android emulator | `http://10.0.2.2:8080` |
| iOS simulator | `http://localhost:8080` |
| Physical device | `http://<YOUR_LAN_IP>:8080` |

### Windows Developer Mode

Flutter plugin builds require symlink support. Enable **Developer Mode** in Windows Settings (`start ms-settings:developers`) if you see symlink errors during `flutter run`.

## Step 6: Smoke Test

```powershell
# Register
curl -X POST http://localhost:8080/api/v1/auth/register `
  -H "Content-Type: application/json" `
  -d '{"username":"runner1","email":"runner1@test.com","password":"Securepass1!"}'

# Login (save the token)
curl -X POST http://localhost:8080/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"runner1@test.com","password":"Securepass1!"}'
```

See [Testing](testing.md) for the full E2E checklist.

## Docker Alternative

If you prefer containers for the full stack:

```powershell
copy .env.example .env
docker compose up -d
```

See [Deployment](deployment.md) for production configuration.

## Related Documents

- [Environment Variables](environment-variables.md)
- [Database](database.md)
- [Troubleshooting](troubleshooting.md)
