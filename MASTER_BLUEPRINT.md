# 🏃 FitTrack Pro — Production-Grade Strava Alternative
## Master Blueprint & Cursor.ai Development Reference

> **This document is the single source of truth for building FitTrack Pro — a high-performance, decentralized, offline-first fitness tracking platform. Reference this when generating code in Cursor.ai.**

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Technology Stack](#technology-stack)
3. [Directory Structure](#directory-structure)
4. [Environment Configuration](#environment-configuration)
5. [Database Schema (Prisma + PostGIS)](#database-schema)
6. [Auth & User Service](#auth--user-service-port-5001)
7. [Activity Ingestion API](#activity-ingestion-api-port-5002)
8. [Spatial Processing Worker](#spatial-processing-worker)
9. [Analytics & Leaderboard Service](#analytics--leaderboard-service-port-5003)
10. [API Gateway & Reverse Proxy](#api-gateway--reverse-proxy-port-80443)
11. [Flutter Mobile Client](#flutter-mobile-client)
12. [Infrastructure & DevOps](#infrastructure--devops)
13. [Security Implementation](#security-implementation)
14. [Testing Strategy](#testing-strategy)
15. [Cursor.ai Code Generation Prompts](#cursorai-code-generation-prompts)

---

## System Overview

FitTrack Pro is a **microservices-based fitness tracking platform** with the following core capabilities:

- **Ultra-high-speed GPS ingestion** via Redis-buffered queue (zero-latency ACK)
- **PostGIS spatial processing** for accurate distance, elevation, and route analysis
- **Offline-first Flutter mobile app** with background GPS tracking and auto-sync
- **Social features**: Kudos, Comments, Segments, Leaderboards
- **JWT-authenticated REST APIs** with rate limiting and input validation
- **Containerized deployment** via Docker Compose

### Architecture Flow

```
Mobile App (Flutter)
    │
    ▼ HTTP POST (GPS batch)
API Gateway (Nginx) :80/:443
    │
    ├──▶ Auth Service :5001 (Fastify + Prisma)
    │         │
    ├──▶ Ingestion API :5002 (Fastify + ioredis)
    │         │
    │         ▼ redis.rpush('activity_queue')
    │    Redis Queue
    │         │
    │         ▼ redis.blpop (blocking)
    │    Spatial Worker (Node.js daemon)
    │         │ prisma.$transaction
    │         ▼
    │    PostgreSQL + PostGIS
    │         │
    └──▶ Analytics Service :5003 (Fastify + Prisma)
              │
              ▼
         Redis Cache (leaderboards, feed)
```

---

## Technology Stack

### Backend Services
| Layer | Technology | Version |
|-------|-----------|---------|
| Runtime | Node.js | 20 LTS |
| HTTP Framework | Fastify | 4.x |
| ORM | Prisma | 5.x |
| Database | PostgreSQL | 16 + PostGIS 3.4 |
| Queue/Cache | Redis | 7.x |
| Auth | JWT (jsonwebtoken) | 9.x |
| Validation | Zod | 3.x |
| Password Hash | bcrypt | 5.x |
| Queue Client | ioredis | 5.x |
| Logger | Pino (built into Fastify) | — |

### Mobile Client
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| HTTP Client | Dio |
| Local Storage | Hive + hive_flutter |
| Background Service | flutter_background_service |
| GPS | geolocator |
| Maps | flutter_map + latlong2 |
| State Management | Riverpod |
| Secure Storage | flutter_secure_storage |

### Infrastructure
| Component | Technology |
|-----------|-----------|
| Containerization | Docker + Docker Compose |
| Reverse Proxy | Nginx |
| Process Manager | PM2 (production Node.js) |
| SSL | Let's Encrypt / Certbot |
| Monitoring | Prometheus + Grafana |

---

## Directory Structure

```text
fittrack-pro/
│
├── docker-compose.yml                  # Full stack orchestration
├── docker-compose.dev.yml              # Dev overrides (hot reload)
├── nginx/
│   ├── nginx.conf                      # Reverse proxy config
│   └── ssl/                            # SSL certificates
│
├── prisma/
│   └── schema.prisma                   # Central data models
│
├── auth-user-service/                  # Port 5001
│   ├── package.json
│   ├── server.js                       # Fastify entry point
│   ├── routes/
│   │   ├── auth.routes.js              # Register, Login, Refresh
│   │   └── users.routes.js             # Profile CRUD, Follow system
│   ├── middleware/
│   │   ├── authenticate.js             # JWT verification hook
│   │   └── rateLimit.js                # Per-IP rate limiter
│   ├── validators/
│   │   └── auth.schema.js              # Zod schemas
│   └── Dockerfile
│
├── activity-ingestion-api/             # Port 5002
│   ├── package.json
│   ├── server.js                       # Fastify entry point
│   ├── routes/
│   │   ├── ingest.routes.js            # POST /ingest (Redis push)
│   │   └── feed.routes.js              # GET /feed (PostGIS queries)
│   ├── middleware/
│   │   └── authenticate.js             # JWT verification hook
│   └── Dockerfile
│
├── spatial-processing-worker/          # Background daemon
│   ├── package.json
│   ├── worker.js                       # Main consumer loop
│   ├── processors/
│   │   ├── routeProcessor.js           # WKT construction + ST_ calls
│   │   └── waypointProcessor.js        # Bulk waypoint inserts
│   └── Dockerfile
│
├── analytics-service/                  # Port 5003
│   ├── package.json
│   ├── server.js                       # Fastify entry point
│   ├── routes/
│   │   ├── stats.routes.js             # Personal stats, PRs
│   │   ├── segments.routes.js          # Segment CRUD + leaderboards
│   │   └── social.routes.js            # Kudos, Comments, Follow feed
│   └── Dockerfile
│
├── strava_alternative_app/             # Flutter mobile client
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart                   # App entry, DI setup
│       ├── core/
│       │   ├── constants.dart          # API base URL, config
│       │   ├── di.dart                 # Riverpod providers
│       │   └── router.dart             # GoRouter config
│       ├── services/
│       │   ├── tracking_service.dart   # Background GPS isolate
│       │   ├── sync_service.dart       # Hive → API sync pipeline
│       │   ├── auth_service.dart       # Token management
│       │   └── api_client.dart         # Dio HTTP client
│       ├── features/
│       │   ├── auth/                   # Login, Register screens
│       │   ├── tracking/               # Live run screen + HUD
│       │   ├── feed/                   # Activity feed + maps
│       │   ├── profile/                # User profile + stats
│       │   └── segments/               # Segment browser
│       └── models/
│           ├── activity.dart
│           ├── user.dart
│           └── waypoint.dart
│
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       └── dashboards/
│
└── .env                                # Shared env vars (never commit)
```

---

## Environment Configuration

### `.env` (Root — shared by all services via Docker Compose)

```bash
# ── Database ──────────────────────────────────────────────
DATABASE_URL=postgresql://fittrack:strongpassword@postgres:5432/fittrack_db

# ── Redis ─────────────────────────────────────────────────
REDIS_URL=redis://redis:6379

# ── JWT ───────────────────────────────────────────────────
JWT_SECRET=replace_with_256bit_random_secret_never_expose
JWT_REFRESH_SECRET=replace_with_different_256bit_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d

# ── Service Ports ─────────────────────────────────────────
AUTH_SERVICE_PORT=5001
INGESTION_API_PORT=5002
ANALYTICS_SERVICE_PORT=5003

# ── App Config ────────────────────────────────────────────
NODE_ENV=production
BCRYPT_ROUNDS=12
MAX_WAYPOINTS_PER_ACTIVITY=100000
ACTIVITY_QUEUE_NAME=activity_queue

# ── Monitoring ────────────────────────────────────────────
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
```

---

## Database Schema

> **File:** `prisma/schema.prisma`
> The schema below is the **complete and final** version. Do not abbreviate.

```prisma
// ─── Prisma Config ────────────────────────────────────────────────────────────
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["postgresqlExtensions"]
}

// ─── User ─────────────────────────────────────────────────────────────────────
model User {
  id                Int             @id @default(autoincrement())
  username          String          @unique @db.VarChar(50)
  email             String          @unique @db.VarChar(100)
  passwordHash      String          @map("password_hash") @db.VarChar(255)
  bio               String?         @db.Text
  profilePictureUrl String?         @map("profile_picture_url") @db.VarChar(255)
  isVerified        Boolean         @default(false) @map("is_verified")
  refreshToken      String?         @map("refresh_token") @db.Text

  activities        Activity[]
  segmentEfforts    SegmentEffort[]
  kudosGiven        Kudo[]
  comments          Comment[]
  followers         Follow[]        @relation("Following")
  following         Follow[]        @relation("Follower")

  createdAt         DateTime        @default(now()) @map("created_at")
  updatedAt         DateTime        @default(now()) @updatedAt @map("updated_at")

  @@map("users")
}

// ─── Follow System ────────────────────────────────────────────────────────────
model Follow {
  id          Int      @id @default(autoincrement())
  followerId  Int      @map("follower_id")
  follower    User     @relation("Follower", fields: [followerId], references: [id], onDelete: Cascade)
  followingId Int      @map("following_id")
  following   User     @relation("Following", fields: [followingId], references: [id], onDelete: Cascade)
  createdAt   DateTime @default(now()) @map("created_at")

  @@unique([followerId, followingId])
  @@map("follows")
}

// ─── Activity ─────────────────────────────────────────────────────────────────
model Activity {
  id                  Int      @id @default(autoincrement())
  userId              Int      @map("user_id")
  user                User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  title               String   @db.VarChar(100)
  description         String?  @db.Text
  activityType        String   @default("run") @map("activity_type") @db.VarChar(20)
  distanceMeters      Float    @default(0.0) @map("distance_meters")
  durationSeconds     Int      @default(0) @map("duration_seconds")
  elapsedTimeSeconds  Int      @default(0) @map("elapsed_time_seconds")
  elevationGainMeters Float    @default(0.0) @map("elevation_gain_meters")
  maxHeartRate        Int?     @map("max_heart_rate")
  averageHeartRate    Int?     @map("average_heart_rate")
  caloriesBurned      Int?     @map("calories_burned")
  averagePaceSecPerKm Float?   @map("average_pace_sec_per_km")
  isPublic            Boolean  @default(true) @map("is_public")
  startTime           DateTime @map("start_time")

  // PostGIS: Full GPS route saved as a LineString
  route               Unsupported("geography(LineString, 4326)")?

  waypoints           ActivityWaypoint[]
  segmentEfforts      SegmentEffort[]
  kudos               Kudo[]
  comments            Comment[]

  createdAt           DateTime @default(now()) @map("created_at")

  @@map("activities")
}

// ─── Activity Waypoints (high-frequency GPS ticks) ────────────────────────────
model ActivityWaypoint {
  id              BigInt   @id @default(autoincrement())
  activityId      Int      @map("activity_id")
  activity        Activity @relation(fields: [activityId], references: [id], onDelete: Cascade)
  timeStamp       DateTime @map("time_stamp")
  elevationMeters Float?   @map("elevation_meters")
  heartRate       Int?     @map("heart_rate")
  speedMps        Float?   @map("speed_mps")
  cadence         Int?
  accuracy        Float?   // GPS accuracy in meters

  // PostGIS: Individual GPS tick as a Point
  location        Unsupported("geography(Point, 4326)")

  @@index([activityId])
  @@map("activity_waypoints")
}

// ─── Segment (a named, reusable route section) ────────────────────────────────
model Segment {
  id             Int    @id @default(autoincrement())
  name           String @db.VarChar(100)
  distanceMeters Float  @map("distance_meters")
  createdById    Int    @map("created_by_id")

  startPoint     Unsupported("geography(Point, 4326)")    @map("start_point")
  endPoint       Unsupported("geography(Point, 4326)")    @map("end_point")
  segmentRoute   Unsupported("geography(LineString, 4326)") @map("segment_route")

  efforts        SegmentEffort[]
  createdAt      DateTime @default(now()) @map("created_at")

  @@map("segments")
}

// ─── Segment Effort (a user's attempt on a Segment) ──────────────────────────
model SegmentEffort {
  id                 BigInt   @id @default(autoincrement())
  userId             Int      @map("user_id")
  user               User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  activityId         Int      @map("activity_id")
  activity           Activity @relation(fields: [activityId], references: [id], onDelete: Cascade)
  segmentId          Int      @map("segment_id")
  segment            Segment  @relation(fields: [segmentId], references: [id], onDelete: Cascade)
  elapsedTimeSeconds Int      @map("elapsed_time_seconds")
  averageHeartRate   Int?     @map("average_heart_rate")
  rank               Int?     // Current rank on leaderboard (cached)
  isKom              Boolean  @default(false) @map("is_kom") // King of the Mountain
  startTime          DateTime @map("start_time")
  createdAt          DateTime @default(now()) @map("created_at")

  @@map("segment_efforts")
}

// ─── Social: Kudos ────────────────────────────────────────────────────────────
model Kudo {
  id         Int      @id @default(autoincrement())
  userId     Int      @map("user_id")
  user       User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  activityId Int      @map("activity_id")
  activity   Activity @relation(fields: [activityId], references: [id], onDelete: Cascade)
  createdAt  DateTime @default(now()) @map("created_at")

  @@unique([userId, activityId])
  @@map("kudos")
}

// ─── Social: Comments ─────────────────────────────────────────────────────────
model Comment {
  id          Int      @id @default(autoincrement())
  userId      Int      @map("user_id")
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  activityId  Int      @map("activity_id")
  activity    Activity @relation(fields: [activityId], references: [id], onDelete: Cascade)
  commentText String   @map("comment_text") @db.Text
  createdAt   DateTime @default(now()) @map("created_at")

  @@map("comments")
}

// ─── Personal Records ─────────────────────────────────────────────────────────
model PersonalRecord {
  id             Int      @id @default(autoincrement())
  userId         Int      @map("user_id")
  activityId     Int      @map("activity_id")
  recordType     String   @map("record_type") @db.VarChar(50) // e.g. "fastest_5k", "longest_run"
  value          Float    // seconds for time-based, meters for distance-based
  achievedAt     DateTime @map("achieved_at")
  createdAt      DateTime @default(now()) @map("created_at")

  @@unique([userId, recordType])
  @@map("personal_records")
}
```

### Required PostGIS SQL Migrations

After `prisma migrate dev`, run these raw SQL commands:

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add spatial indexes for performance
CREATE INDEX idx_activity_waypoints_location 
  ON activity_waypoints USING GIST (location);

CREATE INDEX idx_activities_route 
  ON activities USING GIST (route);

CREATE INDEX idx_segments_start_point 
  ON segments USING GIST (start_point);

CREATE INDEX idx_segments_segment_route 
  ON segments USING GIST (segment_route);

-- Add covering index for feed queries
CREATE INDEX idx_activities_user_created 
  ON activities (user_id, created_at DESC);
```

---

## Auth & User Service (Port 5001)

> **File:** `auth-user-service/server.js`

### Package Dependencies

```json
{
  "name": "auth-user-service",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js"
  },
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "bcrypt": "^5.1.1",
    "fastify": "^4.28.0",
    "@fastify/jwt": "^8.0.0",
    "@fastify/cors": "^9.0.0",
    "@fastify/rate-limit": "^9.0.0",
    "zod": "^3.23.0",
    "prisma": "^5.0.0"
  }
}
```

### Complete Implementation

```javascript
// auth-user-service/server.js
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyRateLimit from '@fastify/rate-limit';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import { z } from 'zod';

const prisma = new PrismaClient();
const app = Fastify({ logger: true });

// ── Plugins ────────────────────────────────────────────────────────────────
await app.register(fastifyCors, { origin: '*' });
await app.register(fastifyJwt, { secret: process.env.JWT_SECRET });
await app.register(fastifyRateLimit, {
  max: 100,
  timeWindow: '1 minute'
});

// ── Authentication Decorator ───────────────────────────────────────────────
app.decorate('authenticate', async (request, reply) => {
  try {
    await request.jwtVerify();
  } catch (err) {
    reply.status(401).send({ error: 'Unauthorized' });
  }
});

// ── Zod Schemas ────────────────────────────────────────────────────────────
const registerSchema = z.object({
  username: z.string().min(3).max(50).regex(/^[a-zA-Z0-9_]+$/),
  email: z.string().email().max(100),
  password: z.string().min(8).max(72)
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

// ── Routes ─────────────────────────────────────────────────────────────────

// POST /api/v1/auth/register
app.post('/api/v1/auth/register', async (request, reply) => {
  const result = registerSchema.safeParse(request.body);
  if (!result.success) {
    return reply.status(400).send({ error: result.error.flatten() });
  }

  const { username, email, password } = result.data;

  const existing = await prisma.user.findFirst({
    where: { OR: [{ email }, { username }] }
  });
  if (existing) {
    return reply.status(409).send({
      error: existing.email === email ? 'Email already in use' : 'Username taken'
    });
  }

  const passwordHash = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS || '12'));
  const user = await prisma.user.create({
    data: { username, email, passwordHash },
    select: { id: true, username: true, email: true, createdAt: true }
  });

  const token = app.jwt.sign(
    { sub: user.id, username: user.username },
    { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
  );

  return reply.status(201).send({ user, token });
});

// POST /api/v1/auth/login
app.post('/api/v1/auth/login', async (request, reply) => {
  const result = loginSchema.safeParse(request.body);
  if (!result.success) {
    return reply.status(400).send({ error: result.error.flatten() });
  }

  const { email, password } = result.data;

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    return reply.status(401).send({ error: 'Invalid credentials' });
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    return reply.status(401).send({ error: 'Invalid credentials' });
  }

  const token = app.jwt.sign(
    { sub: user.id, username: user.username },
    { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
  );

  const refreshToken = app.jwt.sign(
    { sub: user.id, type: 'refresh' },
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
  );

  await prisma.user.update({
    where: { id: user.id },
    data: { refreshToken }
  });

  return reply.send({
    token,
    refreshToken,
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      profilePictureUrl: user.profilePictureUrl
    }
  });
});

// POST /api/v1/auth/refresh
app.post('/api/v1/auth/refresh', async (request, reply) => {
  const { refreshToken } = request.body;
  try {
    const decoded = app.jwt.verify(refreshToken);
    const user = await prisma.user.findUnique({ where: { id: decoded.sub } });
    if (!user || user.refreshToken !== refreshToken) {
      return reply.status(401).send({ error: 'Invalid refresh token' });
    }
    const token = app.jwt.sign(
      { sub: user.id, username: user.username },
      { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );
    return reply.send({ token });
  } catch {
    return reply.status(401).send({ error: 'Invalid refresh token' });
  }
});

// GET /api/v1/users/:id
app.get('/api/v1/users/:id', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const userId = parseInt(request.params.id);
  if (isNaN(userId)) return reply.status(400).send({ error: 'Invalid user ID' });

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true, username: true, bio: true, profilePictureUrl: true, createdAt: true,
      activities: {
        where: { isPublic: true },
        orderBy: { createdAt: 'desc' },
        take: 20,
        select: {
          id: true, title: true, activityType: true,
          distanceMeters: true, durationSeconds: true,
          elevationGainMeters: true, startTime: true, createdAt: true,
          _count: { select: { kudos: true, comments: true } }
        }
      },
      _count: {
        select: { followers: true, following: true, activities: true }
      }
    }
  });

  if (!user) return reply.status(404).send({ error: 'User not found' });
  return reply.send(user);
});

// PUT /api/v1/users/me — Update own profile
app.put('/api/v1/users/me', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const schema = z.object({
    bio: z.string().max(500).optional(),
    username: z.string().min(3).max(50).regex(/^[a-zA-Z0-9_]+$/).optional(),
  });
  const result = schema.safeParse(request.body);
  if (!result.success) return reply.status(400).send({ error: result.error.flatten() });

  const updated = await prisma.user.update({
    where: { id: request.user.sub },
    data: result.data,
    select: { id: true, username: true, bio: true, profilePictureUrl: true }
  });
  return reply.send(updated);
});

// POST /api/v1/users/:id/follow
app.post('/api/v1/users/:id/follow', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const followingId = parseInt(request.params.id);
  const followerId = request.user.sub;

  if (followerId === followingId) {
    return reply.status(400).send({ error: 'Cannot follow yourself' });
  }

  await prisma.follow.upsert({
    where: { followerId_followingId: { followerId, followingId } },
    create: { followerId, followingId },
    update: {}
  });

  return reply.status(201).send({ success: true });
});

// DELETE /api/v1/users/:id/follow
app.delete('/api/v1/users/:id/follow', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const followingId = parseInt(request.params.id);
  const followerId = request.user.sub;

  await prisma.follow.deleteMany({ where: { followerId, followingId } });
  return reply.send({ success: true });
});

// ── Server Bootstrap ───────────────────────────────────────────────────────
try {
  await app.listen({
    port: parseInt(process.env.AUTH_SERVICE_PORT || '5001'),
    host: '0.0.0.0'
  });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
```

---

## Activity Ingestion API (Port 5002)

> **File:** `activity-ingestion-api/server.js`

### Package Dependencies

```json
{
  "name": "activity-ingestion-api",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "fastify": "^4.28.0",
    "@fastify/jwt": "^8.0.0",
    "@fastify/cors": "^9.0.0",
    "@fastify/rate-limit": "^9.0.0",
    "ioredis": "^5.3.2",
    "zod": "^3.23.0"
  }
}
```

### Complete Implementation

```javascript
// activity-ingestion-api/server.js
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyRateLimit from '@fastify/rate-limit';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';
import { z } from 'zod';

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL);
const app = Fastify({ logger: true });

await app.register(fastifyCors, { origin: '*' });
await app.register(fastifyJwt, { secret: process.env.JWT_SECRET });
await app.register(fastifyRateLimit, { max: 200, timeWindow: '1 minute' });

app.decorate('authenticate', async (request, reply) => {
  try {
    await request.jwtVerify();
  } catch {
    reply.status(401).send({ error: 'Unauthorized' });
  }
});

// ── Ingest Schema ─────────────────────────────────────────────────────────
const coordinateSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  timestamp: z.string().datetime(),
  elevation: z.number().optional(),
  heartRate: z.number().int().min(0).max(300).optional(),
  speed: z.number().min(0).optional(),
  cadence: z.number().int().min(0).optional(),
  accuracy: z.number().min(0).optional()
});

const ingestSchema = z.object({
  title: z.string().min(1).max(100),
  activityType: z.enum(['run', 'ride', 'swim', 'walk', 'hike', 'workout']).default('run'),
  startTime: z.string().datetime(),
  durationSeconds: z.number().int().min(0),
  coordinates: z.array(coordinateSchema).min(2).max(
    parseInt(process.env.MAX_WAYPOINTS_PER_ACTIVITY || '100000')
  )
});

// ── POST /api/v1/ingest ────────────────────────────────────────────────────
// High-traffic endpoint — zero DB writes here, push to Redis queue only
app.post('/api/v1/ingest', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const result = ingestSchema.safeParse(request.body);
  if (!result.success) {
    return reply.status(400).send({ error: result.error.flatten() });
  }

  const payload = {
    userId: request.user.sub,
    ...result.data,
    receivedAt: new Date().toISOString()
  };

  await redis.rpush(
    process.env.ACTIVITY_QUEUE_NAME || 'activity_queue',
    JSON.stringify(payload)
  );

  // Immediately ACK — client can clear local cache
  return reply.status(202).send({ accepted: true, queuedAt: payload.receivedAt });
});

// ── GET /api/v1/feed ───────────────────────────────────────────────────────
// Returns activities with PostGIS-decoded route geometry for map rendering
app.get('/api/v1/feed', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const { page = 1, limit = 20 } = request.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  const userId = request.user.sub;

  // Fetch activities from users that the current user follows + own activities
  const activities = await prisma.$queryRaw`
    SELECT
      a.id,
      a.title,
      a.activity_type,
      a.distance_meters,
      a.duration_seconds,
      a.elevation_gain_meters,
      a.average_pace_sec_per_km,
      a.start_time,
      a.created_at,
      u.id as user_id,
      u.username,
      u.profile_picture_url,
      ST_AsGeoJSON(a.route)::json AS route_geojson,
      COUNT(DISTINCT k.id)::int AS kudos_count,
      COUNT(DISTINCT c.id)::int AS comments_count,
      EXISTS(SELECT 1 FROM kudos k2 WHERE k2.activity_id = a.id AND k2.user_id = ${userId}) AS viewer_has_kudoed
    FROM activities a
    JOIN users u ON u.id = a.user_id
    LEFT JOIN kudos k ON k.activity_id = a.id
    LEFT JOIN comments c ON c.activity_id = a.id
    WHERE
      a.is_public = true
      AND (
        a.user_id = ${userId}
        OR a.user_id IN (
          SELECT following_id FROM follows WHERE follower_id = ${userId}
        )
      )
    GROUP BY a.id, u.id
    ORDER BY a.created_at DESC
    LIMIT ${parseInt(limit)}
    OFFSET ${offset}
  `;

  return reply.send({ activities, page: parseInt(page), limit: parseInt(limit) });
});

// ── GET /api/v1/activities/:id ────────────────────────────────────────────
app.get('/api/v1/activities/:id', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const activityId = parseInt(request.params.id);

  const [activity] = await prisma.$queryRaw`
    SELECT
      a.*,
      ST_AsGeoJSON(a.route)::json AS route_geojson,
      u.username, u.profile_picture_url,
      COUNT(DISTINCT k.id)::int AS kudos_count,
      COUNT(DISTINCT c.id)::int AS comments_count
    FROM activities a
    JOIN users u ON u.id = a.user_id
    LEFT JOIN kudos k ON k.activity_id = a.id
    LEFT JOIN comments c ON c.activity_id = a.id
    WHERE a.id = ${activityId}
    GROUP BY a.id, u.id
  `;

  if (!activity) return reply.status(404).send({ error: 'Activity not found' });
  return reply.send(activity);
});

