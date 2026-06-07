# FitTrack Pro — Project Blueprint

> **Canonical specification:** [MASTER_BLUEPRINT.md](./MASTER_BLUEPRINT.md)  
> This file records the **current implementation bounds** for UI and API wiring.

## UI Implementation Matrix (Strict)

| Area | Flutter UI | Backend API |
|------|------------|-------------|
| Auth (register, login, logout) | Wired | `POST /auth/register`, `/login`, `/refresh` |
| Feed (pull-to-refresh, cards, kudos) | Wired | `GET /feed`, `POST /activities/:id/kudos` |
| Track (GPS mobile-only) | Wired (Android/iOS) | `POST /ingest` |
| Profile (stats, PRs, logout) | Wired | `GET /stats/me` |
| Segments (list + leaderboard) | Wired | `GET /segments`, `GET /segments/:id/leaderboard` |
| Profile edit | **Not wired** | `PUT /users/me` |
| Follow / unfollow | **Not wired** | `POST/DELETE /users/:id/follow` |
| Activity detail | **Not wired** | `GET /activities/:id` |
| Activity delete | **Not wired** | `DELETE /activities/:id` |
| Create segment | **Not wired** | `POST /segments` |
| Post comments | **Not wired** | `POST /activities/:id/comments` |

## Critical Technical Constraints

1. **Worker ID retrieval** — Activity insert uses `prisma.$queryRaw` with `RETURNING id`.
2. **Worker waypoint writes** — Bulk `INSERT ... VALUES` via `Prisma.join()` in 1000-row chunks.
3. **Hive concurrency** — `Hive.isBoxOpen()` guard before `openBox` in background isolate.
4. **JWT refresh** — Dio `JwtRefreshInterceptor` auto-refreshes on 401 and retries once.
5. **PostGIS** — Geography writes via `$executeRaw` / `$queryRaw`; reads via `ST_AsGeoJSON()`.
6. **Web/desktop tracking** — Disabled with message: *"GPS Tracking is only available on Mobile Devices."*

## Local Development

```powershell
npm run start:all    # Backend services
npm run seed         # Seed account runner1@test.com / Securepass1!
cd strava_alternative_app && flutter run -d chrome --web-port=3001
```

See [docs/getting-started.md](./docs/getting-started.md) for full setup.
