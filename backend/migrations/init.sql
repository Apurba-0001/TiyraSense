-- ============================================================
-- TiyraSense — PostGIS & Database Initialization Script
-- Authoritative Schema: docs/data_model.md
-- ============================================================

-- 1. Enable Required PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Enumerations
DO $$ BEGIN
    CREATE TYPE data_label AS ENUM ('LIVE', 'HISTORICAL', 'SIMULATED', 'TEST');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE accessibility_state AS ENUM ('OPEN', 'CAUTION', 'RESTRICTED', 'HIGH_RISK', 'BLOCKED', 'UNKNOWN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE incident_type AS ENUM (
        'LANDSLIDE', 'MUDSLIDE', 'WATERLOGGING', 'ROAD_COLLAPSE',
        'TREE_FALL', 'HEAVY_CONGESTION', 'BRIDGE_DISTRESS', 'OTHER'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE severity_level AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('DRIVER', 'FIELD_WORKER', 'OFFICIAL', 'ADMIN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE journey_status AS ENUM ('PLANNED', 'ACTIVE', 'REROUTED', 'COMPLETED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE alert_status AS ENUM ('CREATED', 'DISPATCHED', 'ACKNOWLEDGED', 'RESOLVED', 'EXPIRED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE sync_status AS ENUM ('PENDING', 'SYNCING', 'SYNCED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 3. Core Tables

-- Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(128) NOT NULL,
    phone_number VARCHAR(32),
    role user_role NOT NULL DEFAULT 'DRIVER',
    organization VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_number VARCHAR(32) UNIQUE NOT NULL,
    vehicle_class VARCHAR(32) NOT NULL DEFAULT 'FOUR_WHEELER',
    gross_weight_tonnes NUMERIC(5,2) NOT NULL,
    assigned_user_id UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Road Segments
CREATE TABLE IF NOT EXISTS road_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    segment_code VARCHAR(64) UNIQUE NOT NULL,
    corridor_name VARCHAR(128) NOT NULL,
    road_class VARCHAR(32) NOT NULL,
    start_node_id BIGINT NOT NULL,
    end_node_id BIGINT NOT NULL,
    geom geometry(LineString, 4326) NOT NULL,
    length_meters NUMERIC(10,2) NOT NULL,
    average_slope_degrees NUMERIC(4,2) NOT NULL DEFAULT 0.0,
    landslide_susceptibility NUMERIC(3,2) NOT NULL DEFAULT 0.1,
    current_accessibility accessibility_state NOT NULL DEFAULT 'OPEN',
    current_risk_score NUMERIC(4,3) NOT NULL DEFAULT 0.0,
    current_speed_kmh NUMERIC(5,2),
    last_assessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_label data_label NOT NULL DEFAULT 'LIVE'
);
CREATE INDEX IF NOT EXISTS idx_road_segments_geom ON road_segments USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_road_segments_code ON road_segments(segment_code);

-- Field Reports
CREATE TABLE IF NOT EXISTS field_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    road_segment_id UUID REFERENCES road_segments(id),
    hazard_type incident_type NOT NULL,
    reported_severity severity_level NOT NULL,
    description TEXT,
    location geometry(Point, 4326) NOT NULL,
    client_captured_at TIMESTAMPTZ NOT NULL,
    server_received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verification_status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    data_label data_label NOT NULL DEFAULT 'LIVE'
);
CREATE INDEX IF NOT EXISTS idx_field_reports_loc ON field_reports USING GIST(location);

-- Incident Evidence
CREATE TABLE IF NOT EXISTS incident_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_report_id UUID REFERENCES field_reports(id) ON DELETE CASCADE,
    storage_uri VARCHAR(512) NOT NULL,
    file_hash_sha256 VARCHAR(64) NOT NULL,
    mime_type VARCHAR(64) NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Incidents
CREATE TABLE IF NOT EXISTS incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_segment_id UUID REFERENCES road_segments(id),
    hazard_type incident_type NOT NULL,
    severity severity_level NOT NULL,
    accessibility_impact accessibility_state NOT NULL,
    confidence_score NUMERIC(3,2) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    resolved_at TIMESTAMPTZ,
    verified_by_user_id UUID REFERENCES users(id),
    data_label data_label NOT NULL DEFAULT 'LIVE'
);