// ── DELETE /api/v1/activities/:id ─────────────────────────────────────────
app.delete('/api/v1/activities/:id', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const activityId = parseInt(request.params.id);
  const userId = request.user.sub;

  const activity = await prisma.activity.findUnique({ where: { id: activityId } });
  if (!activity) return reply.status(404).send({ error: 'Not found' });
  if (activity.userId !== userId) return reply.status(403).send({ error: 'Forbidden' });

  await prisma.activity.delete({ where: { id: activityId } });
  return reply.status(204).send();
});

try {
  await app.listen({
    port: parseInt(process.env.INGESTION_API_PORT || '5002'),
    host: '0.0.0.0'
  });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
```

---

## Spatial Processing Worker

> **File:** `spatial-processing-worker/worker.js`
> This is a **long-running daemon process**, not an HTTP server.

### Package Dependencies

```json
{
  "name": "spatial-processing-worker",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node worker.js"
  },
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "ioredis": "^5.3.2",
    "prisma": "^5.0.0"
  }
}
```

### Complete Implementation

```javascript
// spatial-processing-worker/worker.js
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL);
const QUEUE_NAME = process.env.ACTIVITY_QUEUE_NAME || 'activity_queue';

console.log('[Worker] Spatial processing worker started. Waiting for jobs...');

