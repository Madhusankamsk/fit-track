import './load-env.js';
import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';
import {
  buildLineStringWKT,
  calculateElevationGain,
  calculateAvgPace,
  extractHeartRateStats
} from './processors/routeProcessor.js';
import { insertWaypoints, updatePersonalRecords } from './processors/waypointProcessor.js';

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
const QUEUE_NAME = process.env.ACTIVITY_QUEUE_NAME || 'activity_queue';

console.log('[Worker] Spatial processing worker started. Waiting for jobs...');

process.on('SIGTERM', async () => {
  console.log('[Worker] SIGTERM received. Shutting down gracefully...');
  await redis.quit();
  await prisma.$disconnect();
  process.exit(0);
});

function toActivityId(row) {
  const id = row?.id;
  return typeof id === 'bigint' ? Number(id) : id;
}

async function processJob(payload) {
  const { userId, title, activityType, startTime, durationSeconds, coordinates } = payload;

  const lineStringWKT = buildLineStringWKT(coordinates);
  const elevationGain = calculateElevationGain(coordinates);
  const { maxHeartRate, averageHeartRate } = extractHeartRateStats(coordinates);

  await prisma.$transaction(async (tx) => {
    const inserted = await tx.$queryRaw`
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

    const activityId = toActivityId(inserted[0]);
    if (!activityId) {
      throw new Error('Activity insert did not return an id');
    }

    await insertWaypoints(tx, activityId, coordinates);

    const [distResult] = await tx.$queryRaw`
      SELECT ST_Length(route) AS distance_meters
      FROM activities
      WHERE id = ${activityId}
    `;

    const rawDistance = distResult?.distance_meters ?? 0;
    const distanceMeters = typeof rawDistance === 'bigint' ? Number(rawDistance) : rawDistance;
    const avgPace = calculateAvgPace(durationSeconds, distanceMeters);

    await tx.$executeRaw`
      UPDATE activities
      SET
        distance_meters = ${distanceMeters},
        average_pace_sec_per_km = ${avgPace}
      WHERE id = ${activityId}
    `;

    await updatePersonalRecords(tx, userId, activityId, distanceMeters, durationSeconds);

    console.log(`[Worker] Activity ${activityId} processed: ${(distanceMeters / 1000).toFixed(2)}km`);
  });
}

async function run() {
  while (true) {
    try {
      const result = await redis.blpop(QUEUE_NAME, 0);
      if (!result) continue;

      const [, rawPayload] = result;
      const payload = JSON.parse(rawPayload);

      console.log(`[Worker] Processing job for user ${payload.userId}, ${payload.coordinates.length} GPS points`);

      await processJob(payload);
    } catch (err) {
      console.error('[Worker] Error processing job:', err.message);
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
}

run();
