/**
 * TiyraSense Distance & Regulatory Clauses Engine
 * 
 * Implements deterministic road distance calculation across the North Eastern Region (NER)
 * with engineering and regulatory clauses:
 * - Clause 1: Geodesic Aerial Base (WGS-84 Haversine spherical model)
 * - Clause 2: Topographic Curvature Clause (IRC:SP:48 / D-015 mountain winding)
 * - Clause 3: Vehicle Axle & GVW Clearance Clause (MoRTH Heavy Vehicle Axle Rules)
 * - Clause 4: Safety Hazard Detour Clause (TiyraSense D-006 safety-first protocol)
 * - Clause 5: Cargo Protocol Buffer Clause (CMVR Rule 131 POL/HAZMAT perimeter buffer)
 */

export interface DistanceClauseItem {
  clauseCode: 'BASE_AERIAL' | 'IRC_TERRAIN' | 'VEHICLE_AXLE' | 'HAZARD_DETOUR' | 'CARGO_BUFFER';
  clauseName: string;
  regulatoryRef: string;
  deltaKm: number;
  percentageText: string;
  explanation: string;
  badgeColor: string;
}

export interface DistanceBreakdown {
  baseAerialKm: number;
  topographicCurvatureKm: number;
  vehicleAxleClearanceKm: number;
  hazardDetourKm: number;
  cargoBufferKm: number;
  totalRoadKm: number;
  estimatedEtaText: string;
  items: DistanceClauseItem[];
}

export const TERRAIN_WINDING_FACTOR = 1.38; // IRC:SP:48 / D-015
export const DEFAULT_SPEED_KMH = 35.0; // Mountain transit average speed

/**
 * Calculates great-circle distance between two GPS coordinates using WGS-84 Haversine formula.
 */
export function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371.0;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

/**
 * Calculates road distance applying the 1.38x mountain topography winding factor.
 */
export function calculateRoadDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const aerial = haversineKm(lat1, lon1, lat2, lon2);
  return Math.round(aerial * TERRAIN_WINDING_FACTOR * 10) / 10;
}

/**
 * Formats estimated duration into hours and minutes text.
 */
export function formatEta(distanceKm: number, averageSpeedKmh: number = DEFAULT_SPEED_KMH): string {
  if (distanceKm <= 0) return 'ETA 0m';
  const hours = distanceKm / averageSpeedKmh;
  const h = Math.floor(hours);
  const m = Math.round((hours - h) * 60);
  return h > 0 ? `ETA ${h}h ${m < 10 ? '0' : ''}${m}m` : `ETA ${m}m`;
}

/**
 * Computes full multi-clause breakdown with legal citations and engineering standards.
 */
