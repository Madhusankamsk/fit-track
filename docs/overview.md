# Overview

## What is FitTrack Pro?

FitTrack Pro is a high-performance fitness tracking platform designed as a decentralized, offline-first alternative to Strava. It records GPS activities, processes routes with PostGIS, and provides social features including kudos, comments, segments, and leaderboards.

## Core Features

### Activity Tracking
- Ultra-high-speed GPS ingestion via a Redis-buffered queue (zero-latency ACK to the client)
- PostGIS spatial processing for accurate distance, elevation, and route analysis
- Offline-first mobile recording with background GPS and automatic sync

### Social
- Activity feed from followed users
- Kudos and comments on activities
- Follow/unfollow system

### Segments & Analytics
- Named route segments with leaderboards
- Personal lifetime stats (distance, time, elevation)
- Personal records (longest run, fastest pace per km)
- Redis-cached stats and leaderboards

### Platform
- JWT-authenticated REST APIs with rate limiting and Zod validation
- Microservices architecture (Node.js / Fastify)
- Containerized deployment via Docker Compose
- Flutter mobile client (Android, iOS)

## Technology Stack

### Backend
| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 20 LTS |
| HTTP Framework | Fastify 4.x |
| ORM | Prisma 5.x |
| Database | PostgreSQL 16 + PostGIS 3.4 |
| Queue / Cache | Redis 7.x |
| Auth | JWT (`@fastify/jwt`), bcrypt |
| Validation | Zod 3.x |

### Mobile
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State | Riverpod |
| HTTP | Dio |
| Local Storage | Hive, flutter_secure_storage |
| GPS | geolocator, flutter_background_service |
| Maps | flutter_map, latlong2 |
| Navigation | GoRouter |

### Infrastructure
| Component | Technology |
|-----------|-----------|
| Containerization | Docker + Docker Compose |
| Reverse Proxy | Nginx (production), dev-gateway (local) |
| Monitoring | Prometheus + Grafana (optional) |

## Design Principles

1. **Hot path isolation** — The ingest endpoint never writes to PostgreSQL; it pushes to Redis and returns `202 Accepted` immediately.
2. **Spatial accuracy** — Routes and waypoints use PostGIS geography types; distance is computed with `ST_Length` on the ellipsoid.
3. **Offline-first mobile** — GPS waypoints are stored in Hive locally and synced when connectivity is available.
4. **Single API entry** — Clients talk to one gateway URL; routing to microservices is handled by Nginx or the dev gateway.

## Related Documents

- [Architecture](architecture.md) — How components connect
- [Getting Started](getting-started.md) — Run the stack locally
- [MASTER_BLUEPRINT.md](../MASTER_BLUEPRINT.md) — Original design specification