// ── Graceful Shutdown ──────────────────────────────────────────────────────
process.on('SIGTERM', async () => {
  console.log('[Worker] SIGTERM received. Shutting down gracefully...');
  await redis.quit();
  await prisma.$disconnect();
  process.exit(0);
});

// ── Helper: Build WKT LineString from coordinate array ────────────────────
function buildLineStringWKT(coordinates) {
  if (coordinates.length < 2) throw new Error('Need at least 2 coordinates');
  const points = coordinates
    .map(c => `${c.longitude} ${c.latitude}`)
    .join(', ');
  return `LINESTRING(${points})`;
}

// ── Helper: Calculate elevation gain ──────────────────────────────────────
function calculateElevationGain(coordinates) {
  let gain = 0;
  for (let i = 1; i < coordinates.length; i++) {
    const prev = coordinates[i - 1].elevation ?? 0;
    const curr = coordinates[i].elevation ?? 0;
    if (curr > prev) gain += curr - prev;
  }
  return gain;
}

// ── Helper: Calculate avg pace (seconds per km) ───────────────────────────
function calculateAvgPace(durationSeconds, distanceMeters) {
  if (distanceMeters < 1) return null;
  return (durationSeconds / (distanceMeters / 1000));
}

// ── Main Consumer Loop ────────────────────────────────────────────────────
async function processJob(payload) {
  const {
    userId, title, activityType, startTime,
    durationSeconds, coordinates
  } = payload;

  const lineStringWKT = buildLineStringWKT(coordinates);
  const elevationGain = calculateElevationGain(coordinates);

  // Derive heart rate stats from waypoints if present
  const heartRates = coordinates.map(c => c.heartRate).filter(Boolean);
  const maxHeartRate = heartRates.length ? Math.max(...heartRates) : null;
  const averageHeartRate = heartRates.length
    ? Math.round(heartRates.reduce((a, b) => a + b, 0) / heartRates.length)
    : null;

  await prisma.$transaction(async (tx) => {
    // 1. Create the Activity row with the PostGIS route
    const activity = await tx.$executeRaw`
      INSERT INTO activities (
        user_id, title, activity_type, start_time, duration_seconds, elapsed_time_seconds,
        elevation_gain_meters, max_heart_rate, average_heart_rate, route, created_at
      ) VALUES (
        ${userId}, ${title}, ${activityType}, ${new Date(startTime)}::timestamptz,
        ${durationSeconds}, ${durationSeconds},
        ${elevationGain},
        ${maxHeartRate}, ${averageHeartRate},
        ST_GeogFromText(${lineStringWKT}),
        NOW()
      )
      RETURNING id
    `;

    // Retrieve the inserted activity ID
    const [newActivity] = await tx.$queryRaw`
      SELECT id FROM activities
      WHERE user_id = ${userId}
      ORDER BY created_at DESC
      LIMIT 1
    `;

    const activityId = newActivity.id;

    // 2. Bulk insert all waypoints in a single VALUES statement (chunked)
    const CHUNK_SIZE = 1000;
    for (let i = 0; i < coordinates.length; i += CHUNK_SIZE) {
      const chunk = coordinates.slice(i, i + CHUNK_SIZE);

      // Build parameterized VALUES for bulk insert
      for (const coord of chunk) {
        await tx.$executeRaw`
          INSERT INTO activity_waypoints (
            activity_id, time_stamp, elevation_meters, heart_rate, speed_mps, cadence, accuracy, location
          ) VALUES (
            ${activityId},
            ${new Date(coord.timestamp)}::timestamptz,
            ${coord.elevation ?? null},
            ${coord.heartRate ?? null},
            ${coord.speed ?? null},
            ${coord.cadence ?? null},
            ${coord.accuracy ?? null},
            ST_GeogFromText(${'POINT(' + coord.longitude + ' ' + coord.latitude + ')'})
          )
        `;
      }
    }

    // 3. Post-process: Calculate accurate distance using PostGIS ST_Length (ellipsoidal)
    const [distResult] = await tx.$queryRaw`
      SELECT ST_Length(route) AS distance_meters
      FROM activities
      WHERE id = ${activityId}
    `;

    const distanceMeters = distResult?.distance_meters ?? 0;
    const avgPace = calculateAvgPace(durationSeconds, distanceMeters);

    // 4. Update activity with precise distance + pace
    await tx.$executeRaw`
      UPDATE activities
      SET
        distance_meters = ${distanceMeters},
        average_pace_sec_per_km = ${avgPace}
      WHERE id = ${activityId}
    `;

    // 5. Check and update Personal Records
    await updatePersonalRecords(tx, userId, activityId, distanceMeters, durationSeconds);

    console.log(`[Worker] ✅ Activity ${activityId} processed: ${(distanceMeters / 1000).toFixed(2)}km`);
  });
}

