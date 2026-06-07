# Security

## Authentication

### JWT Access Tokens
- Signed with `JWT_SECRET` via `@fastify/jwt`
- Default lifetime: **15 minutes** (`JWT_EXPIRES_IN`)
- Payload: `{ sub: userId, username, iat, exp }`
- Sent as `Authorization: Bearer <token>`

### Refresh Tokens
- Issued on login with **30-day** lifetime
- Stored in the `users.refresh_token` column
- Verified against DB before issuing a new access token
- Invalidated if token in DB doesn't match the submitted refresh token

### Password Hashing
- bcrypt with **12 rounds** minimum (`BCRYPT_ROUNDS`)
- Passwords never stored in plain text
- Max password length: 72 chars (bcrypt limit)

## Input Validation

All request bodies are validated with **Zod** before processing:

| Service | Schemas |
|---------|---------|
| Auth | `registerSchema`, `loginSchema`, `updateProfileSchema` |
| Ingestion | `ingestSchema`, `coordinateSchema` |
| Analytics | `createSegmentSchema` |

Validation failures return `400` with Zod flatten output.

## SQL Injection Prevention

- Prisma ORM queries are parameterized by default
- PostGIS raw queries use tagged template literals (`$queryRaw`, `$executeRaw`) — never string concatenation
- Example (safe):
  ```javascript
  await prisma.$queryRaw`SELECT * FROM activities WHERE id = ${activityId}`
  ```

## Rate Limiting

Applied at two layers:

### Fastify (`@fastify/rate-limit`)
- Auth service: 100 req/min
- Ingestion API: 200 req/min

### Nginx (production)
- Auth: 10 req/min (burst 5)
- Ingest: 60 req/min (burst 10)
- General API: 200 req/min (burst 20–30)

## CORS

Development: `origin: '*'` on all Fastify services.

**Production:** Replace with an explicit allowlist of client origins.

## PostGIS Field Safety

Geography columns are `Unsupported()` in Prisma — they cannot be read or written through the ORM. All spatial operations go through raw SQL with parameterized WKT strings.

## Secrets Management

- `.env` file for local development — **never commit**
- Docker Compose uses `env_file: .env`
- Production: use Docker secrets, a vault, or cloud provider secret managers
- Rotate `JWT_SECRET` periodically; existing tokens will invalidate

## Authorization Rules

| Action | Rule |
|--------|------|
| Delete activity | Owner only (`activity.userId === request.user.sub`) |
| Update profile | Own profile only (`/users/me`) |
| Follow | Cannot follow yourself |
| Kudos | Idempotent upsert; any authenticated user |
| Feed | Public activities from self + followed users |

## Security Checklist

- [ ] Strong random `JWT_SECRET` (256-bit)
- [ ] bcrypt rounds ≥ 12
- [ ] Zod validation on all inputs
- [ ] Parameterized raw SQL only
- [ ] Rate limiting enabled
- [ ] CORS locked down in production
- [ ] HTTPS via Nginx in production
- [ ] `.env` in `.gitignore`
- [ ] Refresh tokens stored and verified in DB

## Related Documents

- [API Reference](api-reference.md)
- [Environment Variables](environment-variables.md)
