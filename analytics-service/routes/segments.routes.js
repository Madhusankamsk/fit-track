import { z } from 'zod';
import { authenticate } from '../middleware/authenticate.js';

const createSegmentSchema = z.object({
  name: z.string().min(1).max(100),
  startLatitude: z.number().min(-90).max(90),
  startLongitude: z.number().min(-180).max(180),
  endLatitude: z.number().min(-90).max(90),
  endLongitude: z.number().min(-180).max(180),
  routeCoordinates: z.array(z.object({
    latitude: z.number(),
    longitude: z.number()
  })).min(2)
});

export async function segmentsRoutes(app, { prisma, redis }) {
  app.get('/api/v1/segments', { onRequest: [authenticate] }, async (_request, reply) => {
    try {
      const segments = await prisma.$queryRaw`
        SELECT
          s.id,
          s.name,
          s.distance_meters,
          s.created_by_id,
          s.created_at,
          ST_AsGeoJSON(s.segment_route)::json AS route_geojson
        FROM segments s
        ORDER BY s.created_at DESC
        LIMIT 100
      `;
      return reply.send({ segments });
    } catch (err) {
      if (err?.code === 'P2010') {
        return reply.send({ segments: [] });
      }
      throw err;
    }
  });

  app.post('/api/v1/segments', { onRequest: [authenticate] }, async (request, reply) => {
    const result = createSegmentSchema.safeParse(request.body);
    if (!result.success) {
      return reply.status(400).send({ error: result.error.flatten() });
    }

    const { name, startLatitude, startLongitude, endLatitude, endLongitude, routeCoordinates } = result.data;
    const userId = request.user.sub;

    const lineWkt = `LINESTRING(${routeCoordinates.map((c) => `${c.longitude} ${c.latitude}`).join(', ')})`;
    const startWkt = `POINT(${startLongitude} ${startLatitude})`;
    const endWkt = `POINT(${endLongitude} ${endLatitude})`;

    await prisma.$executeRaw`
      INSERT INTO segments (name, distance_meters, created_by_id, start_point, end_point, segment_route, created_at)
      VALUES (
        ${name},
        ST_Length(ST_GeogFromText(${lineWkt})),
        ${userId},
        ST_GeogFromText(${startWkt}),
        ST_GeogFromText(${endWkt}),
        ST_GeogFromText(${lineWkt}),
        NOW()
      )
    `;

    const [segment] = await prisma.$queryRaw`
      SELECT id, name, distance_meters, created_at
      FROM segments
      WHERE created_by_id = ${userId}
      ORDER BY created_at DESC
      LIMIT 1
    `;

    return reply.status(201).send(segment);
  });

  app.get('/api/v1/segments/:id/leaderboard', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const segmentId = parseInt(request.params.id, 10);
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

    await redis.setex(cacheKey, 60, JSON.stringify(leaderboard));
    return reply.send(leaderboard);
  });
}