// ── Personal Records Engine ────────────────────────────────────────────────
async function updatePersonalRecords(tx, userId, activityId, distanceMeters, durationSeconds) {
  const pacePerKm = durationSeconds / (distanceMeters / 1000);

  // Longest run record
  const existing = await tx.personalRecord.findUnique({
    where: { userId_recordType: { userId, recordType: 'longest_run' } }
  });
  if (!existing || distanceMeters > existing.value) {
    await tx.personalRecord.upsert({
      where: { userId_recordType: { userId, recordType: 'longest_run' } },
      create: { userId, activityId, recordType: 'longest_run', value: distanceMeters, achievedAt: new Date() },
      update: { activityId, value: distanceMeters, achievedAt: new Date() }
    });
  }

  // Fastest pace (per km) — only for runs >= 1km
  if (distanceMeters >= 1000) {
    const existingPace = await tx.personalRecord.findUnique({
      where: { userId_recordType: { userId, recordType: 'fastest_pace_per_km' } }
    });
    if (!existingPace || pacePerKm < existingPace.value) {
      await tx.personalRecord.upsert({
        where: { userId_recordType: { userId, recordType: 'fastest_pace_per_km' } },
        create: { userId, activityId, recordType: 'fastest_pace_per_km', value: pacePerKm, achievedAt: new Date() },
        update: { activityId, value: pacePerKm, achievedAt: new Date() }
      });
    }
  }
}

