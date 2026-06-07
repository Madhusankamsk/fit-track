# FitTrack Pro

Production-grade Strava alternative — microservices backend, PostGIS spatial processing, offline-first Flutter mobile app.

## Documentation

**Full documentation:** [docs/README.md](docs/README.md)

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Local setup |
| [Architecture](docs/architecture.md) | System design |
| [API Reference](docs/api-reference.md) | REST endpoints |
| [Flutter Mobile](docs/flutter-mobile.md) | Mobile app guide |

**Design specification:** [MASTER_BLUEPRINT.md](MASTER_BLUEPRINT.md)

## Quick Start

```powershell
copy .env.example .env
npm install
npm run prisma:migrate
psql $env:DATABASE_URL -f prisma/migrations/postgis_indexes.sql

# Start services (separate terminals)
npm run dev:auth
npm run dev:ingest
npm run dev:analytics
npm run dev:worker
npm run dev:gateway

# Flutter app
cd strava_alternative_app && flutter pub get && flutter run
```

See [docs/getting-started.md](docs/getting-started.md) for detailed instructions.

## Architecture

```
Flutter App → Dev Gateway (:8080)
  ├── Auth Service (:5001)
  ├── Ingestion API (:5002) → Redis → Spatial Worker → PostgreSQL+PostGIS
  └── Analytics Service (:5003)
```

## Tests

```powershell
cd auth-user-service && npm test
cd ../strava_alternative_app && flutter test
```