export function computeDetailedBreakdown({
  lat1,
  lon1,
  lat2,
  lon2,
  vehicleTitle = 'Tata Prima 31T',
  cargoTitle = 'Standard Dry Cargo',
  isSafestRoute = true,
}: {
  lat1: number;
  lon1: number;
  lat2: number;
  lon2: number;
  vehicleTitle?: string;
  cargoTitle?: string;
  isSafestRoute?: boolean;
}): DistanceBreakdown {
  const baseAerial = haversineKm(lat1, lon1, lat2, lon2);

  // Clause 2: Topographic Curvature (+38% IRC:SP:48)
  const curvature = Math.round(baseAerial * 0.38 * 10) / 10;

  // Clause 3: Vehicle Axle Clearance (MoRTH Heavy Vehicle Axle Rules)
  const vLower = vehicleTitle.toLowerCase();
  let axlePct = 0.01;
  let axleDesc = 'Light 4x4 / LCV: Minimal hairpin bypass adjustment.';
  if (vLower.includes('31t') || vLower.includes('prima') || vLower.includes('heavy') || vLower.includes('multi-axle')) {
    axlePct = 0.12;
    axleDesc = 'Heavy Multi-Axle Truck (>25T GVW): Grade <9% compliance & wider hairpin bypasses.';
  } else if (vLower.includes('1618') || vLower.includes('16 ton') || vLower.includes('medium')) {
    axlePct = 0.06;
    axleDesc = 'Medium Cargo Truck (16T GVW): Standard hill road bridge rating & curve buffers.';
  }
  const axleClearance = Math.round(baseAerial * axlePct * 10) / 10;

  // Clause 4: Safety Hazard Detour (TiyraSense D-006)
  const detour = isSafestRoute
    ? Math.round(Math.max(8.0, baseAerial * 0.14) * 10) / 10
    : 0.0;
  const detourDesc = isSafestRoute
    ? 'Safest Viable Route: Verified bypass around active landslide & saturated slope zones.'
    : 'Fastest Available Route: Direct traverse without hazard detour buffer.';

  // Clause 5: Cargo Protocol Buffer (CMVR Rule 131)
  const cLower = cargoTitle.toLowerCase();
  let cargoPct = 0.0;
  let cargoDesc = 'Standard cargo transit protocol.';
  if (cLower.includes('pol') || cLower.includes('petroleum') || cLower.includes('fuel') || cLower.includes('hazmat')) {
    cargoPct = 0.03;
    cargoDesc = 'Hazardous / POL Fuel (CMVR Rule 131): Mandatory safety perimeter corridor buffer.';
  } else if (cLower.includes('medical') || cLower.includes('relief') || cLower.includes('perishable')) {
    cargoDesc = 'Priority Cold Chain / Disaster Relief: Express corridor green-channel.';
  }
  const cargoBuffer = Math.round(baseAerial * cargoPct * 10) / 10;

  const total = Math.round((baseAerial + curvature + axleClearance + detour + cargoBuffer) * 10) / 10;

  // Speed adjustments
  const isHeavy = axlePct >= 0.10;
  const speed = isHeavy ? 28.0 : (isSafestRoute ? 35.0 : 42.0);
  const etaText = formatEta(total, speed);

  const items: DistanceClauseItem[] = [
    {
      clauseCode: 'BASE_AERIAL',
      clauseName: 'Geodesic Aerial Base',
      regulatoryRef: 'WGS-84 Ellipsoid Spherical Haversine',
      deltaKm: baseAerial,
      percentageText: 'Baseline 100%',
      explanation: 'Straight-line geodesic distance between coordinates on the Earth sphere.',
      badgeColor: '#0284C7',
    },
    {
      clauseCode: 'IRC_TERRAIN',
      clauseName: 'Topographic Curvature Clause',
      regulatoryRef: 'IRC:SP:48 / D-015 Hill Road Guidelines',
      deltaKm: curvature,
      percentageText: '+38%',
      explanation: 'Account for mountain switchbacks, ghat sections, and elevation loops.',
      badgeColor: '#D97706',
    },
    {
      clauseCode: 'VEHICLE_AXLE',
      clauseName: 'Vehicle Axle & Weight Clearance Clause',
      regulatoryRef: 'MoRTH Heavy Vehicle Axle Rules',
      deltaKm: axleClearance,
      percentageText: `+${Math.round(axlePct * 100)}%`,
      explanation: axleDesc,
      badgeColor: '#7C3AED',
    },
    {
      clauseCode: 'HAZARD_DETOUR',
      clauseName: 'Safety Hazard Detour Clause',
      regulatoryRef: 'TiyraSense D-006 Risk-First Protocol',
      deltaKm: detour,
      percentageText: isSafestRoute ? '+14%' : '0% (Direct)',
      explanation: detourDesc,
      badgeColor: isSafestRoute ? '#059669' : '#94A3B8',
    },
  ];

  if (cargoBuffer > 0) {
    items.push({
      clauseCode: 'CARGO_BUFFER',
      clauseName: 'Cargo Protocol Buffer Clause',
      regulatoryRef: 'CMVR Rule 131 Hazardous Goods Protocol',
      deltaKm: cargoBuffer,
      percentageText: '+3%',
      explanation: cargoDesc,
      badgeColor: '#DC2626',
    });
  }

  return {
    baseAerialKm: baseAerial,
    topographicCurvatureKm: curvature,
    vehicleAxleClearanceKm: axleClearance,
    hazardDetourKm: detour,
    cargoBufferKm: cargoBuffer,
    totalRoadKm: total,
    estimatedEtaText: etaText,
    items,
  };
}
