import { authenticate } from '../middleware/authenticate.js';

export async function statsRoutes(app, { prisma, redis }) {
  app.get('/api/v1/stats/me', { onRequest: [authenticate] }, async (request, reply) => {
    const userId = request.user.sub;
    const cacheKey = `stats:user:${userId}`;

    const cached = await redis.get(cacheKey);
    if (cached) return reply.send(JSON.parse(cached));

    const rows = await prisma.$queryRaw`
      SELECT
        COUNT(*)::int AS total_activities,
        COALESCE(SUM(distance_meters), 0)::float8 AS total_distance_meters,
        COALESCE(SUM(duration_seconds), 0)::int AS total_duration_seconds,
        COALESCE(SUM(elevation_gain_meters), 0)::float8 AS total_elevation_gain,
        COALESCE(AVG(average_pace_sec_per_km), 0)::float8 AS avg_pace_sec_per_km,
        COALESCE(MAX(distance_meters), 0)::float8 AS longest_run_meters
      FROM activities
      WHERE user_id = ${userId}
    `;

    const stats = rows[0];

    const records = await prisma.personalRecord.findMany({
      where: { userId },
      orderBy: { achievedAt: 'desc' }
    });

    const result = { stats, personalRecords: records };
    await redis.setex(cacheKey, 300, JSON.stringify(result));

    return reply.send(result);
  });
}
