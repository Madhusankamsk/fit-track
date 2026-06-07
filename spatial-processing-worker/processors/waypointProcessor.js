const CHUNK_SIZE = 1000;

export async function insertWaypoints(tx, activityId, coordinates) {
  for (let i = 0; i < coordinates.length; i += CHUNK_SIZE) {
    const chunk = coordinates.slice(i, i + CHUNK_SIZE);
    for (const coord of chunk) {
      const pointWkt = `POINT(${coord.longitude} ${coord.latitude})`;
      await tx.$executeRaw`
        INSERT INTO activity_waypoints (
          activity_id, time_stamp, elevation_meters, heart_rate, speed_mps, cadence, accuracy, location
        ) VALUES (
          ${activityId},
          ${new Date(coord.timestamp)}::timestamptz,
          ${coord.elevation ?? null},
          ${coord.heartRate ?? null},
          ${coord.speed ?? null},
          ${coord.cadence ?? null},
          ${coord.accuracy ?? null},
          ST_GeogFromText(${pointWkt})
        )
      `;
    }
  }
}

export async function updatePersonalRecords(tx, userId, activityId, distanceMeters, durationSeconds) {
  const pacePerKm = durationSeconds / (distanceMeters / 1000);

  const existing = await tx.personalRecord.findUnique({
    where: { userId_recordType: { userId, recordType: 'longest_run' } }
  });
  if (!existing || distanceMeters > existing.value) {
    await tx.personalRecord.upsert({
      where: { userId_recordType: { userId, recordType: 'longest_run' } },
      create: {
        userId,
        activityId,
        recordType: 'longest_run',
        value: distanceMeters,
        achievedAt: new Date()
      },
      update: { activityId, value: distanceMeters, achievedAt: new Date() }
    });
  }

  if (distanceMeters >= 1000) {
    const existingPace = await tx.personalRecord.findUnique({
      where: { userId_recordType: { userId, recordType: 'fastest_pace_per_km' } }
    });
    if (!existingPace || pacePerKm < existingPace.value) {
      await tx.personalRecord.upsert({
        where: { userId_recordType: { userId, recordType: 'fastest_pace_per_km' } },
        create: {
          userId,
          activityId,
          recordType: 'fastest_pace_per_km',
          value: pacePerKm,
          achievedAt: new Date()
        },
        update: { activityId, value: pacePerKm, achievedAt: new Date() }
      });
    }
  }
}
