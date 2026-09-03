# Data Model & Database Schema Specification — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Database Engine:** PostgreSQL 16 with PostGIS 3.4 Spatial Extension  
**Spatial Reference System:** WGS 84 (EPSG:4326)

---

## 1. Global Enumerations & Constraints

```sql
-- Provenance and environment data categorization
CREATE TYPE data_label AS ENUM ('LIVE', 'HISTORICAL', 'SIMULATED', 'TEST');

-- Physical accessibility operational status
CREATE TYPE accessibility_state AS ENUM ('OPEN', 'CAUTION', 'RESTRICTED', 'HIGH_RISK', 'BLOCKED', 'UNKNOWN');

-- Incident hazard categories
CREATE TYPE incident_type AS ENUM (
    'LANDSLIDE', 'MUDSLIDE', 'WATERLOGGING', 'ROAD_COLLAPSE',
    'TREE_FALL', 'HEAVY_CONGESTION', 'BRIDGE_DISTRESS', 'OTHER'
);

-- Severity rating
CREATE TYPE severity_level AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- System user roles
CREATE TYPE user_role AS ENUM ('DRIVER', 'FIELD_WORKER', 'OFFICIAL', 'ADMIN');

-- Journey operational status
CREATE TYPE journey_status AS ENUM ('PLANNED', 'ACTIVE', 'REROUTED', 'COMPLETED', 'CANCELLED');

-- Alert lifecycle status
CREATE TYPE alert_status AS ENUM ('CREATED', 'DISPATCHED', 'ACKNOWLEDGED', 'RESOLVED', 'EXPIRED');

-- Mobile synchronization state
CREATE TYPE sync_status AS ENUM ('PENDING', 'SYNCING', 'SYNCED', 'FAILED');
```

---

## 2. Core Entity Schemas (18 Tables)

### 2.1 Identity & Asset Layer

#### `users`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique user identifier |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | Login email address |
| `password_hash` | VARCHAR(255) | NOT NULL | Argon2 / bcrypt password hash |
| `full_name` | VARCHAR(128) | NOT NULL | User's legal name |
| `phone_number` | VARCHAR(32) | NULL | Contact phone for SMS alerts |
| `role` | user_role | NOT NULL, DEFAULT 'DRIVER' | RBAC role |
| `organization` | VARCHAR(128) | NULL | Transport union, logistics firm, or government agency |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record modification timestamp |

#### `vehicles`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Vehicle identifier |
| `registration_number` | VARCHAR(32) | UNIQUE, NOT NULL | License plate (e.g. AS-01-XX-0000) |
| `vehicle_class` | VARCHAR(32) | NOT NULL, DEFAULT 'FOUR_WHEELER' | Baseline category (4-wheeler, LCV, Heavy) |
| `gross_weight_tonnes` | NUMERIC(5,2) | NOT NULL | Load weight for bridge/gradient risk |
| `assigned_user_id` | UUID | REFERENCES users(id) ON DELETE SET NULL | Driver currently operating vehicle |

---

### 2.2 Geospatial Network Layer

