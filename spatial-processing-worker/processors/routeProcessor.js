export function buildLineStringWKT(coordinates) {
  if (coordinates.length < 2) throw new Error('Need at least 2 coordinates');
  const points = coordinates
    .map((c) => `${c.longitude} ${c.latitude}`)
    .join(', ');
  return `LINESTRING(${points})`;
}

export function calculateElevationGain(coordinates) {
  let gain = 0;
  for (let i = 1; i < coordinates.length; i++) {
    const prev = coordinates[i - 1].elevation ?? 0;
    const curr = coordinates[i].elevation ?? 0;
    if (curr > prev) gain += curr - prev;
  }
  return gain;
}

export function calculateAvgPace(durationSeconds, distanceMeters) {
  if (distanceMeters < 1) return null;
  return durationSeconds / (distanceMeters / 1000);
}

export function extractHeartRateStats(coordinates) {
  const heartRates = coordinates.map((c) => c.heartRate).filter(Boolean);
  if (!heartRates.length) return { maxHeartRate: null, averageHeartRate: null };
  return {
    maxHeartRate: Math.max(...heartRates),
    averageHeartRate: Math.round(heartRates.reduce((a, b) => a + b, 0) / heartRates.length)
  };
}
