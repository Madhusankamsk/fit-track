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

function toIsoString(value) {
  if (value == null || value === '') return value;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toISOString();
}

function toNumber(value) {
  if (value == null || value === '') return undefined;
  const num = Number(value);
  return Number.isFinite(num) ? num : undefined;
}

function sanitizeIngestBody(body) {
  if (!body || typeof body !== 'object') return body;

  const next = { ...body };

  if (next.startTime != null) {
    next.startTime = toIsoString(next.startTime);
  }

  const duration = toNumber(next.durationSeconds);
  if (duration != null) {
    next.durationSeconds = Math.max(0, Math.round(duration));
  }

  if (!Array.isArray(next.coordinates)) return next;

  const coordinates = next.coordinates
    .map((coord) => {
      if (!coord || typeof coord !== 'object') return null;

      const latitude = toNumber(coord.latitude);
      const longitude = toNumber(coord.longitude);
      const timestamp = toIsoString(coord.timestamp);

      if (latitude == null || longitude == null || !timestamp) return null;

      const cleaned = { latitude, longitude, timestamp };

      const elevation = toNumber(coord.elevation);
      if (elevation != null) cleaned.elevation = elevation;

      const speed = toNumber(coord.speed);
      if (speed != null && speed >= 0) cleaned.speed = speed;

      const accuracy = toNumber(coord.accuracy);
      if (accuracy != null && accuracy >= 0) cleaned.accuracy = accuracy;

      const heartRate = toNumber(coord.heartRate);
      if (heartRate != null && heartRate >= 0) {
        cleaned.heartRate = Math.round(heartRate);
      }

      const cadence = toNumber(coord.cadence);
      if (cadence != null && cadence >= 0) {
        cleaned.cadence = Math.round(cadence);
      }

      return cleaned;
    })
    .filter(Boolean);

  if (coordinates.length === 1) {
    const only = coordinates[0];
    const ts = new Date(only.timestamp);
    coordinates.push({
      ...only,
      timestamp: new Date(ts.getTime() + 1000).toISOString(),
    });
  }

  return { ...next, coordinates };
}

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
    const sanitized = sanitizeIngestBody(request.body);
    const result = ingestSchema.safeParse(sanitized);
    if (!result.success) {
      request.log.warn({ body: sanitized, errors: result.error.flatten() }, 'ingest validation failed');
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
