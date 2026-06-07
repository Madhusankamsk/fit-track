import './load-env.js';
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyRateLimit from '@fastify/rate-limit';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';
import { ingestRoutes } from './routes/ingest.routes.js';
import { feedRoutes } from './routes/feed.routes.js';

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
const app = Fastify({ logger: true });

await app.register(fastifyCors, { origin: '*' });
await app.register(fastifyJwt, { secret: process.env.JWT_SECRET || 'dev-secret-change-me' });
await app.register(fastifyRateLimit, { max: 200, timeWindow: '1 minute' });

await ingestRoutes(app, { redis });
await feedRoutes(app, { prisma });

app.get('/health', async () => ({ status: 'ok', service: 'activity-ingestion-api' }));

try {
  await app.listen({
    port: parseInt(process.env.INGESTION_API_PORT || '5002', 10),
    host: '0.0.0.0'
  });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
