# Project Structure

```
strava-clone/
├── docs/                           # This documentation
├── MASTER_BLUEPRINT.md             # Original design specification (source of truth)
├── AGENTS.md                       # Cursor/agent quick reference
├── README.md                       # Quick start
├── package.json                    # Root scripts (dev:*, prisma:*)
├── .env.example                    # Environment template
├── docker-compose.yml              # Production stack
├── docker-compose.dev.yml          # Dev volume overrides
│
├── prisma/
│   ├── schema.prisma               # Shared data models
│   └── migrations/
│       ├── migration_lock.toml
│       ├── 20240607000000_init/     # Initial schema migration
│       └── postgis_indexes.sql     # PostGIS extension + GIST indexes
│
├── auth-user-service/              # Port 5001
│   ├── server.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   └── users.routes.js
│   ├── middleware/authenticate.js
│   ├── validators/auth.schema.js
│   ├── tests/auth.test.js
│   └── Dockerfile
│
├── activity-ingestion-api/         # Port 5002
│   ├── server.js
│   ├── routes/
│   │   ├── ingest.routes.js
│   │   └── feed.routes.js
│   ├── middleware/authenticate.js
│   └── Dockerfile
│
├── spatial-processing-worker/      # Background daemon
│   ├── worker.js
│   ├── processors/
│   │   ├── routeProcessor.js
│   │   └── waypointProcessor.js
│   └── Dockerfile
│
├── analytics-service/              # Port 5003
│   ├── server.js
│   ├── routes/
│   │   ├── stats.routes.js
│   │   ├── segments.routes.js
│   │   └── social.routes.js
│   ├── middleware/authenticate.js
│   └── Dockerfile
│
├── dev-gateway/                    # Port 8080 (local only)
│   └── server.js
│
├── nginx/
│   ├── nginx.conf                  # Production reverse proxy
│   └── ssl/                        # TLS certificates
│
├── monitoring/
│   └── prometheus.yml
│
└── strava_alternative_app/         # Flutter mobile client
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── core/
    │   │   ├── constants.dart      # API base URL, config
    │   │   ├── di.dart             # Riverpod providers
    │   │   └── router.dart         # GoRouter navigation
    │   ├── services/
    │   │   ├── api_client.dart
    │   │   ├── auth_service.dart
    │   │   ├── tracking_service.dart
    │   │   └── sync_service.dart
    │   ├── models/
    │   │   ├── activity.dart
    │   │   ├── user.dart
    │   │   └── waypoint.dart
    │   └── features/
    │       ├── auth/
    │       ├── tracking/
    │       ├── feed/
    │       ├── profile/
    │       └── segments/
    ├── android/                    # Android platform
    ├── ios/                        # iOS platform
    └── test/
```

## Conventions

### Backend
- **ESM modules** — All services use `"type": "module"`.
- **Shared Prisma schema** — Root `prisma/schema.prisma`; generate client from repo root.
- **Route modules** — `server.js` bootstraps Fastify; routes live in `routes/*.routes.js`.
- **Docker builds** — Use repo root as build context (`docker build -f auth-user-service/Dockerfile .`).

### Flutter
- **Feature-first layout** — Screens grouped under `lib/features/{feature}/`.
- **Riverpod DI** — Providers defined in `lib/core/di.dart`.
- **Single API base URL** — `AppConstants.baseUrl` points to the dev gateway.

### Cursor Rules
Persistent AI guidance lives in `.cursor/rules/`:
- `fittrack-blueprint.mdc` — Always apply; core constraints
- `backend-services.mdc` — Fastify/Prisma conventions
- `flutter-client.mdc` — Mobile client patterns

## Related Documents

- [Getting Started](getting-started.md)
- [Backend Services](backend-services.md)
- [Flutter Mobile App](flutter-mobile.md)
