import React, { useState, useEffect } from 'react';
import {
  X,
  Navigation,
  ArrowUpDown,
  Truck,
  Package,
  ShieldCheck,
  Clock,
  MapPin,
  CheckCircle2,
  ChevronDown,
  Crosshair,
  Scale,
} from 'lucide-react';
import { evaluateRoutes, startJourney, searchPlaces, RouteOption, PlaceResult } from '../services/api';
import { computeDetailedBreakdown, DistanceBreakdown } from '../utils/distanceUtils';
import { DistanceClausesModal } from './DistanceClausesModal';


export interface JourneyPlanningModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialOrigin?: string;
  initialDestination?: string;
}

const HUB_COORDINATES: Record<string, { lat: number; lng: number }> = {
  guwahati: { lat: 26.1445, lng: 91.7362 },
  shillong: { lat: 25.5788, lng: 91.8933 },
  silchar: { lat: 24.8333, lng: 92.7926 },
  agartala: { lat: 23.8315, lng: 91.2868 },
  jorhat: { lat: 26.7500, lng: 94.2167 },
  dibrugarh: { lat: 27.4728, lng: 94.9120 },
  dimapur: { lat: 25.9060, lng: 93.7270 },
  imphal: { lat: 24.8170, lng: 93.9368 },
  aizawl: { lat: 23.7271, lng: 92.7176 },
  kohima: { lat: 25.6751, lng: 94.1086 },
  tezpur: { lat: 26.6528, lng: 92.7926 },
  tura: { lat: 25.5140, lng: 90.2200 },
};

function parseOrLookupCoords(input: string, fallbackLat: number, fallbackLng: number): { latitude: number; longitude: number; label: string } {
  const match = input.match(/(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)/);
  if (match) {
    return { latitude: parseFloat(match[1]), longitude: parseFloat(match[2]), label: input };
  }
  const lower = input.toLowerCase();
  for (const [key, coords] of Object.entries(HUB_COORDINATES)) {
    if (lower.includes(key)) {
      return { latitude: coords.lat, longitude: coords.lng, label: input };
    }
  }
  return { latitude: fallbackLat, longitude: fallbackLng, label: input };
}

function calculateDistanceClauses(
  orig: { latitude: number; longitude: number },
  dest: { latitude: number; longitude: number },
  isSafest: boolean,
  vehicleName: string,
  cargoName: string = 'Standard Dry Cargo'
) {
  const breakdown = computeDetailedBreakdown({
    lat1: orig.latitude,
    lon1: orig.longitude,
    lat2: dest.latitude,
    lon2: dest.longitude,
    vehicleTitle: vehicleName,
    cargoTitle: cargoName,
    isSafestRoute: isSafest,
  });

  return {
    aerial: breakdown.baseAerialKm,
    curvature: breakdown.topographicCurvatureKm,
    axle: breakdown.vehicleAxleClearanceKm,
    detour: breakdown.hazardDetourKm,
    cargo: breakdown.cargoBufferKm,
    total: breakdown.totalRoadKm,
    etaText: breakdown.estimatedEtaText,
    breakdown,
  };
}




const VEHICLE_PROFILES = [
  {
    id: 'tata-prima',
    name: 'Tata Prima 31T',
    category: 'Heavy Multi-Axle (31 Ton GVW)',
    clearance: '3.8m Height · 12.2m Length',
    notes: 'Requires grade < 9%, high bridge rating',
  },
  {
    id: 'ashok-leyland',
    name: 'Ashok Leyland 1618',
    category: 'Medium Cargo Truck (16 Ton GVW)',
    clearance: '3.4m Height · 9.1m Length',
    notes: 'Standard hill road clearance clearance',
  },
  {
    id: 'bolero-maxi',
    name: 'Mahindra Bolero Maxi',
    category: '4x4 Light Logistics (2.5 Ton GVW)',
    clearance: '2.1m Height · 4.9m Length',
    notes: 'All-weather 4WD; narrow hairpin capable',
  },
  {
    id: 'tata-407',
    name: 'Tata 407 LCV',
    category: 'Urban / Hill Freight (4.5 Ton GVW)',
    clearance: '2.8m Height · 5.8m Length',
    notes: 'Maneuverable in landslide single-lane detours',
  },
  {
    id: 'emergency-4wd',
    name: 'Emergency 4WD Response',
    category: 'Essential Relief & Evacuation',
    clearance: '2.2m Height · High Ground Clearance',
    notes: 'Max priority convoy with winch & recovery pack',
  },
];

