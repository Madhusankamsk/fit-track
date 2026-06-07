import { authenticate } from '../middleware/authenticate.js';

function isMissingRouteColumn(err) {
  return err?.code === 'P2010' && String(err?.message || '').includes('route');
}

export async function feedRoutes(app, { prisma }) {
  app.get('/api/v1/feed', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const { page = 1, limit = 20 } = request.query;
    const pageNum = parseInt(page, 10);
    const limitNum = parseInt(limit, 10);
    const offset = (pageNum - 1) * limitNum;
    const userId = request.user.sub;

    let activities;
    try {
      activities = await prisma.$queryRaw`
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
        LIMIT ${limitNum}
        OFFSET ${offset}
      `;
    } catch (err) {
      if (!isMissingRouteColumn(err)) throw err;
      activities = await prisma.$queryRaw`
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
          NULL::json AS route_geojson,
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
        LIMIT ${limitNum}
        OFFSET ${offset}
      `;
    }

    return reply.send({ activities, page: pageNum, limit: limitNum });
  });

  app.get('/api/v1/activities/:id', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const activityId = parseInt(request.params.id, 10);

    let rows;
    try {
      rows = await prisma.$queryRaw`
        SELECT
          a.id,
          a.user_id,
          a.title,
          a.description,
          a.activity_type,
          a.distance_meters,
          a.duration_seconds,
          a.elapsed_time_seconds,
          a.elevation_gain_meters,
          a.max_heart_rate,
          a.average_heart_rate,
          a.calories_burned,
          a.average_pace_sec_per_km,
          a.is_public,
          a.start_time,
          a.created_at,
          ST_AsGeoJSON(a.route)::json AS route_geojson,
          u.username,
          u.profile_picture_url,
          COUNT(DISTINCT k.id)::int AS kudos_count,
          COUNT(DISTINCT c.id)::int AS comments_count
        FROM activities a
        JOIN users u ON u.id = a.user_id
        LEFT JOIN kudos k ON k.activity_id = a.id
        LEFT JOIN comments c ON c.activity_id = a.id
        WHERE a.id = ${activityId}
        GROUP BY a.id, u.id
      `;
    } catch (err) {
      if (!isMissingRouteColumn(err)) throw err;
      rows = await prisma.$queryRaw`
        SELECT
          a.id,
          a.user_id,
          a.title,
          a.description,
          a.activity_type,
          a.distance_meters,
          a.duration_seconds,
          a.elapsed_time_seconds,
          a.elevation_gain_meters,
          a.max_heart_rate,
          a.average_heart_rate,
          a.calories_burned,
          a.average_pace_sec_per_km,
          a.is_public,
          a.start_time,
          a.created_at,
          NULL::json AS route_geojson,
          u.username,
          u.profile_picture_url,
          COUNT(DISTINCT k.id)::int AS kudos_count,
          COUNT(DISTINCT c.id)::int AS comments_count
        FROM activities a
        JOIN users u ON u.id = a.user_id
        LEFT JOIN kudos k ON k.activity_id = a.id
        LEFT JOIN comments c ON c.activity_id = a.id
        WHERE a.id = ${activityId}
        GROUP BY a.id, u.id
      `;
    }

    const activity = rows[0];
    if (!activity) return reply.status(404).send({ error: 'Activity not found' });
    return reply.send(activity);
  });

  app.delete('/api/v1/activities/:id', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const activityId = parseInt(request.params.id, 10);
    const userId = request.user.sub;

    const activity = await prisma.activity.findUnique({ where: { id: activityId } });
    if (!activity) return reply.status(404).send({ error: 'Not found' });
    if (activity.userId !== userId) return reply.status(403).send({ error: 'Forbidden' });

    await prisma.activity.delete({ where: { id: activityId } });
    return reply.status(204).send();
  });
}
