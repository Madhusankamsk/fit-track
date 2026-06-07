import { z } from 'zod';
import { authenticate } from '../middleware/authenticate.js';

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
    parseInt(process.env.MAX_WAYPOINTS_PER_ACTIVITY || '100000', 10)
  )
});

export async function ingestRoutes(app, { redis }) {
  app.post('/api/v1/ingest', {
    onRequest: [authenticate]
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

    return reply.status(202).send({ accepted: true, queuedAt: payload.receivedAt });
  });
}