#### `road_segments`
The central atomic unit of the TiyraSense intelligence engine.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique segment UUID |
| `segment_code` | VARCHAR(64) | UNIQUE, NOT NULL | Human-readable code (e.g. `NER-NH6-042`) |
| `corridor_name` | VARCHAR(128) | NOT NULL | Corridor identifier (e.g. `Guwahati-Shillong NH-6`) |
| `road_class` | VARCHAR(32) | NOT NULL | Highway classification (`NH`, `SH`, `MDR`, `RURAL`) |
| `start_node_id` | BIGINT | NOT NULL | Topological start vertex for routing graph |
| `end_node_id` | BIGINT | NOT NULL | Topological end vertex for routing graph |
| `geom` | geometry(LineString, 4326) | NOT NULL | PostGIS geospatial path coordinates |
| `length_meters` | NUMERIC(10,2) | NOT NULL | Physical segment distance in meters |
| `average_slope_degrees` | NUMERIC(4,2) | NOT NULL, DEFAULT 0.0 | Terrain gradient (steepness) |
| `landslide_susceptibility` | NUMERIC(3,2) | NOT NULL, DEFAULT 0.1 | Static geomorphological hazard index (0.0–1.0) |
| `current_accessibility` | accessibility_state | NOT NULL, DEFAULT 'OPEN' | Evaluated operational access state |
| `current_risk_score` | NUMERIC(4,3) | NOT NULL, DEFAULT 0.0 | Composite segment risk (0.000 to 1.000) |
| `current_speed_kmh` | NUMERIC(5,2) | NULL | Estimated transit velocity |
| `last_assessed_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Timestamp of most recent risk calculation |
| `data_label` | data_label | NOT NULL, DEFAULT 'LIVE' | Provenance classification |

*Index:* `CREATE INDEX idx_road_segments_geom ON road_segments USING GIST(geom);`

---

### 2.3 Evidence & Observation Layer

#### `field_reports`
Raw submissions received from drivers and field workers.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Report identifier |
| `reporter_id` | UUID | REFERENCES users(id) ON DELETE CASCADE | Submitting user |
| `road_segment_id` | UUID | REFERENCES road_segments(id) | Nearest associated road segment |
| `hazard_type` | incident_type | NOT NULL | Selected incident category |
| `reported_severity` | severity_level | NOT NULL | Severity rating |
| `description` | TEXT | NULL | Free-form notes or driver observations |
| `location` | geometry(Point, 4326) | NOT NULL | Device GPS coordinates at report capture |
| `client_captured_at` | TIMESTAMPTZ | NOT NULL | Device local capture timestamp (offline proof) |
| `server_received_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Ingestion server arrival timestamp |
| `verification_status` | VARCHAR(32) | NOT NULL, DEFAULT 'PENDING' | `PENDING`, `CORROBORATED`, `REJECTED`, `VERIFIED` |
| `data_label` | data_label | NOT NULL, DEFAULT 'LIVE' | Provenance classification |