// ── Blocking Consumer Loop ─────────────────────────────────────────────────
async function run() {
  while (true) {
    try {
      // BLPOP blocks until an item is available — zero CPU spin
      const result = await redis.blpop(QUEUE_NAME, 0);
      if (!result) continue;

      const [, rawPayload] = result;
      const payload = JSON.parse(rawPayload);

      console.log(`[Worker] Processing job for user ${payload.userId}, ${payload.coordinates.length} GPS points`);

      await processJob(payload);
    } catch (err) {
      console.error('[Worker] ❌ Error processing job:', err.message);
      // Continue loop — do not crash the daemon on a single bad payload
      await new Promise(r => setTimeout(r, 1000)); // backoff on error
    }
  }
}

run();
```

---

## Analytics & Leaderboard Service (Port 5003)

> **File:** `analytics-service/server.js`

```javascript
// analytics-service/server.js
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL);
const app = Fastify({ logger: true });

await app.register(fastifyCors, { origin: '*' });
await app.register(fastifyJwt, { secret: process.env.JWT_SECRET });

app.decorate('authenticate', async (request, reply) => {
  try { await request.jwtVerify(); }
  catch { reply.status(401).send({ error: 'Unauthorized' }); }
});

// ── GET /api/v1/stats/me ──────────────────────────────────────────────────
app.get('/api/v1/stats/me', { onRequest: [app.authenticate] }, async (request, reply) => {
  const userId = request.user.sub;
  const cacheKey = `stats:user:${userId}`;

  const cached = await redis.get(cacheKey);
  if (cached) return reply.send(JSON.parse(cached));

  const [stats] = await prisma.$queryRaw`
    SELECT
      COUNT(*)::int AS total_activities,
      COALESCE(SUM(distance_meters), 0) AS total_distance_meters,
      COALESCE(SUM(duration_seconds), 0) AS total_duration_seconds,
      COALESCE(SUM(elevation_gain_meters), 0) AS total_elevation_gain,
      COALESCE(AVG(average_pace_sec_per_km), 0) AS avg_pace_sec_per_km,
      COALESCE(MAX(distance_meters), 0) AS longest_run_meters
    FROM activities
    WHERE user_id = ${userId}
  `;

  const records = await prisma.personalRecord.findMany({
    where: { userId },
    orderBy: { achievedAt: 'desc' }
  });

  const result = { stats, personalRecords: records };
  await redis.setex(cacheKey, 300, JSON.stringify(result)); // cache 5 min

  return reply.send(result);
});

