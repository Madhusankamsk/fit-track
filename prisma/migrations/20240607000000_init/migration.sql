-- CreateTable
CREATE TABLE "users" (
    "id" SERIAL NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "email" VARCHAR(100) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "bio" TEXT,
    "profile_picture_url" VARCHAR(255),
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "refresh_token" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "follows" (
    "id" SERIAL NOT NULL,
    "follower_id" INTEGER NOT NULL,
    "following_id" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "follows_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "activities" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "title" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "activity_type" VARCHAR(20) NOT NULL DEFAULT 'run',
    "distance_meters" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "duration_seconds" INTEGER NOT NULL DEFAULT 0,
    "elapsed_time_seconds" INTEGER NOT NULL DEFAULT 0,
    "elevation_gain_meters" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "max_heart_rate" INTEGER,
    "average_heart_rate" INTEGER,
    "calories_burned" INTEGER,
    "average_pace_sec_per_km" DOUBLE PRECISION,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "start_time" TIMESTAMP(3) NOT NULL,
    "route" geography(LineString, 4326),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "activities_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "activity_waypoints" (
    "id" BIGSERIAL NOT NULL,
    "activity_id" INTEGER NOT NULL,
    "time_stamp" TIMESTAMP(3) NOT NULL,
    "elevation_meters" DOUBLE PRECISION,
    "heart_rate" INTEGER,
    "speed_mps" DOUBLE PRECISION,
    "cadence" INTEGER,
    "accuracy" DOUBLE PRECISION,
    "location" geography(Point, 4326) NOT NULL,

    CONSTRAINT "activity_waypoints_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "segments" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "distance_meters" DOUBLE PRECISION NOT NULL,
    "created_by_id" INTEGER NOT NULL,
    "start_point" geography(Point, 4326) NOT NULL,
    "end_point" geography(Point, 4326) NOT NULL,
    "segment_route" geography(LineString, 4326) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "segments_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "segment_efforts" (
    "id" BIGSERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "activity_id" INTEGER NOT NULL,
    "segment_id" INTEGER NOT NULL,
    "elapsed_time_seconds" INTEGER NOT NULL,
    "average_heart_rate" INTEGER,
    "rank" INTEGER,
    "is_kom" BOOLEAN NOT NULL DEFAULT false,
    "start_time" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "segment_efforts_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "kudos" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "activity_id" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kudos_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "comments" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "activity_id" INTEGER NOT NULL,
    "comment_text" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comments_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "personal_records" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "activity_id" INTEGER NOT NULL,
    "record_type" VARCHAR(50) NOT NULL,
    "value" DOUBLE PRECISION NOT NULL,
    "achieved_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "personal_records_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "users_username_key" ON "users"("username");
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
CREATE UNIQUE INDEX "follows_follower_id_following_id_key" ON "follows"("follower_id", "following_id");
CREATE INDEX "activity_waypoints_activity_id_idx" ON "activity_waypoints"("activity_id");
CREATE UNIQUE INDEX "kudos_user_id_activity_id_key" ON "kudos"("user_id", "activity_id");
CREATE UNIQUE INDEX "personal_records_user_id_record_type_key" ON "personal_records"("user_id", "record_type");

ALTER TABLE "follows" ADD CONSTRAINT "follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "follows" ADD CONSTRAINT "follows_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "activities" ADD CONSTRAINT "activities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "activity_waypoints" ADD CONSTRAINT "activity_waypoints_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "segment_efforts" ADD CONSTRAINT "segment_efforts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "segment_efforts" ADD CONSTRAINT "segment_efforts_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "segment_efforts" ADD CONSTRAINT "segment_efforts_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "segments"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "kudos" ADD CONSTRAINT "kudos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "kudos" ADD CONSTRAINT "kudos_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "comments" ADD CONSTRAINT "comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "comments" ADD CONSTRAINT "comments_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE CASCADE ON UPDATE CASCADE;