#### `incident_evidence`
Media attachments supporting field reports.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Evidence record ID |
| `field_report_id` | UUID | REFERENCES field_reports(id) ON DELETE CASCADE | Associated report |
| `storage_uri` | VARCHAR(512) | NOT NULL | Protected filesystem or object storage URL |
| `file_hash_sha256` | VARCHAR(64) | NOT NULL | Tamper-evidence digest |
| `mime_type` | VARCHAR(64) | NOT NULL | Image format (`image/jpeg`, `image/png`) |
| `uploaded_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Timestamp of upload |

#### `incidents`
Synthesized, corroborated real-world events.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Incident identifier |
| `road_segment_id` | UUID | REFERENCES road_segments(id) | Impacted segment |
| `hazard_type` | incident_type | NOT NULL | Classified hazard type |
| `severity` | severity_level | NOT NULL | Arbitrated severity level |
| `accessibility_impact` | accessibility_state | NOT NULL | Induced road state (`RESTRICTED` / `BLOCKED`) |
| `confidence_score` | NUMERIC(3,2) | NOT NULL | Corroboration confidence (0.0–1.0) |
| `started_at` | TIMESTAMPTZ | NOT NULL | Estimated onset time |
| `resolved_at` | TIMESTAMPTZ | NULL | Clear/reopening timestamp |
| `verified_by_user_id` | UUID | REFERENCES users(id) | Official who confirmed event |
| `data_label` | data_label | NOT NULL, DEFAULT 'LIVE' | Provenance classification |

#### `weather_observations`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Observation identifier |
| `road_segment_id` | UUID | REFERENCES road_segments(id) | Associated segment |
| `precipitation_mm_hr` | NUMERIC(6,2) | NOT NULL | Rainfall intensity in mm/hr |
| `soil_moisture_percentage` | NUMERIC(5,2) | NULL | Volumetric root-zone moisture saturation % |
| `wind_gust_kmh` | NUMERIC(5,2) | NULL | Wind gust speed |
| `wmo_weather_code` | INTEGER | NOT NULL | WMO standard weather code |
| `observation_timestamp` | TIMESTAMPTZ | NOT NULL | Timestamp of weather measurement |
| `forecast_horizon_hours` | INTEGER | NOT NULL, DEFAULT 0 | 0 = current observation; >0 = forecast |
| `source_name` | VARCHAR(64) | NOT NULL, DEFAULT 'Open-Meteo' | Data provider identifier |
| `data_label` | data_label | NOT NULL, DEFAULT 'LIVE' | Provenance classification |

#### `traffic_observations`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Traffic telemetry ID |
| `road_segment_id` | UUID | REFERENCES road_segments(id) | Associated segment |
| `observed_speed_kmh` | NUMERIC(5,2) | NOT NULL | Monitored flow velocity |
| `free_flow_speed_kmh` | NUMERIC(5,2) | NOT NULL | Nominal design speed |
| `congestion_ratio` | NUMERIC(3,2) | NOT NULL | Observed / Free-flow speed ratio |
| `sample_count` | INTEGER | NOT NULL, DEFAULT 1 | Fleet breadcrumb sample volume |
| `observed_at` | TIMESTAMPTZ | NOT NULL | Observation timestamp |

---

### 2.4 Routing & Intelligence Layer

#### `predictions`
ML disruption forecast records.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Prediction identifier |
| `road_segment_id` | UUID | REFERENCES road_segments(id) | Target segment |
| `model_version` | VARCHAR(32) | NOT NULL | Model identifier (e.g. `xgb-disruption-v1.2`) |
| `disruption_probability` | NUMERIC(4,3) | NOT NULL | Estimated likelihood (0.000 to 1.000) |
| `target_horizon_start` | TIMESTAMPTZ | NOT NULL | Start of forecast window |
| `target_horizon_end` | TIMESTAMPTZ | NOT NULL | End of forecast window (e.g. +2 hours) |
| `top_feature_factors` | JSONB | NOT NULL | Explainability weights (rain, slope, history) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Prediction calculation timestamp |
| `data_label` | data_label | NOT NULL, DEFAULT 'LIVE' | Provenance classification |

#### `routes`
Evaluated origin-destination trajectories.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Route identifier |
| `origin_name` | VARCHAR(128) | NOT NULL | Origin label (e.g. `Guwahati Freight Terminal`) |
| `destination_name` | VARCHAR(128) | NOT NULL | Destination label (e.g. `Shillong Polo Ground`) |
| `origin_geom` | geometry(Point, 4326) | NOT NULL | Start coordinate |
| `destination_geom` | geometry(Point, 4326) | NOT NULL | End coordinate |
| `route_geom` | geometry(LineString, 4326) | NOT NULL | Complete journey polyline |
| `segment_ids` | UUID[] | NOT NULL | Ordered array of traversing `road_segment_id`s |
| `total_distance_km` | NUMERIC(8,2) | NOT NULL | Total path length |
| `estimated_duration_mins` | NUMERIC(8,2) | NOT NULL | Nominal transit duration |
| `composite_risk_score` | NUMERIC(4,3) | NOT NULL | Aggregate journey risk index (0.000–1.000) |
| `is_recommended_safest` | BOOLEAN | NOT NULL, DEFAULT FALSE | Flag indicating the safest viable selection |
| `is_fastest_available` | BOOLEAN | NOT NULL, DEFAULT FALSE | Flag indicating fastest path |
| `evaluated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Timestamp of route computation |