// ── GET /api/v1/segments/:id/leaderboard ─────────────────────────────────
app.get('/api/v1/segments/:id/leaderboard', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const segmentId = parseInt(request.params.id);
  const cacheKey = `leaderboard:segment:${segmentId}`;

  const cached = await redis.get(cacheKey);
  if (cached) return reply.send(JSON.parse(cached));

  const leaderboard = await prisma.$queryRaw`
    SELECT
      se.user_id,
      u.username,
      u.profile_picture_url,
      MIN(se.elapsed_time_seconds) AS best_time_seconds,
      COUNT(se.id)::int AS attempt_count,
      RANK() OVER (ORDER BY MIN(se.elapsed_time_seconds) ASC)::int AS rank
    FROM segment_efforts se
    JOIN users u ON u.id = se.user_id
    WHERE se.segment_id = ${segmentId}
    GROUP BY se.user_id, u.username, u.profile_picture_url
    ORDER BY best_time_seconds ASC
    LIMIT 50
  `;

  await redis.setex(cacheKey, 60, JSON.stringify(leaderboard)); // cache 1 min
  return reply.send(leaderboard);
});

// ── POST /api/v1/activities/:id/kudos ─────────────────────────────────────
app.post('/api/v1/activities/:id/kudos', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const activityId = parseInt(request.params.id);
  const userId = request.user.sub;

  await prisma.kudo.upsert({
    where: { userId_activityId: { userId, activityId } },
    create: { userId, activityId },
    update: {}
  });

  // Invalidate feed caches for this activity
  await redis.del(`activity:${activityId}`);
  return reply.status(201).send({ success: true });
});

// ── POST /api/v1/activities/:id/comments ──────────────────────────────────
app.post('/api/v1/activities/:id/comments', {
  onRequest: [app.authenticate]
}, async (request, reply) => {
  const activityId = parseInt(request.params.id);
  const userId = request.user.sub;
  const { text } = request.body;

  if (!text?.trim()) return reply.status(400).send({ error: 'Comment text required' });

  const comment = await prisma.comment.create({
    data: { userId, activityId, commentText: text.trim() },
    include: { user: { select: { username: true, profilePictureUrl: true } } }
  });

  return reply.status(201).send(comment);
});

await app.listen({ port: 5003, host: '0.0.0.0' });
```

---

## API Gateway & Reverse Proxy (Port 80/443)

> **File:** `nginx/nginx.conf`

```nginx
events { worker_connections 1024; }

http {
  upstream auth_service     { server auth-user-service:5001; }
  upstream ingestion_api    { server activity-ingestion-api:5002; }
  upstream analytics_svc    { server analytics-service:5003; }

  # Rate limiting zones
  limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;
  limit_req_zone $binary_remote_addr zone=ingest:10m rate=60r/m;
  limit_req_zone $binary_remote_addr zone=api:10m rate=200r/m;

  server {
    listen 80;
    server_name _;

    # Auth endpoints — strict rate limit
    location /api/v1/auth/ {
      limit_req zone=auth burst=5 nodelay;
      proxy_pass http://auth_service;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # User profile endpoints
    location /api/v1/users/ {
      limit_req zone=api burst=20 nodelay;
      proxy_pass http://auth_service;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }

    # Activity ingestion — high throughput
    location /api/v1/ingest {
      limit_req zone=ingest burst=10 nodelay;
      client_max_body_size 50M;
      proxy_pass http://ingestion_api;
      proxy_set_header Host $host;
      proxy_read_timeout 120s;
    }

    # Feed and activity reads
    location /api/v1/feed {
      limit_req zone=api burst=30 nodelay;
      proxy_pass http://ingestion_api;
      proxy_set_header Host $host;
    }

    location /api/v1/activities/ {
      limit_req zone=api burst=30 nodelay;
      proxy_pass http://ingestion_api;
      proxy_set_header Host $host;
    }

    # Analytics, stats, social
    location /api/v1/stats/ {
      limit_req zone=api burst=20 nodelay;
      proxy_pass http://analytics_svc;
      proxy_set_header Host $host;
    }

    location /api/v1/segments/ {
      limit_req zone=api burst=20 nodelay;
      proxy_pass http://analytics_svc;
      proxy_set_header Host $host;
    }
  }
}
```

---

## Infrastructure & DevOps

### `docker-compose.yml` (Production)

```yaml
version: '3.9'

services:
  postgres:
    image: postgis/postgis:16-3.4
    container_name: fittrack_postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: fittrack
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: fittrack_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fittrack -d fittrack_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: fittrack_redis
    restart: unless-stopped
    command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    container_name: fittrack_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - auth-user-service
      - activity-ingestion-api
      - analytics-service

  auth-user-service:
    build: ./auth-user-service
    container_name: fittrack_auth
    restart: unless-stopped
    env_file: .env
    depends_on:
      postgres:
        condition: service_healthy
    command: >
      sh -c "npx prisma migrate deploy && node server.js"

  activity-ingestion-api:
    build: ./activity-ingestion-api
    container_name: fittrack_ingestion
    restart: unless-stopped
    env_file: .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  spatial-processing-worker:
    build: ./spatial-processing-worker
    container_name: fittrack_worker
    restart: unless-stopped
    env_file: .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  analytics-service:
    build: ./analytics-service
    container_name: fittrack_analytics
    restart: unless-stopped
    env_file: .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

volumes:
  postgres_data:
  redis_data:
```

### Shared `Dockerfile` (for all Node.js services)

```dockerfile
# Use this Dockerfile template in each service directory
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM base AS production
COPY . .
# If this service uses Prisma, copy the schema
COPY ../prisma ./prisma
ENV NODE_ENV=production
EXPOSE 5001
CMD ["node", "server.js"]
```

---

## Flutter Mobile Client

### `pubspec.yaml`

```yaml
name: fittrack_pro
description: High-performance fitness tracker
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # HTTP
  dio: ^5.4.3
  dio_smart_retry: ^6.0.0

  # Local Storage
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0

  # Background GPS
  flutter_background_service: ^5.0.5
  geolocator: ^11.0.0
  permission_handler: ^11.3.1

  # Maps
  flutter_map: ^6.2.1
  latlong2: ^0.9.1

  # Navigation
  go_router: ^13.2.0

  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  fl_chart: ^0.68.0  # For stats charts
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^3.0.0
```

### `lib/core/constants.dart`

```dart
class AppConstants {
  // Change this to your server IP for local dev, or your domain for production
  static const String baseUrl = 'http://YOUR_LOCAL_IP:80';
  
  static const String activityQueue = 'activity_queue';
  
  // GPS Tracking
  static const double gpsDistanceFilter = 3.0; // meters
  static const int gpsSaveIntervalMs = 1000;    // save to Hive every 1 second
  
  // Hive Box Names
  static const String trackingBox = 'tracking_waypoints';
  static const String settingsBox = 'settings';
  
  // Activity Types
  static const List<String> activityTypes = ['run', 'ride', 'swim', 'walk', 'hike', 'workout'];
}
```

### `lib/services/tracking_service.dart`

```dart
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Initialize Background Service ─────────────────────────────────────────
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'fittrack_tracking',
      initialNotificationTitle: 'FitTrack Pro',
      initialNotificationContent: 'Tracking your activity...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// ── iOS Background Handler ─────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  await Hive.initFlutter();
  return true;
}

// ── Main Background Isolate ────────────────────────────────────────────────
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  await Hive.initFlutter();
  
  final box = await Hive.openBox<Map>('tracking_waypoints');
  int waypointCount = 0;

  // Notify UI with live stats
  service.on('stopService').listen((event) async {
    await box.close();
    service.stopSelf();
  });

  // ── GPS Stream ──────────────────────────────────────────────────────────
  final positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // meters — adaptive filter
    ),
  );

  positionStream.listen((Position position) async {
    final waypoint = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': position.timestamp.toIso8601String(),
      'elevation': position.altitude,
      'speed': position.speed,
      'accuracy': position.accuracy,
    };

    // Write to Hive immediately — offline-safe
    await box.add(waypoint);
    waypointCount++;

    // Broadcast live data to UI thread
    service.invoke('update', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'waypointCount': waypointCount,
      'timestamp': position.timestamp.toIso8601String(),
    });
  });
}
```

### `lib/services/sync_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class SyncService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  SyncService(this._dio, this._storage);

  // ── Upload buffered GPS data to ingestion API ──────────────────────────
  Future<SyncResult> syncActivity({
    required String title,
    required String activityType,
    required DateTime startTime,
    required int durationSeconds,
  }) async {
    final box = await Hive.openBox<Map>('tracking_waypoints');

    if (box.isEmpty) {
      return SyncResult.failure('No GPS data recorded');
    }

    // Harvest all waypoints from Hive
    final coordinates = box.values
        .map((w) => Map<String, dynamic>.from(w))
        .toList();

    final token = await _storage.read(key: 'auth_token');

    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/api/v1/ingest',
        options: Options(
          headers: { 'Authorization': 'Bearer $token' },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'title': title,
          'activityType': activityType,
          'startTime': startTime.toIso8601String(),
          'durationSeconds': durationSeconds,
          'coordinates': coordinates,
        },
      );

      if (response.statusCode == 202) {
        // Server acknowledged — safe to clear local cache
        await box.clear();
        return SyncResult.success();
      } else {
        return SyncResult.failure('Unexpected response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Network error — keep Hive data for retry
      return SyncResult.failure('Sync failed: ${e.message}. Data kept locally.');
    }
  }
}

