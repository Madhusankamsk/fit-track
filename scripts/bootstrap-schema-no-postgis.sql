-- Dev schema bootstrap without PostGIS (auth, stats, feed work; maps/segments need PostGIS).

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

-- Mark init migration applied so Prisma does not retry on every deploy.
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
SELECT gen_random_uuid()::text, '', NOW(), '20240607000000_init', NULL, NULL, NOW(), 1
WHERE NOT EXISTS (
    SELECT 1 FROM _prisma_migrations
    WHERE migration_name = '20240607000000_init' AND finished_at IS NOT NULL
);
