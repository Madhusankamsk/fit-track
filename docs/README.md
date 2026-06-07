# FitTrack Pro Documentation

Welcome to the FitTrack Pro documentation. FitTrack Pro is a production-grade Strava alternative built as a microservices platform with PostGIS spatial processing and an offline-first Flutter mobile client.

## Documentation Index

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | What FitTrack Pro is, core features, and tech stack |
| [Architecture](architecture.md) | System design, data flows, and service interactions |
| [Project Structure](project-structure.md) | Repository layout and file organization |
| [Getting Started](getting-started.md) | Local development setup (Windows-focused) |
| [Environment Variables](environment-variables.md) | Full `.env` reference |
| [Database](database.md) | Prisma schema, PostGIS, migrations, and indexes |
| [Backend Services](backend-services.md) | Auth, ingestion, worker, and analytics services |
| [Activity Pipeline](activity-pipeline.md) | GPS ingest → Redis → spatial worker flow |
| [API Reference](api-reference.md) | REST endpoints, auth, request/response examples |
| [Flutter Mobile App](flutter-mobile.md) | Mobile client architecture and features |
| [Deployment](deployment.md) | Docker Compose, Nginx, and production setup |
| [Security](security.md) | Authentication, validation, and hardening |
| [Testing](testing.md) | Backend and Flutter test strategy |
| [Troubleshooting](troubleshooting.md) | Common issues and fixes |

## Quick Links

- **Blueprint (source of truth):** [../MASTER_BLUEPRINT.md](../MASTER_BLUEPRINT.md)
- **Agent guide:** [../AGENTS.md](../AGENTS.md)
- **Root README:** [../README.md](../README.md)

## Service Ports (Local Dev)

| Service | Port |
|---------|------|
| Auth & Users | 5001 |
| Activity Ingestion | 5002 |
| Analytics | 5003 |
| Dev Gateway | 8080 |
| PostgreSQL | 5432 |
| Redis | 6379 |

All API requests from clients should go through the **dev gateway** at `http://localhost:8080` (or your LAN IP on physical devices).
