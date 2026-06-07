import './load-env.js';
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';
import { statsRoutes } from './routes/stats.routes.js';
import { segmentsRoutes } from './routes/segments.routes.js';
import { socialRoutes } from './routes/social.routes.js';

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
const app = Fastify({ logger: true });

await app.register(fastifyCors, { origin: '*' });
await app.register(fastifyJwt, { secret: process.env.JWT_SECRET || 'dev-secret-change-me' });

await statsRoutes(app, { prisma, redis });
await segmentsRoutes(app, { prisma, redis });
await socialRoutes(app, { prisma, redis });

app.get('/health', async () => ({ status: 'ok', service: 'analytics-service' }));

try {
  await app.listen({
    port: parseInt(process.env.ANALYTICS_SERVICE_PORT || '5003', 10),
    host: '0.0.0.0'
  });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