const CARGO_TYPES = [
  {
    id: 'fmcg',
    name: 'FMCG Critical',
    category: 'Essential Food & Dry Rations',
    threshold: 'Standard Risk Tolerance (<= 45)',
  },
  {
    id: 'medical',
    name: 'Medical & Disaster Relief',
    category: 'Life Safety Critical Supplies',
    threshold: 'Zero Disruption Tolerance (<= 20)',
  },
  {
    id: 'pol',
    name: 'Petroleum & POL',
    category: 'Hazardous / Flammable Liquids',
    threshold: 'No High Slope / Debris Corridors (<= 30)',
  },
  {
    id: 'agri',
    name: 'Agricultural Perishables',
    category: 'Time-Sensitive Cold Chain',
    threshold: 'Prioritize Minimum Transit Time (<= 40)',
  },
  {
    id: 'heavy',
    name: 'Heavy Construction',
    category: 'Excavator Spares & Culvert Pipes',
    threshold: 'Requires Reinforced Bridge Infrastructure',
  },
];

export const JourneyPlanningModal: React.FC<JourneyPlanningModalProps> = ({
  isOpen,
  onClose,
  initialOrigin = 'Guwahati Port Hub',
  initialDestination = 'Shillong Terminal Hub',
}) => {
  const [origin, setOrigin] = useState(initialOrigin);
  const [destination, setDestination] = useState(initialDestination);
  const [vehicle, setVehicle] = useState(VEHICLE_PROFILES[0].name);
  const [cargo, setCargo] = useState(CARGO_TYPES[0].name);
  const [selectedRoute, setSelectedRoute] = useState<string>('safest');
  
  const [showOriginPicker, setShowOriginPicker] = useState(false);
  const [showDestPicker, setShowDestPicker] = useState(false);
  const [originSuggestions, setOriginSuggestions] = useState<PlaceResult[]>([]);
  const [destSuggestions, setDestSuggestions] = useState<PlaceResult[]>([]);
  
  const [originCoords, setOriginCoords] = useState<{ latitude: number; longitude: number; label: string }>(() =>
    parseOrLookupCoords(initialOrigin, 26.1445, 91.7362)
  );
  const [destCoords, setDestCoords] = useState<{ latitude: number; longitude: number; label: string }>(() =>
    parseOrLookupCoords(initialDestination, 25.5788, 91.8933)
  );

  const [confirmedMessage, setConfirmedMessage] = useState<string | null>(null);
  const [liveRoutes, setLiveRoutes] = useState<RouteOption[]>([]);
  const [isCalculating, setIsCalculating] = useState(false);
  const [gpsOriginLoading, setGpsOriginLoading] = useState(false);
  const [gpsDestLoading, setGpsDestLoading] = useState(false);
  const [auditModalOpen, setAuditModalOpen] = useState(false);
  const [activeAuditBreakdown, setActiveAuditBreakdown] = useState<DistanceBreakdown | null>(null);
  const [activeAuditRouteName, setActiveAuditRouteName] = useState('');

  // Search places for origin
  useEffect(() => {
    const timer = setTimeout(async () => {
      if (showOriginPicker || origin.length > 1) {
        const places = await searchPlaces(origin);
        setOriginSuggestions(places);
      }
    }, 200);
    return () => clearTimeout(timer);
  }, [origin, showOriginPicker]);

  // Search places for destination
  useEffect(() => {
    const timer = setTimeout(async () => {
      if (showDestPicker || destination.length > 1) {
        const places = await searchPlaces(destination);
        setDestSuggestions(places);
      }
    }, 200);
    return () => clearTimeout(timer);
  }, [destination, showDestPicker]);

  const calculateLiveRoutes = async (
    orig = originCoords,
    dest = destCoords
  ) => {
    setIsCalculating(true);
    try {
      const data = await evaluateRoutes(orig, dest);
      if (data.routes && data.routes.length > 0) {
        setLiveRoutes(data.routes);
        const safestRoute = data.routes.find((r) => r.is_recommended_safest) || data.routes[0];
        setSelectedRoute(safestRoute.id);
      }
    } catch {
      // Retain fallback demonstration
    } finally {
      setIsCalculating(false);
    }
  };

  useEffect(() => {
    if (isOpen) {
      calculateLiveRoutes(originCoords, destCoords);
    }
  }, [isOpen]);

  const handleUseGpsForOrigin = () => {
    if (typeof navigator === 'undefined' || !navigator.geolocation) return;
    setGpsOriginLoading(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = parseFloat(pos.coords.latitude.toFixed(4));
        const lng = parseFloat(pos.coords.longitude.toFixed(4));
        const label = `My GPS Location (${lat}, ${lng})`;
        const newCoords = { latitude: lat, longitude: lng, label };
        setOrigin(label);
        setOriginCoords(newCoords);
        setGpsOriginLoading(false);
        calculateLiveRoutes(newCoords, destCoords);
      },
      () => setGpsOriginLoading(false),
      { timeout: 5000 }
    );
  };

  const handleUseGpsForDest = () => {
    if (typeof navigator === 'undefined' || !navigator.geolocation) return;
    setGpsDestLoading(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = parseFloat(pos.coords.latitude.toFixed(4));
        const lng = parseFloat(pos.coords.longitude.toFixed(4));
        const label = `My GPS Location (${lat}, ${lng})`;
        const newCoords = { latitude: lat, longitude: lng, label };
        setDestination(label);
        setDestCoords(newCoords);
        setGpsDestLoading(false);
        calculateLiveRoutes(originCoords, newCoords);
      },
      () => setGpsDestLoading(false),
      { timeout: 5000 }
    );
  };

  if (!isOpen) return null;

  const handleSwap = () => {
    const tempOrigin = origin;
    const tempCoords = originCoords;
    setOrigin(destination);
    setOriginCoords(destCoords);
    setDestination(tempOrigin);
    setDestCoords(tempCoords);
    calculateLiveRoutes(destCoords, tempCoords);
  };

  const handleConfirm = () => {
    const chosenRoute = selectedRoute === 'safest'
      ? (liveRoutes.find((r) => r.is_recommended_safest) || liveRoutes[0])
      : (liveRoutes.find((r) => r.is_fastest_available) || liveRoutes[1] || liveRoutes[0]);

    if (chosenRoute?.id) {
      startJourney(chosenRoute.id).catch(() => {});
    }

    const routeName = selectedRoute === 'safest' ? 'Route A · NH-06 via Nongpoh (Safest)' : 'Route B · Direct Hill Bypass (Faster)';
    setConfirmedMessage(`Confirmed ${routeName} for ${vehicle} transporting ${cargo}. Dispatching navigation vectors to driver console...`);
    setTimeout(() => {
      setConfirmedMessage(null);
      onClose();
    }, 1800);
  };



  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.45)',
        backdropFilter: 'blur(6px)',
        WebkitBackdropFilter: 'blur(6px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 100,
        padding: '16px',
      }}
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '100%',
          maxWidth: '680px',
          backgroundColor: '#FFFFFF',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--modal-shadow)',
          border: '1px solid var(--color-border)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          maxHeight: '90vh',
        }}
      >
        {/* HEADER */}
        <div
          style={{
            padding: '18px 24px',
            borderBottom: '1px solid var(--color-border)',
            backgroundColor: 'var(--color-canvas)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '10px',
                backgroundColor: 'var(--color-primary-bg)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--color-primary)',
              }}
            >
              <Navigation size={20} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
                  Plan Journey & Route Assessment
                </h2>
                <span
                  style={{
                    fontSize: '10px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: 'var(--color-success-bg)',
                    color: 'var(--color-success)',
                  }}
                >
                  LIVE ROUTING
                </span>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                Risk-aware candidate route evaluation for North Eastern Region corridors
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            aria-label="Close modal"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              border: 'none',
              backgroundColor: 'var(--color-container)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--color-text-muted)',
              cursor: 'pointer',
            }}
          >
            <X size={16} />
          </button>
        </div>

        {/* CONTENT */}
        <div style={{ padding: '24px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {/* LOCATION INPUTS WITH SWAP */}
          <div
            style={{
              padding: '16px',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-canvas)',
              position: 'relative',
              display: 'flex',
              flexDirection: 'column',
              gap: '12px',
            }}
          >
            {/* Origin Field */}
            <div style={{ position: 'relative' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                  Starting Point / Origin (Any Town, Hub, or Coords)
                </label>
                <span style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--color-primary)', fontWeight: 600 }}>
                  📍 {originCoords.latitude.toFixed(4)}, {originCoords.longitude.toFixed(4)}
                </span>
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                <div
                  style={{
                    flex: 1,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    height: '42px',
                    padding: '0 12px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    boxShadow: 'var(--input-shadow)',
                  }}
                >
                  <MapPin size={16} color="var(--color-success)" />
                  <input
                    type="text"
                    value={origin}
                    onChange={(e) => {
                      setOrigin(e.target.value);
                      const parsed = parseOrLookupCoords(e.target.value, originCoords.latitude, originCoords.longitude);
                      setOriginCoords(parsed);
                      setShowOriginPicker(true);
                      calculateLiveRoutes(parsed, destCoords);
                    }}
                    onFocus={() => setShowOriginPicker(true)}
                    placeholder="Search or enter origin hub..."
                    style={{
                      border: 'none',
                      outline: 'none',
                      width: '100%',
                      fontSize: '13px',
                      fontWeight: 600,
                      color: 'var(--color-text-primary)',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowOriginPicker(!showOriginPicker)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)' }}
                  >
                    <ChevronDown size={16} />
                  </button>
                </div>
                <button
                  type="button"
                  onClick={handleUseGpsForOrigin}
                  title="Use My Current GPS Location"
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '0 14px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-primary)',
                    backgroundColor: 'var(--color-container)',
                    color: 'var(--color-primary)',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
                    whiteSpace: 'nowrap',
                  }}
                >
                  <Crosshair size={14} className={gpsOriginLoading ? 'animate-spin' : ''} />
                  <span>{gpsOriginLoading ? 'Locking GPS...' : 'My Live Location'}</span>
                </button>
              </div>

              {/* Origin Dropdown Autocomplete */}
              {showOriginPicker && (
                <div
                  style={{
                    position: 'absolute',
                    top: '100%',
                    left: 0,
                    right: 0,
                    backgroundColor: '#FFFFFF',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    boxShadow: '0 10px 25px -5px rgba(0,0,0,0.15)',
                    zIndex: 50,
                    marginTop: '4px',
                    maxHeight: '230px',
                    overflowY: 'auto',
                    padding: '6px',
                  }}
                >
                  <div style={{ padding: '4px 8px', fontSize: '11px', fontWeight: 700, color: 'var(--color-text-disabled)', textTransform: 'uppercase', display: 'flex', justifyContent: 'space-between' }}>
                    <span>Matched Places across NER</span>
                    <span style={{ fontSize: '10px', textTransform: 'none', color: 'var(--color-primary)' }}>Free-form location search active</span>
                  </div>
                  {originSuggestions.length > 0 ? (
                    originSuggestions.map((place, idx) => (
                      <div
                        key={`${place.name}-${idx}`}
                        onClick={() => {
                          const newCoords = { latitude: place.latitude, longitude: place.longitude, label: place.name };
                          setOrigin(place.name);
                          setOriginCoords(newCoords);
                          setShowOriginPicker(false);
                          calculateLiveRoutes(newCoords, destCoords);
                        }}
                        style={{
                          padding: '8px 10px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          fontSize: '13px',
                          cursor: 'pointer',
                          borderRadius: '4px',
                          color: 'var(--color-text-primary)',
                        }}
                        onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = 'var(--color-canvas)')}
                        onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <MapPin size={14} color="var(--color-primary)" />
                          <div>
                            <span style={{ fontWeight: 600 }}>{place.name}</span>
                            {place.state && (
                              <span style={{ marginLeft: '6px', fontSize: '11px', color: 'var(--color-text-muted)' }}>
                                ({place.state})
                              </span>
                            )}
                          </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <span style={{ fontSize: '10px', padding: '1px 6px', borderRadius: '4px', backgroundColor: 'var(--color-container)', color: 'var(--color-primary)', fontWeight: 600 }}>
                            {place.place_type?.toUpperCase() || 'PLACE'}
                          </span>
                          <span style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--color-text-muted)' }}>
                            {place.latitude.toFixed(2)}, {place.longitude.toFixed(2)}
                          </span>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div style={{ padding: '8px 10px', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      Press enter or type coordinates (e.g. 26.14, 91.73)
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Swap Button Divider */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '-4px 0' }}>
              <button
                type="button"
                onClick={handleSwap}
                title="Swap Origin and Destination"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '4px 12px',
                  borderRadius: 'var(--radius-pill)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: '#FFFFFF',
                  color: 'var(--color-primary)',
                  fontSize: '11px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.05)',
                  transition: 'all var(--transition-fast)',
                }}
              >
                <ArrowUpDown size={13} />
                <span>Swap Hubs</span>
              </button>
            </div>

            {/* Destination Field */}
            <div style={{ position: 'relative' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                  Final Destination (Any Town, Hub, or Coords)
                </label>
                <span style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--color-primary)', fontWeight: 600 }}>
                  📍 {destCoords.latitude.toFixed(4)}, {destCoords.longitude.toFixed(4)}
                </span>
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                <div
                  style={{
                    flex: 1,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    height: '42px',
                    padding: '0 12px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    boxShadow: 'var(--input-shadow)',
                  }}
                >
                  <MapPin size={16} color="var(--color-primary)" />
                  <input
                    type="text"
                    value={destination}
                    onChange={(e) => {
                      setDestination(e.target.value);
                      const parsed = parseOrLookupCoords(e.target.value, destCoords.latitude, destCoords.longitude);
                      setDestCoords(parsed);
                      setShowDestPicker(true);
                      calculateLiveRoutes(originCoords, parsed);
                    }}
                    onFocus={() => setShowDestPicker(true)}
                    placeholder="Search or enter destination..."
                    style={{
                      border: 'none',
                      outline: 'none',
                      width: '100%',
                      fontSize: '13px',
                      fontWeight: 600,
                      color: 'var(--color-text-primary)',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowDestPicker(!showDestPicker)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)' }}
                  >
                    <ChevronDown size={16} />
                  </button>
                </div>
                <button
                  type="button"
                  onClick={handleUseGpsForDest}
                  title="Use My Current GPS Coordinates for Destination"
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '0 14px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    backgroundColor: '#FFFFFF',
                    color: 'var(--color-primary)',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
                    whiteSpace: 'nowrap',
                  }}
                >
                  <Crosshair size={14} className={gpsDestLoading ? 'animate-spin' : ''} />
                  <span>{gpsDestLoading ? 'Locking GPS...' : 'My Live Location'}</span>
                </button>
              </div>

              {/* Destination Dropdown Autocomplete */}
              {showDestPicker && (
                <div
                  style={{
                    position: 'absolute',
                    top: '100%',
                    left: 0,
                    right: 0,
                    backgroundColor: '#FFFFFF',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    boxShadow: '0 10px 25px -5px rgba(0,0,0,0.15)',
                    zIndex: 50,
                    marginTop: '4px',
                    maxHeight: '230px',
                    overflowY: 'auto',
                    padding: '6px',
                  }}
                >
                  <div style={{ padding: '4px 8px', fontSize: '11px', fontWeight: 700, color: 'var(--color-text-disabled)', textTransform: 'uppercase', display: 'flex', justifyContent: 'space-between' }}>
                    <span>Matched Places across NER</span>
                    <span style={{ fontSize: '10px', textTransform: 'none', color: 'var(--color-primary)' }}>Free-form location search active</span>
                  </div>
                  {destSuggestions.length > 0 ? (
                    destSuggestions.map((place, idx) => (
                      <div
                        key={`${place.name}-${idx}`}
                        onClick={() => {
                          const newCoords = { latitude: place.latitude, longitude: place.longitude, label: place.name };
                          setDestination(place.name);
                          setDestCoords(newCoords);
                          setShowDestPicker(false);
                          calculateLiveRoutes(originCoords, newCoords);
                        }}
                        style={{
                          padding: '8px 10px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          fontSize: '13px',
                          cursor: 'pointer',
                          borderRadius: '4px',
                          color: 'var(--color-text-primary)',
                        }}
                        onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = 'var(--color-canvas)')}
                        onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <MapPin size={14} color="var(--color-primary)" />
                          <div>
                            <span style={{ fontWeight: 600 }}>{place.name}</span>
                            {place.state && (
                              <span style={{ marginLeft: '6px', fontSize: '11px', color: 'var(--color-text-muted)' }}>
                                ({place.state})
                              </span>
                            )}
                          </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <span style={{ fontSize: '10px', padding: '1px 6px', borderRadius: '4px', backgroundColor: 'var(--color-container)', color: 'var(--color-primary)', fontWeight: 600 }}>
                            {place.place_type?.toUpperCase() || 'PLACE'}
                          </span>
                          <span style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--color-text-muted)' }}>
                            {place.latitude.toFixed(2)}, {place.longitude.toFixed(2)}
                          </span>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div style={{ padding: '8px 10px', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      Press enter or type coordinates (e.g. 25.57, 91.89)
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>


          {/* VEHICLE & CARGO SELECTORS */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            {/* Vehicle Profile */}
            <div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '8px' }}>
                <Truck size={15} color="var(--color-primary)" />
                <span>Vehicle Profile</span>
              </label>
              <select
                value={vehicle}
                onChange={(e) => setVehicle(e.target.value)}
                style={{
                  width: '100%',
                  height: '42px',
                  padding: '0 12px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: '#FFFFFF',
                  fontSize: '13px',
                  fontWeight: 600,
                  color: 'var(--color-text-primary)',
                  outline: 'none',
                  cursor: 'pointer',
                }}
              >
                {VEHICLE_PROFILES.map((v) => (
                  <option key={v.id} value={v.name}>
                    {v.name} ({v.category})
                  </option>
                ))}
              </select>
              <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                Bridge clearance & hairpin gradient restrictions applied.
              </div>
            </div>

            {/* Cargo Priority */}
            <div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '8px' }}>
                <Package size={15} color="var(--color-primary)" />
                <span>Cargo Priority</span>
              </label>
              <select
                value={cargo}
                onChange={(e) => setCargo(e.target.value)}
                style={{
                  width: '100%',
                  height: '42px',
                  padding: '0 12px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: '#FFFFFF',
                  fontSize: '13px',
                  fontWeight: 600,
                  color: 'var(--color-text-primary)',
                  outline: 'none',
                  cursor: 'pointer',
                }}
              >
                {CARGO_TYPES.map((c) => (
                  <option key={c.id} value={c.name}>
                    {c.name} ({c.category})
                  </option>
                ))}
              </select>
              <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                Sets risk tolerance and multi-route optimization objective.
              </div>
            </div>
          </div>

          {/* CANDIDATE ROUTES (INTERACTIVE) */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
              <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--color-text-disabled)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Candidate Routes Evaluated
              </span>
              <span style={{ fontSize: '11px', color: isCalculating ? 'var(--color-primary)' : 'var(--color-text-muted)', fontWeight: isCalculating ? 700 : 400 }}>
                {isCalculating ? 'Computing optimal routes...' : `Comparing ${origin} → ${destination}`}
              </span>
            </div>

            {(() => {
              const safestClauses = calculateDistanceClauses(originCoords, destCoords, true, vehicle, cargo);
              const fasterClauses = calculateDistanceClauses(originCoords, destCoords, false, vehicle, cargo);

              if (liveRoutes && liveRoutes.length > 0) {
                const minDist = Math.min(...liveRoutes.map((r) => r.total_distance_km || 9999));

                return (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {liveRoutes.map((route) => {
                      const isSelected = selectedRoute === route.id;
                      const isSafest = route.is_recommended_safest;
                      const isFastest = route.is_fastest_available;
                      const detourKm = Math.max(0, (route.total_distance_km || 0) - minDist);

                      let badgeText = 'ALTERNATIVE BYPASS';
                      let badgeBg = '#E0F2FE';
                      let badgeColor = '#0284C7';

                      if (isSafest && isFastest) {
                        badgeText = 'RECOMMENDED · FASTEST';
                        badgeBg = 'var(--color-success-bg)';
                        badgeColor = 'var(--color-success)';
                      } else if (isSafest) {
                        badgeText = 'RECOMMENDED (SAFEST)';
                        badgeBg = 'var(--color-success-bg)';
                        badgeColor = 'var(--color-success)';
                      } else if (isFastest) {
                        badgeText = 'FASTER OPTION';
                        badgeBg = '#FEF3C7';
                        badgeColor = '#B45309';
                      }

                      const riskScore = Math.round(route.composite_risk_score * 100);
                      const isHighRisk = route.composite_risk_score > 0.6;
                      const isModRisk = route.composite_risk_score > 0.35;
                      const riskLabel = isHighRisk ? 'Risk: HIGH' : (isModRisk ? 'Risk: MODERATE' : 'Risk: LOW');
                      const riskColor = isHighRisk ? 'var(--color-danger)' : (isModRisk ? '#D97706' : 'var(--color-success)');

                      const durMins = route.estimated_duration_mins || 0;
                      const etaFormatted = `ETA ${Math.floor(durMins / 60)}h ${Math.round(durMins % 60)}m`;

                      return (
                        <div
                          key={route.id}
                          onClick={() => setSelectedRoute(route.id)}
                          style={{
                            padding: '14px 16px',
                            borderRadius: 'var(--radius-md)',
                            border: isSelected ? '2px solid var(--color-primary)' : '1px solid var(--color-border)',
                            backgroundColor: isSelected ? 'var(--color-primary-bg)' : '#FFFFFF',
                            cursor: 'pointer',
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            transition: 'all var(--transition-fast)',
                          }}
                        >
                          <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              <span style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                                {route.name}
                              </span>
                              <span
                                style={{
                                  fontSize: '10px',
                                  fontWeight: 700,
                                  padding: '2px 8px',
                                  borderRadius: 'var(--radius-pill)',
                                  backgroundColor: badgeBg,
                                  color: badgeColor,
                                }}
                              >
                                {badgeText}
                              </span>
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setActiveAuditBreakdown(safestClauses.breakdown);
                                  setActiveAuditRouteName(route.name);
                                  setAuditModalOpen(true);
                                }}
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: '4px',
                                  padding: '2px 8px',
                                  borderRadius: 'var(--radius-pill)',
                                  backgroundColor: '#E0F2FE',
                                  border: '1px solid #0284C7',
                                  color: '#0284C7',
                                  fontSize: '10px',
                                  fontWeight: 700,
                                  cursor: 'pointer',
                                }}
                              >
                                <Scale size={11} />
                                <span>Clauses Applied</span>
                              </button>
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginTop: '6px', fontSize: '12px', color: 'var(--color-text-secondary)' }}>
                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <Clock size={13} />
                                <strong>{etaFormatted}</strong>
                              </span>
                              <span>·</span>
                              <span style={{ fontWeight: 600 }}>{route.total_distance_km.toFixed(1)} km road</span>
                              <span>·</span>
                              <span style={{ color: riskColor, fontWeight: 600 }}>{riskScore}% Disruption Probability</span>
                              <span>·</span>
                              <span style={{ color: riskColor, fontWeight: 700 }}>{riskLabel} ({riskScore})</span>
                            </div>
                            {/* Verified incident hazard warning — shown when risk engine detects a BLOCKED or HIGH_RISK condition from a field report */}
                            {(!route.is_viable || route.max_hazard_state === 'BLOCKED') && (
                              <div
                                style={{
                                  marginTop: '8px',
                                  padding: '8px 12px',
                                  borderRadius: 'var(--radius-sm)',
                                  backgroundColor: '#FEF2F2',
                                  border: '1px solid #FCA5A5',
                                  display: 'flex',
                                  alignItems: 'center',
                                  gap: '8px',
                                  fontSize: '12px',
                                  fontWeight: 700,
                                  color: '#DC2626',
                                }}
                              >
                                <span>⛔</span>
                                <span>Route blocked by verified field incident — selection not recommended</span>
                              </div>
                            )}
                            {(route.is_viable && route.max_hazard_state === 'HIGH_RISK') && (
                              <div
                                style={{
                                  marginTop: '8px',
                                  padding: '8px 12px',
                                  borderRadius: 'var(--radius-sm)',
                                  backgroundColor: '#FFFBEB',
                                  border: '1px solid #FCD34D',
                                  display: 'flex',
                                  alignItems: 'center',
                                  gap: '8px',
                                  fontSize: '12px',
                                  fontWeight: 700,
                                  color: '#B45309',
                                }}
                              >
                                <span>⚠️</span>
                                <span>High-risk verified incident on this route — proceed with caution</span>
                              </div>
                            )}
                            {/* Distance Clauses Applied Strip */}
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: '8px' }}>
                              <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#F1F5F9', color: '#475569', fontWeight: 600 }}>
                                Aerial: {safestClauses.aerial} km
                              </span>
                              <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#CCFBF1', color: '#0F766E', fontWeight: 600 }}>
                                IRC:SP:48 (+38%): +{safestClauses.curvature} km
                              </span>
                              {safestClauses.axle > 0 && (
                                <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#EDE9FE', color: '#6D28D9', fontWeight: 600 }}>
                                  Axle Clause: +{safestClauses.axle} km
                                </span>
                              )}
                              {detourKm > 0.5 ? (
                                <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#DCFCE7', color: '#15803D', fontWeight: 600 }}>
                                  Detour: +{detourKm.toFixed(1)} km
                                </span>
                              ) : (
                                <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#FEF3C7', color: '#B45309', fontWeight: 600 }}>
                                  Direct Pass (0 km Detour)
                                </span>
                              )}
                              {safestClauses.cargo > 0 && (
                                <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#FEE2E2', color: '#DC2626', fontWeight: 600 }}>
                                  Cargo Buffer: +{safestClauses.cargo} km
                                </span>
                              )}
                            </div>
                          </div>

                          <div
                            style={{
                              width: '20px',
                              height: '20px',
                              borderRadius: '50%',
                              border: isSelected ? '6px solid var(--color-primary)' : '2px solid var(--color-border)',
                              backgroundColor: '#FFFFFF',
                            }}
                          />
                        </div>
                      );
                    })}
                  </div>
                );
              }


              return (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {/* Route A - Safest */}
                  <div
                    onClick={() => setSelectedRoute('safest')}
                    style={{
                      padding: '14px 16px',
                      borderRadius: 'var(--radius-md)',
                      border: selectedRoute === 'safest' ? '2px solid var(--color-primary)' : '1px solid var(--color-border)',
                      backgroundColor: selectedRoute === 'safest' ? 'var(--color-primary-bg)' : '#FFFFFF',
                      cursor: 'pointer',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      transition: 'all var(--transition-fast)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                          Route A · NH-06 via Nongpoh
                        </span>
                        <span
                          style={{
                            fontSize: '10px',
                            fontWeight: 700,
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-pill)',
                            backgroundColor: 'var(--color-success-bg)',
                            color: 'var(--color-success)',
                          }}
                        >
                          RECOMMENDED (SAFEST)
                        </span>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setActiveAuditBreakdown(safestClauses.breakdown);
                            setActiveAuditRouteName('Route A · NH-06 via Nongpoh (Safest)');
                            setAuditModalOpen(true);
                          }}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-pill)',
                            backgroundColor: '#E0F2FE',
                            border: '1px solid #0284C7',
                            color: '#0284C7',
                            fontSize: '10px',
                            fontWeight: 700,
                            cursor: 'pointer',
                          }}
                        >
                          <Scale size={11} />
                          <span>Clauses Applied (+{(safestClauses.total - safestClauses.aerial).toFixed(1)} km)</span>
                        </button>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginTop: '6px', fontSize: '12px', color: 'var(--color-text-secondary)' }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Clock size={13} />
                          <strong>{safestClauses.etaText}</strong>
                        </span>
                        <span>·</span>
                        <span style={{ fontWeight: 600 }}>{safestClauses.total} km road</span>
                        <span>·</span>
                        <span style={{ color: 'var(--color-success)', fontWeight: 600 }}>14% Disruption Probability</span>
                        <span>·</span>
                        <span style={{ color: 'var(--color-success)', fontWeight: 700 }}>Risk: LOW (28)</span>
                      </div>
                      {/* Distance Clauses Applied Strip */}
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: '8px' }}>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#F1F5F9', color: '#475569', fontWeight: 600 }}>
                          Aerial: {safestClauses.aerial} km
                        </span>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#CCFBF1', color: '#0F766E', fontWeight: 600 }}>
                          IRC:SP:48 (+38%): +{safestClauses.curvature} km
                        </span>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#EDE9FE', color: '#6D28D9', fontWeight: 600 }}>
                          Axle Clause: +{safestClauses.axle} km
                        </span>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#DCFCE7', color: '#15803D', fontWeight: 600 }}>
                          Hazard Detour: +{safestClauses.detour} km
                        </span>
                        {safestClauses.cargo > 0 && (
                          <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#FEE2E2', color: '#DC2626', fontWeight: 600 }}>
                            Cargo Buffer: +{safestClauses.cargo} km
                          </span>
                        )}
                      </div>
                    </div>

                    <div
                      style={{
                        width: '20px',
                        height: '20px',
                        borderRadius: '50%',
                        border: selectedRoute === 'safest' ? '6px solid var(--color-primary)' : '2px solid var(--color-border)',
                        backgroundColor: '#FFFFFF',
                      }}
                    />
                  </div>

                  {/* Route B - Faster */}
                  <div
                    onClick={() => setSelectedRoute('faster')}
                    style={{
                      padding: '14px 16px',
                      borderRadius: 'var(--radius-md)',
                      border: selectedRoute === 'faster' ? '2px solid #F59E0B' : '1px solid var(--color-border)',
                      backgroundColor: selectedRoute === 'faster' ? '#FFFBEB' : '#FFFFFF',
                      cursor: 'pointer',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      transition: 'all var(--transition-fast)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                          Route B · Direct Hill Bypass
                        </span>
                        <span
                          style={{
                            fontSize: '10px',
                            fontWeight: 700,
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-pill)',
                            backgroundColor: '#FEF3C7',
                            color: '#B45309',
                          }}
                        >
                          FASTER (+45m Saved)
                        </span>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setActiveAuditBreakdown(fasterClauses.breakdown);
                            setActiveAuditRouteName('Route B · Direct Hill Bypass (Faster)');
                            setAuditModalOpen(true);
                          }}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-pill)',
                            backgroundColor: '#FEF3C7',
                            border: '1px solid #D97706',
                            color: '#B45309',
                            fontSize: '10px',
                            fontWeight: 700,
                            cursor: 'pointer',
                          }}
                        >
                          <Scale size={11} />
                          <span>Clauses Applied (+{(fasterClauses.total - fasterClauses.aerial).toFixed(1)} km)</span>
                        </button>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginTop: '6px', fontSize: '12px', color: 'var(--color-text-secondary)' }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Clock size={13} />
                          <strong>{fasterClauses.etaText}</strong>
                        </span>
                        <span>·</span>
                        <span style={{ fontWeight: 600 }}>{fasterClauses.total} km road</span>
                        <span>·</span>
                        <span style={{ color: 'var(--color-danger)', fontWeight: 600 }}>78% Disruption Probability</span>
                        <span>·</span>
                        <span style={{ color: 'var(--color-danger)', fontWeight: 700 }}>Risk: HIGH (84)</span>
                      </div>
                      {/* Distance Clauses Applied Strip */}
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: '8px' }}>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#F1F5F9', color: '#475569', fontWeight: 600 }}>
                          Aerial: {fasterClauses.aerial} km
                        </span>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#CCFBF1', color: '#0F766E', fontWeight: 600 }}>
                          IRC:SP:48 (+38%): +{fasterClauses.curvature} km
                        </span>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#EDE9FE', color: '#6D28D9', fontWeight: 600 }}>
                          Axle Clause: +{fasterClauses.axle} km
                        </span>
                        <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#FEF3C7', color: '#B45309', fontWeight: 600 }}>
                          Direct Pass (0 km Detour)
                        </span>
                        {fasterClauses.cargo > 0 && (
                          <span style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#FEE2E2', color: '#DC2626', fontWeight: 600 }}>
                            Cargo Buffer: +{fasterClauses.cargo} km
                          </span>
                        )}
                      </div>
                    </div>

                    <div
                      style={{
                        width: '20px',
                        height: '20px',
                        borderRadius: '50%',
                        border: selectedRoute === 'faster' ? '6px solid #F59E0B' : '2px solid var(--color-border)',
                        backgroundColor: '#FFFFFF',
                      }}
                    />
                  </div>
                </div>
              );
            })()}
          </div>

          {confirmedMessage && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: '12px 16px',
                borderRadius: 'var(--radius-sm)',
                backgroundColor: 'var(--color-success-bg)',
                border: '1px solid var(--color-success)',
                color: 'var(--color-success)',
                fontSize: '13px',
                fontWeight: 600,
              }}
            >
              <CheckCircle2 size={18} />
              <span>{confirmedMessage}</span>
            </div>
          )}
        </div>

        {/* FOOTER */}
        <div
          style={{
            padding: '16px 24px',
            borderTop: '1px solid var(--color-border)',
            backgroundColor: 'var(--color-canvas)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
            Authoritative routing logic separates observed accessibility from ML prediction.
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <button
              type="button"
              onClick={onClose}
              style={{
                height: '40px',
                padding: '0 16px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)',
                backgroundColor: '#FFFFFF',
                color: 'var(--color-text-secondary)',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              Cancel
            </button>

            <button
              type="button"
              onClick={handleConfirm}
              style={{
                height: '40px',
                padding: '0 20px',
                borderRadius: 'var(--radius-sm)',
                border: 'none',
                backgroundColor: selectedRoute === 'safest' ? 'var(--color-primary)' : '#D97706',
                color: '#FFFFFF',
                fontSize: '13px',
                fontWeight: 700,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                boxShadow: 'var(--card-shadow)',
              }}
            >
              <ShieldCheck size={16} />
              <span>Confirm Route</span>
            </button>
          </div>
        </div>
      </div>

      <DistanceClausesModal
        isOpen={auditModalOpen}
        onClose={() => setAuditModalOpen(false)}
        breakdown={activeAuditBreakdown}
        originName={origin}
        destName={destination}
        vehicleName={vehicle}
        cargoName={cargo}
        routeName={activeAuditRouteName}
      />
    </div>
  );
};