class SyncResult {
  final bool success;
  final String? error;
  SyncResult.success() : success = true, error = null;
  SyncResult.failure(this.error) : success = false;
}
```

### `lib/features/tracking/tracking_screen.dart` (Skeleton)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  final List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  
  bool _isTracking = false;
  double _currentSpeed = 0.0;
  int _elapsedSeconds = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _listenToGpsUpdates();
  }

  void _listenToGpsUpdates() {
    _service.on('update').listen((data) {
      if (data == null) return;
      final point = LatLng(
        data['latitude'] as double,
        data['longitude'] as double,
      );
      setState(() {
        _routePoints.add(point);
        _currentSpeed = (data['speed'] as double?) ?? 0.0;
      });
      _mapController.move(point, 16.0);
    });
  }

  Future<void> _startTracking() async {
    await _service.startService();
    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
    });
  }

  Future<void> _stopTracking() async {
    _service.invoke('stopService');
    setState(() { _isTracking = false; });
    // Navigate to save activity screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map Layer ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _routePoints.isNotEmpty
                  ? _routePoints.last
                  : const LatLng(6.9271, 79.8612), // Colombo default
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fittrack.pro',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Colors.orange,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            ],
          ),
          // ── HUD Overlay ────────────────────────────────────────────────
          Positioned(
            bottom: 32, left: 16, right: 16,
            child: _TrackingHUD(
              isTracking: _isTracking,
              speed: _currentSpeed,
              elapsedSeconds: _elapsedSeconds,
              onStart: _startTracking,
              onStop: _stopTracking,
            ),
          ),
        ],
      ),
    );
  }
}

// HUD widget showing speed, distance, time, and start/stop button
class _TrackingHUD extends StatelessWidget {
  final bool isTracking;
  final double speed;
  final int elapsedSeconds;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _TrackingHUD({
    required this.isTracking,
    required this.speed,
    required this.elapsedSeconds,
    required this.onStart,
    required this.onStop,
  });

  String get _formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Time', value: _formattedTime),
                _StatItem(label: 'Speed', value: '${(speed * 3.6).toStringAsFixed(1)} km/h'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isTracking ? onStop : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTracking ? Colors.red : Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isTracking ? 'STOP' : 'START',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```

---

## Security Implementation

### JWT Middleware (shared pattern for all services)

```javascript
// middleware/authenticate.js
export async function authenticate(request, reply) {
  try {
    await request.jwtVerify();
    // request.user is now populated: { sub: userId, username, iat, exp }
  } catch (err) {
    return reply.status(401).send({ error: 'Unauthorized: ' + err.message });
  }
}
```

### Security Checklist

- **Passwords**: bcrypt with minimum 12 rounds. NEVER store plain text.
- **JWT**: Short-lived access tokens (15min) + long-lived refresh tokens (30d). Store refresh tokens in DB, verify before issuing new access tokens.
- **SQL Injection**: All dynamic queries use Prisma's `$queryRaw` with tagged template literals (parameterized). Never use string concatenation in raw SQL.
- **Rate Limiting**: Applied at Nginx and Fastify layers.
- **Input Validation**: All request bodies validated with Zod schemas before processing.
- **CORS**: Lock down origin list in production.
- **Secrets**: Use `.env` file. Never commit to version control. Use Docker secrets or a vault in production.
- **PostGIS Fields**: Unsupported() Prisma fields are write-only via `$executeRaw` — always use `$queryRaw` with `ST_AsGeoJSON()` to read.

---

## Testing Strategy

### Backend Unit Test Pattern (Vitest)

```javascript
// auth-user-service/tests/auth.test.js
import { describe, it, expect, beforeAll, afterAll } from 'vitest';

describe('POST /api/v1/auth/register', () => {
  it('should return 400 for invalid email', async () => {
    const res = await fetch('http://localhost:5001/api/v1/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'test', email: 'not-an-email', password: 'password123' })
    });
    expect(res.status).toBe(400);
  });

  it('should return 201 and token for valid registration', async () => {
    const res = await fetch('http://localhost:5001/api/v1/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'testuser99', email: 'test99@test.com', password: 'Securepass1!' })
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.token).toBeDefined();
  });
});
```

### Flutter Widget Test Pattern

```dart
// test/tracking_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_pro/features/tracking/tracking_screen.dart';

void main() {
  testWidgets('TrackingScreen shows START button initially', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrackingScreen()));
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsNothing);
  });
}
```

---

## Cursor.ai Code Generation Prompts

Use these exact prompts in Cursor.ai to generate specific parts of the codebase:

