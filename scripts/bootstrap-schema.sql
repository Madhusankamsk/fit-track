-- Bootstrap FitTrack schema when Prisma migrate cannot run (e.g. PostGIS missing).
-- Safe to re-run: uses IF NOT EXISTS throughout.

CREATE TABLE IF NOT EXISTS follows (
    id SERIAL PRIMARY KEY,
    follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (follower_id, following_id)
);

CREATE TABLE IF NOT EXISTS activities (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    activity_type VARCHAR(20) NOT NULL DEFAULT 'run',
    distance_meters DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    elapsed_time_seconds INTEGER NOT NULL DEFAULT 0,
    elevation_gain_meters DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    max_heart_rate INTEGER,
    average_heart_rate INTEGER,
    calories_burned INTEGER,
    average_pace_sec_per_km DOUBLE PRECISION,
    is_public BOOLEAN NOT NULL DEFAULT true,
    start_time TIMESTAMP(3) NOT NULL,
    route geography(LineString, 4326),
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS activity_waypoints (
    id BIGSERIAL PRIMARY KEY,
    activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    time_stamp TIMESTAMP(3) NOT NULL,
    elevation_meters DOUBLE PRECISION,
    heart_rate INTEGER,
    speed_mps DOUBLE PRECISION,
    cadence INTEGER,
    accuracy DOUBLE PRECISION,
    location geography(Point, 4326) NOT NULL
);

CREATE INDEX IF NOT EXISTS activity_waypoints_activity_id_idx ON activity_waypoints(activity_id);

CREATE TABLE IF NOT EXISTS segments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    distance_meters DOUBLE PRECISION NOT NULL,
    created_by_id INTEGER NOT NULL,
    start_point geography(Point, 4326) NOT NULL,
    end_point geography(Point, 4326) NOT NULL,
    segment_route geography(LineString, 4326) NOT NULL,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS segment_efforts (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    segment_id INTEGER NOT NULL REFERENCES segments(id) ON DELETE CASCADE,
    elapsed_time_seconds INTEGER NOT NULL,
    average_heart_rate INTEGER,
    rank INTEGER,
    is_kom BOOLEAN NOT NULL DEFAULT false,
    start_time TIMESTAMP(3) NOT NULL,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS kudos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, activity_id)
);

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS personal_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    record_type VARCHAR(50) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    achieved_at TIMESTAMP(3) NOT NULL,
    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, record_type)
);
