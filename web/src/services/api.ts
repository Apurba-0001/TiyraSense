import { TokenResponse, User } from '../types/auth';

const API_BASE = (import.meta.env.VITE_API_URL as string | undefined)?.replace(/\/$/, '') || 'http://localhost:8000/api/v1';

export class ApiErrorResponse extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
    this.name = 'ApiErrorResponse';
  }
}

function getHeaders(includeAuth = true): HeadersInit {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };
  if (includeAuth) {
    const token = localStorage.getItem('tiyrasense_token');
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
  }
  return headers;
}

export async function loginUser(email: string, password: string): Promise<TokenResponse> {
  const res = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: getHeaders(false),
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    let errorDetail = 'Authentication failed. Please check your credentials.';
    try {
      const err = await res.json();
      if (err.detail) errorDetail = err.detail;
    } catch {
      // Fallback to generic message
    }
    throw new ApiErrorResponse(errorDetail, res.status);
  }

  return res.json();
}

export async function fetchCurrentUser(): Promise<User> {
  const res = await fetch(`${API_BASE}/auth/me`, {
    headers: getHeaders(true),
  });

  if (!res.ok) {
    throw new ApiErrorResponse('Session expired or invalid token', res.status);
  }

  return res.json();
}

export async function updateCurrentUserProfile(payload: {
  full_name?: string;
  phone_number?: string;
  organization?: string;
  current_password?: string;
  new_password?: string;
}): Promise<User> {
  const res = await fetch(`${API_BASE}/auth/me`, {
    method: 'PATCH',
    headers: getHeaders(true),
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    let errorDetail = 'Failed to update profile';
    try {
      const err = await res.json();
      errorDetail = err.detail || errorDetail;
    } catch {
      // fallback
    }
    throw new ApiErrorResponse(errorDetail, res.status);
  }

  return res.json();
}

export async function fetchHealthStatus(): Promise<{
  status: string;
  database: string;
  postgis_version: string;
  data_label: string;
}> {
  const res = await fetch(`${API_BASE}/health`, {
    headers: getHeaders(false),
  });

  if (!res.ok) {
    throw new ApiErrorResponse('Healthcheck failed', res.status);
  }

  return res.json();
}

export interface RouteOption {
  id: string;
  name: string;
  total_distance_km: number;
  estimated_duration_mins: number;
  composite_risk_score: number;
  is_recommended_safest: boolean;
  is_fastest_available: boolean;
  is_viable: boolean;
  max_hazard_state: string;
  classification?: string;
  geometry_geojson?: {
    type: string;
    coordinates: [number, number][];
  };
  segments_summary?: {
    total_segments: number;
    open_count: number;
    caution_count: number;
    restricted_count: number;
    blocked_count: number;
  };
}

export interface RouteEvaluationResponse {
  evaluated_at: string;
  data_label: string;
  recommended_route_id: string;
  routes: RouteOption[];
  candidate_routes?: RouteOption[];
}

export interface CorridorSummary {
  id: string;
  name: string;
  route_id: string;
  status: string;
  risk_score: number;
  disruption_prob: number;
  last_report: string;
  segment_count: number;
}

export interface JourneyTracking {
  journey_id: string;
  status: string;
  current_location?: {
    latitude: number;
    longitude: number;
    label?: string;
  };
  speed_kmh: number;
  last_telemetry_at?: string;
  distance_covered_km: number;
  remaining_distance_km: number;
  estimated_time_remaining_mins: number;
  upcoming_hazards: Array<{
    segment_code: string;
    corridor_name: string;
    hazard_state: string;
    risk_score: number;
    distance_ahead_km: number;
  }>;
}

export interface ActiveJourney {
  journey_id: string;
  vehicle_name?: string;
  vehicle_number?: string;
  callsign?: string;
  driver_name: string;
  driver_phone?: string;
  route_name: string;
  current_location?: {
    latitude: number;
    longitude: number;
  };
  speed_kmh?: number;
  heading_degrees?: number;
  origin_name?: string;
  destination_name?: string;
  origin_coords?: {
    latitude: number;
    longitude: number;
  };
  destination_coords?: {
    latitude: number;
    longitude: number;
  };
  route_geometry?: [number, number][];
  status: string;
  last_ping_mins_ago: number;
}

export async function evaluateRoutes(
  origin: { latitude: number; longitude: number; label?: string },
  destination: { latitude: number; longitude: number; label?: string },
  vehicleClass = 'FOUR_WHEELER',
  preferSafety = true
): Promise<RouteEvaluationResponse> {
  const res = await fetch(`${API_BASE}/routes/evaluate`, {
    method: 'POST',
    headers: getHeaders(false),
    body: JSON.stringify({
      origin,
      destination,
      vehicle_class: vehicleClass,
      prefer_safety: preferSafety,
    }),
  });

  if (!res.ok) {
    throw new ApiErrorResponse('Failed to evaluate routes', res.status);
  }
  return res.json();
}

export async function fetchCorridors(): Promise<CorridorSummary[]> {
  const res = await fetch(`${API_BASE}/routes/corridors`, {
    headers: getHeaders(false),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to fetch corridors', res.status);
  }
  return res.json();
}

export async function startJourney(routeId: string): Promise<{ id: string; status: string }> {
  const res = await fetch(`${API_BASE}/journeys`, {
    method: 'POST',
    headers: getHeaders(true),
    body: JSON.stringify({ route_id: routeId }),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to start journey', res.status);
  }
  return res.json();
}

export async function sendTelemetry(
  journeyId: string,
  latitude: number,
  longitude: number,
  speedKmh = 45.0,
  headingDegrees = 0.0
): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/journeys/${journeyId}/telemetry`, {
    method: 'POST',
    headers: getHeaders(false),
    body: JSON.stringify({
      latitude,
      longitude,
      speed_kmh: speedKmh,
      heading_degrees: headingDegrees,
    }),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to send telemetry', res.status);
  }
  return res.json();
}

export async function fetchJourneyTracking(journeyId: string): Promise<JourneyTracking> {
  const res = await fetch(`${API_BASE}/journeys/${journeyId}/tracking`, {
    headers: getHeaders(false),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to fetch journey tracking', res.status);
  }
  return res.json();
}

export async function fetchActiveJourneys(): Promise<ActiveJourney[]> {
  const res = await fetch(`${API_BASE}/journeys/active`, {
    headers: getHeaders(false),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to fetch active journeys', res.status);
  }
  return res.json();
}

export interface PlaceResult {
  name: string;
  latitude: number;
  longitude: number;
  state?: string;
  place_type?: string;
}

export async function searchPlaces(query: string): Promise<PlaceResult[]> {
  try {
    const res = await fetch(`${API_BASE}/routes/places/search?q=${encodeURIComponent(query)}`, {
      headers: getHeaders(false),
    });
    if (!res.ok) return [];
    return await res.json();
  } catch {
    return [];
  }
}

export interface WebFieldReport {
  id: string;
  hazard_type: string;
  severity: string;
  status: 'PENDING' | 'VERIFIED' | 'DISPATCHED' | 'REJECTED';
  description: string;
  latitude: number;
  longitude: number;
  corridor_name?: string;
  km_marker?: string;
  reporter_name?: string;
  reporter_unit?: string;
  submitted_at: string;
  data_label?: string;
  dispatch_unit?: string;
  dispatch_notes?: string;
  photo_url?: string;
}

export async function fetchFieldReports(): Promise<WebFieldReport[]> {
  const res = await fetch(`${API_BASE}/reports`, {
    headers: getHeaders(false),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to fetch field reports', res.status);
  }
  return res.json();
}

export async function createFieldReport(report: {
  hazard_type: string;
  severity: string;
  description: string;
  latitude: number;
  longitude: number;
  corridor_name?: string;
  km_marker?: string;
  photo_url?: string;
}): Promise<WebFieldReport> {
  const res = await fetch(`${API_BASE}/reports`, {
    method: 'POST',
    headers: getHeaders(true),
    body: JSON.stringify(report),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to create field report', res.status);
  }
  return res.json();
}

export async function uploadEvidencePhoto(file: File): Promise<{ url: string; secure_url: string; filename: string }> {
  const formData = new FormData();
  formData.append('file', file);
  const res = await fetch(`${API_BASE}/evidence/upload`, {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to upload evidence photo', res.status);
  }
  return res.json();
}

export async function verifyFieldReport(
  reportId: string,
  action: {
    status: string;
    dispatch_unit?: string;
    dispatch_notes?: string;
  }
): Promise<WebFieldReport> {
  const res = await fetch(`${API_BASE}/reports/${reportId}/verify`, {
    method: 'PATCH',
    headers: getHeaders(true),
    body: JSON.stringify(action),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to verify field report', res.status);
  }
  return res.json();
}

export interface WebAlert {
  id: string;
  severity: 'EMERGENCY' | 'CAUTION' | 'INFO';
  corridor: string;
  title: string;
  description: string;
  time: string;
  dispatched_at: string;
  acknowledged: boolean;
  acknowledged_at?: string;
  data_label?: string;
}

export async function fetchAlerts(): Promise<WebAlert[]> {
  const res = await fetch(`${API_BASE}/alerts`, {
    headers: getHeaders(false),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to fetch alerts', res.status);
  }
  return res.json();
}

export async function createAlert(alert: {
  corridor: string;
  severity: string;
  title: string;
  description: string;
}): Promise<WebAlert> {
  const res = await fetch(`${API_BASE}/alerts`, {
    method: 'POST',
    headers: getHeaders(true),
    body: JSON.stringify(alert),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to create alert', res.status);
  }
  return res.json();
}

export async function acknowledgeAlert(alertId: string): Promise<WebAlert> {
  const res = await fetch(`${API_BASE}/alerts/${alertId}/acknowledge`, {
    method: 'PATCH',
    headers: getHeaders(true),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to acknowledge alert', res.status);
  }
  return res.json();
}

export async function acknowledgeAllAlerts(): Promise<WebAlert[]> {
  const res = await fetch(`${API_BASE}/alerts/acknowledge-all`, {
    method: 'POST',
    headers: getHeaders(true),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to acknowledge all alerts', res.status);
  }
  return res.json();
}

export async function deleteFieldReport(reportId: string): Promise<{ success: boolean; report_id: string }> {
  const res = await fetch(`${API_BASE}/reports/${reportId}`, {
    method: 'DELETE',
    headers: getHeaders(true),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to delete field report', res.status);
  }
  return res.json();
}

export interface WebEvidenceStats {
  total_images: number;
  total_bytes: number;
  total_size_formatted: string;
  avg_image_size_kb: number;
  format_distribution: Record<string, number>;
  recent_images: Array<{
    id: string;
    cloudinary_public_id: string;
    secure_url: string;
    bytes?: number;
    format?: string;
    created_at: string;
  }>;
}

export async function fetchEvidenceStats(): Promise<WebEvidenceStats> {
  const res = await fetch(`${API_BASE}/evidence/admin/stats`, {
    headers: getHeaders(true),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to fetch evidence storage statistics', res.status);
  }
  return res.json();
}

export async function deleteEvidencePhoto(evidenceId: string): Promise<{ success: boolean; evidence_id: string; cloudinary_destroyed: boolean }> {
  const res = await fetch(`${API_BASE}/evidence/${evidenceId}`, {
    method: 'DELETE',
    headers: getHeaders(true),
  });
  if (!res.ok) {
    throw new ApiErrorResponse('Failed to delete evidence photo', res.status);
  }
  return res.json();
}

export interface RegionalWeatherObservation {
  hub: string;
  corridor: string;
  latitude: number;
  longitude: number;
  temperature_c: number;
  relative_humidity_pct: number;
  precipitation_mm: number;
  wind_speed_kmh: number;
  weather_code: number;
  condition: string;
  weather_penalty_factor: number;
  observed_at: string;
  provider: string;
  data_label: string;
}

export async function fetchRegionalWeather(): Promise<RegionalWeatherObservation[]> {
  try {
    const res = await fetch(`${API_BASE}/external/weather`, {
      headers: getHeaders(false),
    });
    if (!res.ok) {
      return [];
    }
    return await res.json();
  } catch {
    return [];
  }
}

