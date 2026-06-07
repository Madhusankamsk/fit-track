import './load-env.js';
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyRateLimit from '@fastify/rate-limit';
import { PrismaClient } from '@prisma/client';
import { authRoutes } from './routes/auth.routes.js';
import { usersRoutes } from './routes/users.routes.js';

const prisma = new PrismaClient();
const app = Fastify({ logger: true });

await app.register(fastifyCors, {
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});
await app.register(fastifyJwt, { secret: process.env.JWT_SECRET || 'dev-secret-change-me' });
await app.register(fastifyRateLimit, {
  max: 100,
  timeWindow: '1 minute'
});

await authRoutes(app, { prisma });
await usersRoutes(app, { prisma });

app.get('/health', async () => ({ status: 'ok', service: 'auth-user-service' }));

try {
  await app.listen({
    port: parseInt(process.env.AUTH_SERVICE_PORT || '5001', 10),
    host: '0.0.0.0'
  });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