#### `journeys`
Active driver transit sessions.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Journey session UUID |
| `driver_id` | UUID | REFERENCES users(id) ON DELETE CASCADE | Operating driver |
| `vehicle_id` | UUID | REFERENCES vehicles(id) | Assigned vehicle |
| `active_route_id` | UUID | REFERENCES routes(id) | Currently navigating route |
| `status` | journey_status | NOT NULL, DEFAULT 'ACTIVE' | Active execution state |
| `current_location` | geometry(Point, 4326) | NULL | Last reported telemetry coordinate |
| `last_telemetry_at` | TIMESTAMPTZ | NULL | Timestamp of last received breadcrumb |
| `started_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Journey initiation time |
| `completed_at` | TIMESTAMPTZ | NULL | Arrival time |

---

### 2.5 Alerting & System Governance Layer

#### `alerts`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Alert identifier |
| `journey_id` | UUID | REFERENCES journeys(id) ON DELETE CASCADE | Targeted journey session |
| `road_segment_id` | UUID | REFERENCES road_segments(id) | Hazard segment triggering the alert |
| `severity` | severity_level | NOT NULL | Alert priority |
| `title` | VARCHAR(128) | NOT NULL | Concise headline |
| `message_en` | TEXT | NOT NULL | English advisory text |
| `message_multilingual` | JSONB | NULL | Localized texts (`as`, `bn`, `hi`) generated by LLM |
| `status` | alert_status | NOT NULL, DEFAULT 'CREATED' | Delivery state |
| `dispatched_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Dispatch timestamp |
| `acknowledged_at` | TIMESTAMPTZ | NULL | Driver tap confirmation timestamp |

#### `affected_zones`
Geographic bounding envelopes of regional disaster hazards.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Zone identifier |
| `zone_name` | VARCHAR(128) | NOT NULL | E.g. `Nongpoh Valley Flash Flood Zone` |
| `geom` | geometry(Polygon, 4326) | NOT NULL | Spatial polygon boundary |
| `declared_by_user_id` | UUID | REFERENCES users(id) | Official issuer |
| `valid_from` | TIMESTAMPTZ | NOT NULL | Start of advisory window |
| `valid_until` | TIMESTAMPTZ | NOT NULL | Expiry of advisory |

#### `sync_records`
Mobile queue reconciliation audit.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Sync transaction ID |
| `user_id` | UUID | REFERENCES users(id) | Syncing mobile client |
| `items_uploaded` | INTEGER | NOT NULL | Count of successfully processed reports |
| `items_failed` | INTEGER | NOT NULL, DEFAULT 0 | Count of schema/validation failures |
| `synced_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Completion timestamp |

#### `data_sources`
Metadata registry of upstream external information providers.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Provider UUID |
| `source_name` | VARCHAR(64) | UNIQUE, NOT NULL | Provider name (`Open-Meteo`, `OSRM-NER`, `IMD`) |
| `source_type` | VARCHAR(32) | NOT NULL | `WEATHER_API`, `ROUTING_ENGINE`, `OFFICIAL_FEED` |
| `reliability_weight` | NUMERIC(3,2) | NOT NULL, DEFAULT 0.85 | Weight used in conflict resolution (0.0–1.0) |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | System toggle |

#### `model_versions`
Machine learning deployment audit registry.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Model registry UUID |
| `model_tag` | VARCHAR(64) | UNIQUE, NOT NULL | `xgb-disruption-v1.0.0` |
| `algorithm` | VARCHAR(64) | NOT NULL | E.g. `GradientBoostingClassifier` |
| `training_date` | DATE | NOT NULL | Date weights were fitted |
| `validation_roc_auc` | NUMERIC(4,3) | NOT NULL | Validation metric score |
| `is_production` | BOOLEAN | NOT NULL, DEFAULT FALSE | Active inference toggle |

#### `audit_logs`
Immutable tamper-evident governance ledger.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGSERIAL | PRIMARY KEY | Monotonic transaction sequence ID |
| `actor_user_id` | UUID | REFERENCES users(id) | User initiating action |
| `action_name` | VARCHAR(64) | NOT NULL | E.g. `SEGMENT_STATE_OVERRIDE` |
| `entity_type` | VARCHAR(64) | NOT NULL | Target table name |
| `entity_id` | UUID | NOT NULL | Target record UUID |
| `old_state` | JSONB | NULL | Previous attribute values |
| `new_state` | JSONB | NOT NULL | New attribute values |
| `ip_address` | VARCHAR(45) | NULL | Client IP |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Event timestamp |