-- Weather Observations
CREATE TABLE IF NOT EXISTS weather_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_segment_id UUID REFERENCES road_segments(id),
    precipitation_mm_hr NUMERIC(6,2) NOT NULL,
    soil_moisture_percentage NUMERIC(5,2),
    wind_gust_kmh NUMERIC(5,2),
    wmo_weather_code INTEGER NOT NULL,
    observation_timestamp TIMESTAMPTZ NOT NULL,
    forecast_horizon_hours INTEGER NOT NULL DEFAULT 0,
    source_name VARCHAR(64) NOT NULL DEFAULT 'Open-Meteo',
    data_label data_label NOT NULL DEFAULT 'LIVE'
);
CREATE INDEX IF NOT EXISTS idx_weather_segment_time ON weather_observations(road_segment_id, observation_timestamp);

-- Traffic Observations
CREATE TABLE IF NOT EXISTS traffic_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_segment_id UUID REFERENCES road_segments(id),
    observed_speed_kmh NUMERIC(5,2) NOT NULL,
    free_flow_speed_kmh NUMERIC(5,2) NOT NULL,
    congestion_ratio NUMERIC(3,2) NOT NULL,
    sample_count INTEGER NOT NULL DEFAULT 1,
    observed_at TIMESTAMPTZ NOT NULL
);

-- Predictions
CREATE TABLE IF NOT EXISTS predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    road_segment_id UUID REFERENCES road_segments(id),
    model_version VARCHAR(32) NOT NULL,
    disruption_probability NUMERIC(4,3) NOT NULL,
    target_horizon_start TIMESTAMPTZ NOT NULL,
    target_horizon_end TIMESTAMPTZ NOT NULL,
    top_feature_factors JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_label data_label NOT NULL DEFAULT 'LIVE'
);

-- Routes
CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    origin_name VARCHAR(128) NOT NULL,
    destination_name VARCHAR(128) NOT NULL,
    origin_geom geometry(Point, 4326) NOT NULL,
    destination_geom geometry(Point, 4326) NOT NULL,
    route_geom geometry(LineString, 4326) NOT NULL,
    segment_ids UUID[] NOT NULL,
    total_distance_km NUMERIC(8,2) NOT NULL,
    estimated_duration_mins NUMERIC(8,2) NOT NULL,
    composite_risk_score NUMERIC(4,3) NOT NULL,
    is_recommended_safest BOOLEAN NOT NULL DEFAULT FALSE,
    is_fastest_available BOOLEAN NOT NULL DEFAULT FALSE,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Journeys
CREATE TABLE IF NOT EXISTS journeys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id),
    active_route_id UUID REFERENCES routes(id),
    status journey_status NOT NULL DEFAULT 'ACTIVE',
    current_location geometry(Point, 4326),
    last_telemetry_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Alerts
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journey_id UUID REFERENCES journeys(id) ON DELETE CASCADE,
    road_segment_id UUID REFERENCES road_segments(id),
    severity severity_level NOT NULL,
    title VARCHAR(128) NOT NULL,
    message_en TEXT NOT NULL,
    message_multilingual JSONB,
    status alert_status NOT NULL DEFAULT 'CREATED',
    dispatched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ
);

-- Affected Zones
CREATE TABLE IF NOT EXISTS affected_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_name VARCHAR(128) NOT NULL,
    geom geometry(Polygon, 4326) NOT NULL,
    declared_by_user_id UUID REFERENCES users(id),
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL
);

-- Sync Records
CREATE TABLE IF NOT EXISTS sync_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    items_uploaded INTEGER NOT NULL,
    items_failed INTEGER NOT NULL DEFAULT 0,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Data Sources
CREATE TABLE IF NOT EXISTS data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name VARCHAR(64) UNIQUE NOT NULL,
    source_type VARCHAR(32) NOT NULL,
    reliability_weight NUMERIC(3,2) NOT NULL DEFAULT 0.85,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Model Versions
CREATE TABLE IF NOT EXISTS model_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_tag VARCHAR(64) UNIQUE NOT NULL,
    algorithm VARCHAR(64) NOT NULL,
    training_date DATE NOT NULL,
    validation_roc_auc NUMERIC(4,3) NOT NULL,
    is_production BOOLEAN NOT NULL DEFAULT FALSE
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    actor_user_id UUID REFERENCES users(id),
    action_name VARCHAR(64) NOT NULL,
    entity_type VARCHAR(64) NOT NULL,
    entity_id UUID NOT NULL,
    old_state JSONB,
    new_state JSONB NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
