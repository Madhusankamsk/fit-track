-- Run after prisma migrate dev: psql $DATABASE_URL -f prisma/migrations/postgis_indexes.sql

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE INDEX IF NOT EXISTS idx_activity_waypoints_location
  ON activity_waypoints USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_activities_route
  ON activities USING GIST (route);

CREATE INDEX IF NOT EXISTS idx_segments_start_point
  ON segments USING GIST (start_point);

CREATE INDEX IF NOT EXISTS idx_segments_segment_route
  ON segments USING GIST (segment_route);

CREATE INDEX IF NOT EXISTS idx_activities_user_created
  ON activities (user_id, created_at DESC);