### 1. Generate Full Auth Service
```
Using the schema and spec in MASTER_BLUEPRINT.md, generate the complete 
auth-user-service/server.js with all routes, JWT authentication, bcrypt 
password hashing, Zod validation, and Prisma integration. 
Use ESM modules and Fastify 4.x.
```

### 2. Generate Spatial Worker
```
Based on MASTER_BLUEPRINT.md, generate the spatial-processing-worker/worker.js.
It must: use redis.blpop() in an infinite loop, build WKT LINESTRING from 
coordinate arrays, use prisma.$transaction with raw PostGIS SQL 
(ST_GeogFromText, ST_Length), bulk insert waypoints in chunks of 1000, 
and update personal records. Handle errors without crashing the daemon.
```

### 3. Generate Flutter Tracking Screen
```
Using MASTER_BLUEPRINT.md Flutter spec, generate a complete TrackingScreen
in Flutter with: flutter_background_service GPS isolate, flutter_map with 
orange PolylineLayer on OpenStreetMap tiles, real-time HUD showing speed 
and elapsed time, and START/STOP controls that trigger background service.
```

### 4. Generate Feed Screen
```
Using MASTER_BLUEPRINT.md, generate the Flutter feed screen that: 
fetches from GET /api/v1/feed with JWT auth header via Dio, displays 
activity cards with distance/time/elevation, renders a mini flutter_map 
per card using route_geojson from the API, and shows kudos count with 
a tap-to-kudo button.
```

### 5. Generate Docker Compose
```
Generate the full docker-compose.yml from MASTER_BLUEPRINT.md with: 
postgis/postgis:16-3.4 image, Redis 7 alpine, Nginx reverse proxy, 
and all 4 Node.js services. Include health checks, restart policies, 
and env_file references.
```

### 6. Generate Prisma Migration Script
```
Generate the full prisma/schema.prisma from MASTER_BLUEPRINT.md and a
companion SQL file that enables PostGIS, creates all spatial GIST indexes,
and sets up the covering index for feed queries.
```

### 7. Generate Analytics Service
```
Generate analytics-service/server.js from MASTER_BLUEPRINT.md with: 
personal stats endpoint (total distance, time, elevation), segment 
leaderboard with RANK() window function, kudos and comments endpoints,
and Redis caching with 5-minute TTL for stats and 1-minute TTL for leaderboards.
```

---

## Development Quickstart

```bash
# 1. Clone and enter project
git clone <repo> fittrack-pro && cd fittrack-pro

# 2. Copy and configure env
cp .env.example .env
# Edit .env — set strong JWT_SECRET, DB_PASSWORD

# 3. Start all infrastructure
docker-compose up -d postgres redis

# 4. Run Prisma migrations
cd auth-user-service
npx prisma migrate dev --name init

# 5. Apply PostGIS indexes (run against your DB)
psql $DATABASE_URL -f migrations/postgis_indexes.sql

# 6. Start all services in dev mode
docker-compose up

# 7. Flutter setup
cd strava_alternative_app
flutter pub get
flutter run
```

---

## API Reference Summary

| Method | Path | Service | Auth | Description |
|--------|------|---------|------|-------------|
| POST | `/api/v1/auth/register` | Auth | ❌ | Create account |
| POST | `/api/v1/auth/login` | Auth | ❌ | Login, get tokens |
| POST | `/api/v1/auth/refresh` | Auth | ❌ | Refresh access token |
| GET | `/api/v1/users/:id` | Auth | ✅ | Get user profile + activities |
| PUT | `/api/v1/users/me` | Auth | ✅ | Update own profile |
| POST | `/api/v1/users/:id/follow` | Auth | ✅ | Follow a user |
| DELETE | `/api/v1/users/:id/follow` | Auth | ✅ | Unfollow a user |
| POST | `/api/v1/ingest` | Ingestion | ✅ | Submit GPS activity (→ Redis) |
| GET | `/api/v1/feed` | Ingestion | ✅ | Paginated activity feed |
| GET | `/api/v1/activities/:id` | Ingestion | ✅ | Single activity detail |
| DELETE | `/api/v1/activities/:id` | Ingestion | ✅ | Delete own activity |
| GET | `/api/v1/stats/me` | Analytics | ✅ | Personal lifetime stats |
| GET | `/api/v1/segments/:id/leaderboard` | Analytics | ✅ | Segment leaderboard |
| POST | `/api/v1/activities/:id/kudos` | Analytics | ✅ | Give kudo |
| POST | `/api/v1/activities/:id/comments` | Analytics | ✅ | Post comment |

---

*Document version: 1.0 — Generated for FitTrack Pro production development*




Mobile / web app (what you can use in the UI)
Authentication
Register and login with email/password
JWT stored in secure storage; auto token refresh on 401
Logout from Profile
Feed (home tab)
Activity feed from you and people you follow
Pull-to-refresh
Activity cards: title, user, distance, duration, elevation
Map preview of route (OpenStreetMap) when route data exists
Give kudos (like) on activities
Comment count shown (posting comments is not wired in the UI)
Track (GPS tab)
Live GPS tracking on Android/iOS only (background service + map)
Start/stop timer, speed display
Save activity screen: title, activity type (run, ride, swim, walk, hike, workout)
Offline-first sync: waypoints stored in Hive, uploaded via /api/v1/ingest
On web/desktop: tracking is disabled (shows a message instead)
Profile
Personal stats: total distance, activities, elevation, longest run
Personal records list (when present)
Logout
Segments
List segments
Segment leaderboard (rank, username, best time, attempts)
Backend API (implemented, not all exposed in the app)
Feature	API	In Flutter UI?
User profile by ID
GET /api/v1/users/:id
No
Edit profile (bio, username)
PUT /api/v1/users/me
No
Follow / unfollow
POST/DELETE /api/v1/users/:id/follow
No
Activity detail
GET /api/v1/activities/:id
No
Delete activity
DELETE /api/v1/activities/:id
No
Post comment
POST /api/v1/activities/:id/comments
No (count only)
Create segment
POST /api/v1/segments
No
Token refresh
POST /api/v1/auth/refresh
Yes (automatic)
Backend pipeline (behind the scenes)
Auth service — users, bcrypt passwords, JWT
Ingestion API — accepts activities → Redis queue (202 response)
Spatial worker — processes GPS: PostGIS route, waypoints, distance, pace, personal records
Analytics service — stats, segments, kudos, comments, leaderboards (Redis cache)
Dev gateway — single entry point on port 8081
Infrastructure (repo includes, not fully local without setup)
Docker Compose (Postgres+PostGIS, Redis, nginx, all services)
Prometheus/Grafana config under monitoring/
Dev scripts: start-all, seed, DB bootstrap
Current limitations (from your dev setup)
PostGIS not installed locally → full spatial schema, route maps, ingest processing, and segment creation are limited or empty
Feed/segments work but may show no data until activities exist and PostGIS is set up
Web app works for auth, feed, profile, segments; GPS tracking needs a phone/emulator
No UI yet for: comments, follows, profile editing, creating segments, activity detail page
In short: it’s a working Strava-style skeleton with auth, feed, kudos, GPS tracking (mobile), activity upload, stats, and segment leaderboards. Social features (comments, follow, profile edit) and full map/spatial features are mostly API-ready but not fully built in the UI or blocked until PostGIS is installed.