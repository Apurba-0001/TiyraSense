import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  Compass,
  Plus,
  Minus,
  Scale,
  Layers,
  Map as MapIcon,
  Mountain,
  Satellite as SatelliteIcon,
  AlertTriangle,
  AlertCircle,
  X,
  Check,
} from 'lucide-react';
import { computeDetailedBreakdown, DistanceBreakdown } from '../utils/distanceUtils';
import { DistanceClausesModal } from './DistanceClausesModal';
import { evaluateRoutes } from '../services/api';

export interface FleetVehicle {
  id: string;
  vehicleNumber: string;
  model: string;
  driverName: string;
  driverPhone?: string;
  role: 'DRIVER' | 'FIELD_WORKER';
  cargo: string;
  originName: string;
  destName: string;
  originCoords: { lat: number; lng: number };
  destCoords: { lat: number; lng: number };
  routeName: string;
  currentCoords: { lat: number; lng: number };
  speedKmh: number;
  progress: number;
  status: 'IN_TRANSIT' | 'CONVOY_ESCORT' | 'HALTED_CHECKPOINT' | 'HAZARD_SLOWED';
  lastPing: string;
  hazardAhead?: string;
  routeGeometry?: [number, number][];
}

export interface VectorGisMapProps {
  originName?: string;
  destName?: string;
  originCoords?: { lat: number; lng: number };
  destCoords?: { lat: number; lng: number };
  routeName?: string;
  vehicleName?: string;
  cargoName?: string;
  roleMode?: 'driver' | 'field_worker' | 'official' | 'admin';
  height?: number | string;
  showControls?: boolean;
  onOpenClauses?: () => void;
  vehicles?: FleetVehicle[];
  selectedVehicleId?: string;
  onSelectVehicle?: (vehicle: FleetVehicle) => void;
  fleetViewMode?: 'selected' | 'all';
  onFleetViewModeChange?: (mode: 'selected' | 'all') => void;
}

// Web Mercator conversions
const latLngToWorld = (lat: number, lng: number, z: number) => {
  const scale = 256 * Math.pow(2, z);
  const x = ((lng + 180) / 360) * scale;
  const sinLat = Math.min(Math.max(Math.sin((lat * Math.PI) / 180), -0.9999), 0.9999);
  const y = (0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI)) * scale;
  return { x, y };
};

const getTileUrl = (type: 'road' | 'satellite' | 'terrain', z: number, x: number, y: number) => {
  const maxTile = Math.pow(2, z);
  const wrappedX = ((x % maxTile) + maxTile) % maxTile;
  if (y < 0 || y >= maxTile) return '';

  if (type === 'satellite') {
    return `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${wrappedX}`;
  }
  if (type === 'terrain') {
    return `https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/${z}/${y}/${wrappedX}`;
  }
  // 'road' - OpenStreetMap Standard Tile Server (Fast, free, no API key required, zero watermark)
  const subdomains = ['a', 'b', 'c'];
  const s = subdomains[Math.abs(wrappedX + y) % subdomains.length];
  return `https://${s}.tile.openstreetmap.org/${z}/${wrappedX}/${y}.png`;
};

export const VectorGisMap: React.FC<VectorGisMapProps> = ({
  originName: initialOriginName = 'Guwahati Port Hub',
  destName: initialDestName = 'Shillong Terminal Hub',
  originCoords: initialOriginCoords = { lat: 26.1445, lng: 91.7362 },
  destCoords: initialDestCoords = { lat: 25.5788, lng: 91.8933 },
  routeName: initialRouteName = 'NH-06 via Nongpoh',
  vehicleName: initialVehicleName = 'Tata Prima 31T',
  cargoName: initialCargoName = 'Standard Dry Cargo',
  roleMode = 'official',
  height = 420,
  showControls = true,
  onOpenClauses,
  vehicles,
  selectedVehicleId,
  onSelectVehicle,
  fleetViewMode,
  onFleetViewModeChange,
}) => {
  const [internalViewMode, setInternalViewMode] = useState<'selected' | 'all'>(
    vehicles && vehicles.length > 0 ? 'all' : 'selected'
  );
  const viewMode = fleetViewMode !== undefined ? fleetViewMode : internalViewMode;
  const handleViewModeChange = (m: 'selected' | 'all') => {
    setInternalViewMode(m);
    onFleetViewModeChange?.(m);
  };

  const selectedVehicle =
    vehicles?.find((v) => v.id === selectedVehicleId) ||
    (vehicles && vehicles.length > 0 ? vehicles[0] : undefined);
  const originName = selectedVehicle?.originName || initialOriginName;
  const destName = selectedVehicle?.destName || initialDestName;
  const originCoords = selectedVehicle?.originCoords || initialOriginCoords;
  const destCoords = selectedVehicle?.destCoords || initialDestCoords;
  const routeName = selectedVehicle?.routeName || initialRouteName;
  const vehicleName = selectedVehicle?.model || initialVehicleName;
  const cargoName = selectedVehicle?.cargo || initialCargoName;

  const displayedVehicles = useMemo(() => {
    if (!vehicles || vehicles.length === 0) return [];
    if (viewMode === 'selected') {
      const active = vehicles.find((v) => v.id === (selectedVehicle?.id || vehicles[0].id));
      return active ? [active] : [vehicles[0]];
    }
    return vehicles;
  }, [vehicles, viewMode, selectedVehicle?.id]);

  const [mapZoom, setMapZoom] = useState<number>(10);
  const [zoomLevel, setZoomLevel] = useState<number>(1.0);
  const [panOffset, setPanOffset] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [vehicleProgress, setVehicleProgress] = useState<number>(0.38);
  const [isClausesModalOpen, setIsClausesModalOpen] = useState<boolean>(false);
  const [mapType, setMapType] = useState<'road' | 'satellite' | 'terrain'>('road');
  const [showAlerts, setShowAlerts] = useState<boolean>(true);
  const [showIncidents, setShowIncidents] = useState<boolean>(true);
  const [isLayerMenuOpen, setIsLayerMenuOpen] = useState<boolean>(false);

  // Real Multi-Point Route Geometry from Backend OSRM Ingestion
  const [realSafeCoords, setRealSafeCoords] = useState<[number, number][]>([]);
  const [realAltCoords, setRealAltCoords] = useState<[number, number][]>([]);

  const containerRef = useRef<HTMLDivElement>(null);
  const [dimensions, setDimensions] = useState<{ width: number; height: number }>({
    width: 1200,
    height: typeof height === 'number' ? height : 450,
  });

  // Track responsive container size dynamically
  useEffect(() => {
    if (!containerRef.current) return;
    const el = containerRef.current;
    const updateSize = () => {
      if (el.clientWidth > 0) {
        setDimensions({
          width: el.clientWidth,
          height: el.clientHeight || (typeof height === 'number' ? height : 450),
        });
      }
    };
    updateSize();
    if (typeof ResizeObserver !== 'undefined') {
      const observer = new ResizeObserver(updateSize);
      observer.observe(el);
      return () => observer.disconnect();
    }
    window.addEventListener('resize', updateSize);
    return () => window.removeEventListener('resize', updateSize);
  }, [height]);

  // Fetch genuine road vectors from backend routing engine
  useEffect(() => {
    let isMounted = true;
    if (selectedVehicle?.routeGeometry && selectedVehicle.routeGeometry.length > 1) {
      setRealSafeCoords(selectedVehicle.routeGeometry);
      return () => {
        isMounted = false;
      };
    }

    const loadRoute = async () => {
      try {
        const res = await evaluateRoutes(
          { latitude: originCoords.lat, longitude: originCoords.lng, label: originName },
          { latitude: destCoords.lat, longitude: destCoords.lng, label: destName },
          'FOUR_WHEELER',
          true
        );
        if (!isMounted) return;
        const candidates = res.routes || res.candidate_routes || [];
        if (candidates.length > 0 && candidates[0].geometry_geojson?.coordinates) {
          setRealSafeCoords(candidates[0].geometry_geojson.coordinates);
        }
        if (candidates.length > 1 && candidates[1].geometry_geojson?.coordinates) {
          setRealAltCoords(candidates[1].geometry_geojson.coordinates);
        }
      } catch (err) {
        // Fallback gracefully if backend is temporarily disconnected
      }
    };
    loadRoute();
    return () => {
      isMounted = false;
    };
  }, [originCoords.lat, originCoords.lng, destCoords.lat, destCoords.lng, originName, destName, selectedVehicle?.routeGeometry]);

  // Animate vehicle along route if no real telemetry stream exists
  useEffect(() => {
    const interval = setInterval(() => {
      setVehicleProgress((prev) => (prev >= 0.96 ? 0.04 : prev + 0.003));
    }, 120);
    return () => clearInterval(interval);
  }, []);

  // Compute live breakdown
  const breakdown: DistanceBreakdown = computeDetailedBreakdown({
    lat1: originCoords.lat,
    lon1: originCoords.lng,
    lat2: destCoords.lat,
    lon2: destCoords.lng,
    vehicleTitle: vehicleName,
    cargoTitle: cargoName,
    isSafestRoute: true,
  });

  const totalDistanceKm = breakdown.totalRoadKm;
  const remainingDistanceKm = Math.max(0, Math.round(totalDistanceKm * (1 - vehicleProgress) * 10) / 10);
  const currentSpeedKmh = selectedVehicle?.speedKmh || 38;

  // Center calculation based on bounding box
  const centerLat = (originCoords.lat + destCoords.lat) / 2;
  const centerLng = (originCoords.lng + destCoords.lng) / 2;
  const centerWorld = latLngToWorld(centerLat, centerLng, mapZoom);

  const toScreen = (lat: number, lng: number) => {
    const pt = latLngToWorld(lat, lng, mapZoom);
    const zFactor = zoomLevel;
    const rx = (pt.x - centerWorld.x) * zFactor + dimensions.width / 2 + panOffset.x;
    const ry = (pt.y - centerWorld.y) * zFactor + dimensions.height / 2 + panOffset.y;
    return { x: rx, y: ry };
  };

  const originScreen = toScreen(originCoords.lat, originCoords.lng);
  const destScreen = toScreen(destCoords.lat, destCoords.lng);

  // Generate Visible Real Slippy Tiles with Buffer for Panning
  const visibleTiles = useMemo(() => {
    const zFactor = zoomLevel;
    const halfW = dimensions.width / (2 * zFactor);
    const halfH = dimensions.height / (2 * zFactor);

    const minWorldX = centerWorld.x - halfW - panOffset.x / zFactor;
    const maxWorldX = centerWorld.x + halfW - panOffset.x / zFactor;
    const minWorldY = centerWorld.y - halfH - panOffset.y / zFactor;
    const maxWorldY = centerWorld.y + halfH - panOffset.y / zFactor;

    // Expand bounds by 1 tile buffer on every side to guarantee seamless panning and edge filling
    const minTileX = Math.floor(minWorldX / 256) - 1;
    const maxTileX = Math.floor(maxWorldX / 256) + 1;
    const minTileY = Math.floor(minWorldY / 256) - 1;
    const maxTileY = Math.floor(maxWorldY / 256) + 1;

    const tiles: { key: string; url: string; left: number; top: number; size: number }[] = [];
    for (let tx = minTileX; tx <= maxTileX; tx++) {
      for (let ty = minTileY; ty <= maxTileY; ty++) {
        const tileLeft = (tx * 256 - centerWorld.x) * zFactor + dimensions.width / 2 + panOffset.x;
        const tileTop = (ty * 256 - centerWorld.y) * zFactor + dimensions.height / 2 + panOffset.y;
        const tileSize = 256 * zFactor;
        tiles.push({
          key: `${mapType}-${mapZoom}-${tx}-${ty}`,
          url: getTileUrl(mapType, mapZoom, tx, ty),
          left: tileLeft,
          top: tileTop,
          size: tileSize,
        });
      }
    }
    return tiles;
  }, [mapType, mapZoom, zoomLevel, panOffset, centerWorld.x, centerWorld.y, dimensions.width, dimensions.height]);

  // Construct Real SVG Route Polyline Paths
  const safeRoutePathD = useMemo(() => {
    if (realSafeCoords.length > 1) {
      const pts = realSafeCoords.map(([lng, lat]) => toScreen(lat, lng));
      return `M ${pts[0].x.toFixed(1)},${pts[0].y.toFixed(1)} ` + pts.slice(1).map((p) => `L ${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(' ');
    }
    // Realistic curved fallback if OSRM hasn't loaded yet
    const midX = (originScreen.x + destScreen.x) / 2;
    const midY = (originScreen.y + destScreen.y) / 2;
    const safeCtrlX = midX + (destScreen.y - originScreen.y) * 0.18;
    const safeCtrlY = midY - (destScreen.x - originScreen.x) * 0.18;
    return `M ${originScreen.x},${originScreen.y} Q ${safeCtrlX},${safeCtrlY} ${destScreen.x},${destScreen.y}`;
  }, [realSafeCoords, originScreen.x, originScreen.y, destScreen.x, destScreen.y, zoomLevel, panOffset, mapZoom, dimensions.width, dimensions.height]);

  const altRoutePathD = useMemo(() => {
    if (realAltCoords.length > 1) {
      const pts = realAltCoords.map(([lng, lat]) => toScreen(lat, lng));
      return `M ${pts[0].x.toFixed(1)},${pts[0].y.toFixed(1)} ` + pts.slice(1).map((p) => `L ${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(' ');
    }
    const midX = (originScreen.x + destScreen.x) / 2;
    const midY = (originScreen.y + destScreen.y) / 2;
    const altCtrlX = midX - (destScreen.y - originScreen.y) * 0.22;
    const altCtrlY = midY + (destScreen.x - originScreen.x) * 0.22;
    return `M ${originScreen.x},${originScreen.y} Q ${altCtrlX},${altCtrlY} ${destScreen.x},${destScreen.y}`;
  }, [realAltCoords, originScreen.x, originScreen.y, destScreen.x, destScreen.y, zoomLevel, panOffset, mapZoom, dimensions.width, dimensions.height]);

  // Vehicle Tracking Beacon Coordinates along real road or live GPS
  let vehicleX = originScreen.x;
  let vehicleY = originScreen.y;
  if (
    selectedVehicle?.currentCoords &&
    (selectedVehicle.currentCoords.lat !== 0 || selectedVehicle.currentCoords.lng !== 0)
  ) {
    const pos = toScreen(selectedVehicle.currentCoords.lat, selectedVehicle.currentCoords.lng);
    vehicleX = pos.x;
    vehicleY = pos.y;
  } else if (realSafeCoords.length > 1) {
    const idx = Math.min(
      realSafeCoords.length - 1,
      Math.max(0, Math.floor(vehicleProgress * (realSafeCoords.length - 1)))
    );
    const [vLng, vLat] = realSafeCoords[idx];
    const pos = toScreen(vLat, vLng);
    vehicleX = pos.x;
    vehicleY = pos.y;
  } else {
    const midX = (originScreen.x + destScreen.x) / 2;
    const midY = (originScreen.y + destScreen.y) / 2;
    const safeCtrlX = midX + (destScreen.y - originScreen.y) * 0.18;
    const safeCtrlY = midY - (destScreen.x - originScreen.x) * 0.18;
    const t = vehicleProgress;
    vehicleX = (1 - t) * (1 - t) * originScreen.x + 2 * (1 - t) * t * safeCtrlX + t * t * destScreen.x;
    vehicleY = (1 - t) * (1 - t) * originScreen.y + 2 * (1 - t) * t * safeCtrlY + t * t * destScreen.y;
  }

  // Hazard and Alert Markers (Nongpoh & KM 52)
  const hazardLat = (originCoords.lat + destCoords.lat) / 2 + 0.04;
  const hazardLng = (originCoords.lng + destCoords.lng) / 2 - 0.02;
  const hazardScreen = toScreen(hazardLat, hazardLng);

  // Geographic Scale Bar
  const metersPerPixel = (156543.03392 * Math.cos((centerLat * Math.PI) / 180)) / (Math.pow(2, mapZoom) * zoomLevel);
  const scaleBarKm = Math.max(1, Math.round((80 * metersPerPixel) / 1000));

  // Pan & Drag Handlers
  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    setDragStart({ x: e.clientX - panOffset.x, y: e.clientY - panOffset.y });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    setPanOffset({ x: e.clientX - dragStart.x, y: e.clientY - dragStart.y });
  };

  const handleMouseUp = () => setIsDragging(false);

  // Native non-passive wheel & gesture zoom listener:
  // Guarantees ONLY the GIS map zooms and pan/scrolls, completely preventing
  // the browser window from zooming (Ctrl+Wheel / trackpad pinch) or scrolling.
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const onWheelHandler = (e: WheelEvent) => {
      // Intercept and prevent page zoom & window scrolling
      e.preventDefault();
      e.stopPropagation();

      const delta = e.deltaY < 0 ? 0.12 : -0.12;
      setZoomLevel((prev) => {
        const next = prev + delta;
        if (next >= 1.7 && mapZoom < 16) {
          setMapZoom((z) => Math.min(16, z + 1));
          return next / 2;
        } else if (next <= 0.65 && mapZoom > 7) {
          setMapZoom((z) => Math.max(7, z - 1));
          return next * 2;
        }
        return Math.max(0.5, Math.min(2.5, next));
      });
    };

    // Safari/WebKit trackpad gesture preventDefault
    const onGesture = (e: Event) => {
      e.preventDefault();
      e.stopPropagation();
    };

    el.addEventListener('wheel', onWheelHandler, { passive: false });
    el.addEventListener('gesturestart', onGesture, { passive: false });
    el.addEventListener('gesturechange', onGesture, { passive: false });
    el.addEventListener('gestureend', onGesture, { passive: false });

    return () => {
      el.removeEventListener('wheel', onWheelHandler);
      el.removeEventListener('gesturestart', onGesture);
      el.removeEventListener('gesturechange', onGesture);
      el.removeEventListener('gestureend', onGesture);
    };
  }, [mapZoom]);

  // Touch screen 2-finger pinch zoom
  const touchDistRef = useRef<number | null>(null);

  const handleTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 2) {
      touchDistRef.current = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
    }
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (e.touches.length === 2 && touchDistRef.current) {
      const d = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
      const ratio = d / touchDistRef.current;
      if (Math.abs(ratio - 1) > 0.04) {
        const delta = ratio > 1 ? 0.06 : -0.06;
        setZoomLevel((prev) => Math.max(0.5, Math.min(2.5, prev + delta)));
        touchDistRef.current = d;
      }
    }
  };

  const handleTouchEnd = () => {
    touchDistRef.current = null;
  };

  const handleZoomIn = () => {
    setZoomLevel((prev) => {
      const next = prev + 0.25;
      if (next >= 1.7 && mapZoom < 16) {
        setMapZoom((z) => Math.min(16, z + 1));
        return next / 2;
      }
      return Math.min(2.5, next);
    });
  };

  const handleZoomOut = () => {
    setZoomLevel((prev) => {
      const next = prev - 0.25;
      if (next <= 0.65 && mapZoom > 7) {
        setMapZoom((z) => Math.max(7, z - 1));
        return next * 2;
      }
      return Math.max(0.5, next);
    });
  };

  const handleReset = () => {
    setMapZoom(10);
    setZoomLevel(1.0);
    setPanOffset({ x: 0, y: 0 });
  };

  const handleOpenAudit = () => {
    if (onOpenClauses) {
      onOpenClauses();
    } else {
      setIsClausesModalOpen(true);
    }
  };

  const baseBg = mapType === 'satellite' ? '#0B1320' : mapType === 'terrain' ? '#E8ECD7' : '#F8FAFC';

  return (
    <div
      ref={containerRef}
      style={{
        position: 'relative',
        width: '100%',
        height: typeof height === 'number' ? `${height}px` : height,
        borderRadius: 'var(--radius-md)',
        overflow: 'hidden',
        border: '1px solid var(--color-border)',
        backgroundColor: baseBg,
        userSelect: 'none',
        touchAction: 'none',
        cursor: isDragging ? 'grabbing' : 'grab',
      }}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      {/* 1. REAL SLIPPY MAP TILE LAYER (OpenStreetMap Standard, Esri Satellite, Esri Topo) */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          overflow: 'hidden',
          pointerEvents: 'none',
        }}
      >
        {visibleTiles.map((tile) => (
          <img
            key={tile.key}
            src={tile.url}
            alt=""
            loading="eager"
            style={{
              position: 'absolute',
              left: `${tile.left}px`,
              top: `${tile.top}px`,
              width: `${tile.size}px`,
              height: `${tile.size}px`,
              userSelect: 'none',
              filter: mapType === 'satellite' ? 'contrast(1.05) brightness(0.95)' : 'none',
            }}
          />
        ))}
      </div>

      {/* 2. VECTOR GIS OVERLAY (Real Road Polylines, Fleet Markers, Hazards, Pins) */}
      <svg
        viewBox={`0 0 ${dimensions.width} ${dimensions.height}`}
        style={{
          position: 'absolute',
          inset: 0,
          width: '100%',
          height: '100%',
          display: 'block',
          pointerEvents: 'auto',
        }}
      >
        <defs>
          <filter id="routeGlow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="3" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>

          <radialGradient id="radarSweep" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#38BDF8" stopOpacity="0.6" />
            <stop offset="60%" stopColor="#0284C7" stopOpacity="0.2" />
            <stop offset="100%" stopColor="#0284C7" stopOpacity="0" />
          </radialGradient>
        </defs>

        {/* Route Polylines and Origin/Dest Pins (Shown in Selected Vehicle Mode) */}
        {(viewMode === 'selected' || !vehicles || vehicles.length <= 1) && (
          <>
            {/* Alternate Route (Amber Dashed Road Polyline) */}
            <path
              d={altRoutePathD}
              fill="none"
              stroke="#0F172A"
              strokeWidth="6"
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeOpacity="0.75"
            />
            <path
              d={altRoutePathD}
              fill="none"
              stroke="#F59E0B"
              strokeWidth="3.5"
              strokeDasharray="7 4"
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeOpacity="0.95"
            />

            {/* Primary Recommended Safest Route (Double-Cased Vibrant Blue Polyline) */}
            <path
              d={safeRoutePathD}
              fill="none"
              stroke="#0F172A"
              strokeWidth="8"
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeOpacity="0.8"
            />
            <path
              d={safeRoutePathD}
              fill="none"
              stroke={mapType === 'satellite' ? '#0284C7' : '#0284C7'}
              strokeWidth="11"
              strokeOpacity="0.3"
              filter="url(#routeGlow)"
            />
            <path
              d={safeRoutePathD}
              fill="none"
              stroke={mapType === 'satellite' ? '#38BDF8' : '#0284C7'}
              strokeWidth="4.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />

            {/* Origin Marker (Green Pin) */}
            <g transform={`translate(${originScreen.x}, ${originScreen.y})`}>
              <circle r="14" fill="#10B981" fillOpacity="0.3" />
              <circle r="7" fill="#10B981" stroke="#FFFFFF" strokeWidth="2" />
              <rect x="-42" y="-30" width="84" height="18" rx="4" fill="#064E3B" stroke="#10B981" strokeWidth="1" />
              <text x="0" y="-18" fill="#A7F3D0" fontSize="9" fontWeight="700" textAnchor="middle">
                {originName.split(' ')[0]} (START)
              </text>
            </g>

            {/* Destination Marker (Blue Pin) */}
            <g transform={`translate(${destScreen.x}, ${destScreen.y})`}>
              <circle r="14" fill="#3B82F6" fillOpacity="0.3" />
              <circle r="7" fill="#3B82F6" stroke="#FFFFFF" strokeWidth="2" />
              <rect x="-40" y="-30" width="80" height="18" rx="4" fill="#1E3A8A" stroke="#3B82F6" strokeWidth="1" />
              <text x="0" y="-18" fill="#BFDBFE" fontSize="9" fontWeight="700" textAnchor="middle">
                {destName.split(' ')[0]} (END)
              </text>
            </g>
          </>
        )}

        {/* Alerts Layer (Active Hazard Warning & Watch) */}
        {showAlerts && (
          <g>
            <g transform={`translate(${hazardScreen.x}, ${hazardScreen.y})`}>
              <circle r="18" fill="#EF4444" fillOpacity="0.3" />
              <circle r="9" fill="#DC2626" stroke="#FFFFFF" strokeWidth="1.5" />
              <text x="0" y="3" fill="#FFFFFF" fontSize="9" fontWeight="900" textAnchor="middle">!</text>
              <rect x="-46" y="14" width="92" height="16" rx="4" fill="#7F1D1D" stroke="#EF4444" strokeWidth="0.8" />
              <text x="0" y="25" fill="#FECACA" fontSize="8" fontWeight="700" textAnchor="middle">
                KM 52 Landslide
              </text>
            </g>
            {(() => {
              const alert2 = toScreen(25.982, 91.885);
              return (
                <g transform={`translate(${alert2.x}, ${alert2.y})`}>
                  <circle r="14" fill="#F59E0B" fillOpacity="0.3" />
                  <circle r="7" fill="#F59E0B" stroke="#FFFFFF" strokeWidth="1.5" />
                  <rect x="-46" y="-22" width="92" height="15" rx="4" fill="#78350F" stroke="#F59E0B" strokeWidth="0.8" />
                  <text x="0" y="-12" fill="#FEF3C7" fontSize="7.5" fontWeight="700" textAnchor="middle">
                    Nongpoh Flood Watch
                  </text>
                </g>
              );
            })()}
          </g>
        )}

        {/* Incidents Layer (Field Reports) */}
        {showIncidents && (
          <g>
            {(() => {
              const inc1 = toScreen(26.0124, 91.8901);
              const inc2 = toScreen(25.75, 91.901);
              return (
                <>
                  <g transform={`translate(${inc1.x}, ${inc1.y})`}>
                    <polygon points="0,-8 7,0 0,8 -7,0" fill="#DC2626" />
                    <circle r="2.5" fill="#FFFFFF" />
                    <rect x="-48" y="10" width="96" height="15" rx="4" fill="#FFFFFF" stroke="#DC2626" strokeWidth="1" />
                    <text x="0" y="21" fill="#DC2626" fontSize="7.5" fontWeight="800" textAnchor="middle">
                      INC: Boulder Roll
                    </text>
                  </g>
                  <g transform={`translate(${inc2.x}, ${inc2.y})`}>
                    <polygon points="0,-8 7,0 0,8 -7,0" fill="#EA580C" />
                    <circle r="2.5" fill="#FFFFFF" />
                    <rect x="-52" y="10" width="104" height="15" rx="4" fill="#FFFFFF" stroke="#EA580C" strokeWidth="1" />
                    <text x="0" y="21" fill="#EA580C" fontSize="7.5" fontWeight="800" textAnchor="middle">
                      INC: Heavy Fog Sector
                    </text>
                  </g>
                </>
              );
            })()}
          </g>
        )}

        {/* Fleet Vehicles or Single Vehicle Tracking Beacon */}
        {vehicles && vehicles.length > 0 ? (
          displayedVehicles.map((v) => {
            const isSelected = v.id === (selectedVehicle?.id || vehicles[0].id);
            const pos = toScreen(v.currentCoords.lat, v.currentCoords.lng);
            const isHazard = v.status === 'HAZARD_SLOWED';
            const isCheckpoint = v.status === 'HALTED_CHECKPOINT';
            const isConvoy = v.status === 'CONVOY_ESCORT';
            const statusColor = isHazard
              ? '#EF4444'
              : isCheckpoint
              ? '#F59E0B'
              : isConvoy
              ? '#818CF8'
              : '#10B981';

            return (
              <g
                key={v.id}
                data-testid={`fleet-marker-${v.id}`}
                transform={`translate(${pos.x}, ${pos.y})`}
                style={{ cursor: 'pointer' }}
                onClick={(e) => {
                  e.stopPropagation();
                  onSelectVehicle?.(v);
                }}
              >
                {/* Radar sweep glow for selected or moving vehicles */}
                {isSelected && (
                  <>
                    <circle r="30" fill="url(#radarSweep)" />
                    <circle
                      r="18"
                      fill="#38BDF8"
                      fillOpacity="0.25"
                      stroke="#38BDF8"
                      strokeWidth="1.5"
                      strokeDasharray="4 2"
                    />
                  </>
                )}

                {/* Subtle warning ring for hazard delayed units */}
                {isHazard && (
                  <circle
                    r="15"
                    fill="#EF4444"
                    fillOpacity="0.18"
                    stroke="#EF4444"
                    strokeWidth="1"
                    strokeDasharray="3 2"
                  />
                )}

                {/* Outer Halo */}
                <circle
                  r={isSelected ? 10 : 7.5}
                  fill={statusColor}
                  fillOpacity="0.35"
                  stroke={statusColor}
                  strokeWidth="1.5"
                />

                {/* Core Center Dot */}
                <circle
                  r={isSelected ? 5 : 4}
                  fill={isSelected ? '#38BDF8' : '#FFFFFF'}
                  stroke="#0F172A"
                  strokeWidth="1.2"
                />

                {/* Minimalist Floating Pill Label */}
                <rect
                  x={isSelected ? -48 : -36}
                  y={isSelected ? -32 : -24}
                  width={isSelected ? 96 : 72}
                  height={isSelected ? 20 : 16}
                  rx="5"
                  fill="rgba(255, 255, 255, 0.96)"
                  stroke={isSelected ? '#0284C7' : statusColor}
                  strokeWidth={isSelected ? 1.5 : 1}
                />
                <text
                  x="0"
                  y={isSelected ? -18 : -13}
                  fill={isSelected ? '#0284C7' : '#0F172A'}
                  fontSize={isSelected ? '9' : '7.5'}
                  fontWeight="800"
                  textAnchor="middle"
                >
                  {isHazard ? '⚠️ ' : ''}{v.vehicleNumber} · {v.speedKmh}k
                </text>
              </g>
            );
          })
        ) : (
          <g transform={`translate(${vehicleX}, ${vehicleY})`}>
            <circle r="26" fill="url(#radarSweep)" />
            <circle r="14" fill="#38BDF8" fillOpacity="0.3" />
            <circle r="7" fill="#0284C7" stroke="#FFFFFF" strokeWidth="2" />
            <rect x="10" y="-12" width="62" height="16" rx="4" fill="#FFFFFF" stroke="#0284C7" strokeWidth="1" />
            <text x="41" y="-1" fill="#0284C7" fontSize="8" fontWeight="800" textAnchor="middle">
              {currentSpeedKmh} KM/H
            </text>
          </g>
        )}

        {/* Animated Single Vehicle Route Beacon (Shown when focusing a selected route) */}
        {vehicles && vehicles.length > 0 && viewMode === 'selected' && (
          <g transform={`translate(${vehicleX}, ${vehicleY})`}>
            <circle r="20" fill="url(#radarSweep)" />
            <circle r="10" fill="#38BDF8" fillOpacity="0.35" />
            <circle r="5.5" fill="#0284C7" stroke="#FFFFFF" strokeWidth="1.5" />
          </g>
        )}
      </svg>

      {/* TOP-CENTER VIEW MODE SEGMENTED CONTROL */}
      {vehicles && vehicles.length > 0 && (
        <div
          data-testid="fleet-view-mode-toggle"
          style={{
            position: 'absolute',
            top: '12px',
            left: '50%',
            transform: 'translateX(-50%)',
            display: 'flex',
            alignItems: 'center',
            padding: '3px',
            borderRadius: 'var(--radius-pill)',
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(16px)',
            border: '1px solid #CBD5E1',
            boxShadow: '0 2px 10px rgba(0, 0, 0, 0.08)',
            zIndex: 15,
          }}
        >
          <button
            type="button"
            data-testid="view-mode-selected"
            onClick={() => handleViewModeChange('selected')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '5px 12px',
              borderRadius: 'var(--radius-pill)',
              border: 'none',
              backgroundColor: viewMode === 'selected' ? '#0284C7' : 'transparent',
              color: viewMode === 'selected' ? '#FFFFFF' : '#64748B',
              fontSize: '11px',
              fontWeight: viewMode === 'selected' ? 700 : 500,
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
          >
            <span>🎯 Focused Route: {selectedVehicle ? `${selectedVehicle.model} (${selectedVehicle.vehicleNumber})` : 'Unit'}</span>
          </button>
          <button
            type="button"
            data-testid="view-mode-all"
            onClick={() => handleViewModeChange('all')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '5px 12px',
              borderRadius: 'var(--radius-pill)',
              border: 'none',
              backgroundColor: viewMode === 'all' ? '#0284C7' : 'transparent',
              color: viewMode === 'all' ? '#FFFFFF' : '#64748B',
              fontSize: '11px',
              fontWeight: viewMode === 'all' ? 700 : 500,
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
          >
            <span>🌐 All Locations Only ({vehicles.length})</span>
          </button>
        </div>
      )}

      {/* TOP-LEFT TELEMETRY HUD */}
      {viewMode === 'all' && vehicles && vehicles.length > 0 ? (
        /* ALL FLEET LOCATIONS MINIMAL HUD */
        <div
          data-testid="fleet-all-locations-hud"
          style={{
            position: 'absolute',
            top: '12px',
            left: '12px',
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(16px)',
            border: '1px solid #CBD5E1',
            borderRadius: '12px',
            padding: '10px 14px',
            color: '#0F172A',
            fontSize: '12px',
            boxShadow: '0 4px 16px rgba(0,0,0,0.08)',
            display: 'flex',
            flexDirection: 'column',
            gap: '6px',
            maxWidth: '320px',
            zIndex: 10,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span
              style={{
                width: '7px',
                height: '7px',
                borderRadius: '50%',
                backgroundColor: '#0284C7',
                boxShadow: '0 0 8px rgba(2, 132, 199, 0.5)',
              }}
            />
            <strong style={{ fontSize: '13px', color: '#0F172A', letterSpacing: '0.02em' }}>
              All Fleet Locations
            </strong>
            <span
              style={{
                fontSize: '10px',
                fontWeight: 800,
                padding: '2px 7px',
                borderRadius: 'var(--radius-pill)',
                backgroundColor: '#E0F2FE',
                color: '#0284C7',
                marginLeft: 'auto',
              }}
            >
              {vehicles.length} UNITS
            </span>
          </div>

          <div style={{ fontSize: '11px', color: '#64748B', display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            <span style={{ color: '#059669', fontWeight: 600 }}>
              ● {vehicles.filter((v) => v.status === 'IN_TRANSIT').length} Moving
            </span>
            <span style={{ color: '#DC2626', fontWeight: 600 }}>
              ● {vehicles.filter((v) => v.status === 'HAZARD_SLOWED').length} Hazard
            </span>
            <span style={{ color: '#D97706', fontWeight: 600 }}>
              ● {vehicles.filter((v) => v.status === 'HALTED_CHECKPOINT').length} Checkpoint
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '2px' }}>
            <button
              type="button"
              onClick={() => handleViewModeChange('selected')}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px',
                backgroundColor: '#E0F2FE',
                border: '1px solid #BAE6FD',
                borderRadius: 'var(--radius-pill)',
                color: '#0284C7',
                fontSize: '10px',
                fontWeight: 700,
                padding: '3px 10px',
                cursor: 'pointer',
              }}
            >
              <span>Track {selectedVehicle ? `${selectedVehicle.model} (${selectedVehicle.vehicleNumber})` : 'Unit'} Route</span>
            </button>
            <span style={{ fontSize: '10px', color: '#94A3B8' }}>
              Click any pin to inspect
            </span>
          </div>
        </div>
      ) : (
        /* SELECTED VEHICLE FOCUSED HUD */
        <div
          style={{
            position: 'absolute',
            top: '12px',
            left: '12px',
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(12px)',
            border: '1px solid #CBD5E1',
            borderRadius: 'var(--radius-sm)',
            padding: '10px 14px',
            color: '#0F172A',
            fontSize: '12px',
            boxShadow: '0 4px 16px rgba(0,0,0,0.08)',
            display: 'flex',
            flexDirection: 'column',
            gap: '4px',
            maxWidth: '300px',
            zIndex: 10,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span
              style={{
                width: '6px',
                height: '6px',
                borderRadius: '50%',
                backgroundColor: '#10B981',
                boxShadow: '0 0 6px #10B981',
              }}
            />
            <strong style={{ fontSize: '13px', color: '#0F172A' }}>
              {originName.split(' ')[0]} → {destName.split(' ')[0]}
            </strong>
            <span
              style={{
                fontSize: '9px',
                fontWeight: 800,
                padding: '1px 5px',
                borderRadius: '3px',
                backgroundColor: '#E0F2FE',
                color: '#0284C7',
                marginLeft: 'auto',
                whiteSpace: 'nowrap',
              }}
            >
              {selectedVehicle ? selectedVehicle.vehicleNumber : roleMode.toUpperCase()}
            </span>
          </div>

          <div style={{ fontSize: '11px', color: '#64748B' }}>
            Corridor: <span style={{ color: '#0F172A', fontWeight: 600 }}>{routeName}</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '2px' }}>
            <span style={{ color: '#0284C7', fontWeight: 800, fontSize: '13px' }}>
              {breakdown.estimatedEtaText}
            </span>
            <span style={{ color: '#94A3B8' }}>·</span>
            <span style={{ color: '#334155', fontWeight: 600 }}>
              {remainingDistanceKm} km left
            </span>
            <span style={{ color: '#94A3B8' }}>·</span>
            <span style={{ color: '#059669', fontWeight: 700 }}>
              {totalDistanceKm} km total
            </span>
          </div>

          {/* Clauses Button Chip & Identity */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '4px' }}>
            <button
              type="button"
              onClick={handleOpenAudit}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
                backgroundColor: '#F0F9FF',
                border: '1px solid #BAE6FD',
                borderRadius: 'var(--radius-pill)',
                color: '#0284C7',
                fontSize: '10px',
                fontWeight: 700,
                padding: '2px 8px',
                cursor: 'pointer',
              }}
            >
              <Scale size={11} />
              <span>Clauses Audit (+{(totalDistanceKm - breakdown.baseAerialKm).toFixed(1)} km)</span>
            </button>

            <span
              style={{
                fontSize: '10px',
                color: '#475569',
                backgroundColor: '#F1F5F9',
                border: '1px solid #E2E8F0',
                padding: '2px 6px',
                borderRadius: '4px',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap',
                maxWidth: '110px',
              }}
              title={vehicleName}
            >
              {vehicleName.split(' ')[0]}
            </span>
          </div>
        </div>
      )}

      {/* TOP-RIGHT MAP CONTROLS */}
      {showControls && (
        <div
          style={{
            position: 'absolute',
            top: '12px',
            right: '12px',
            display: 'flex',
            flexDirection: 'column',
            gap: '6px',
            zIndex: 10,
          }}
        >
          <button
            type="button"
            onClick={handleZoomIn}
            title="Zoom In"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              backgroundColor: '#FFFFFF',
              border: '1px solid #CBD5E1',
              color: '#0F172A',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
            }}
          >
            <Plus size={16} />
          </button>

          <button
            type="button"
            onClick={handleZoomOut}
            title="Zoom Out"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              backgroundColor: '#FFFFFF',
              border: '1px solid #CBD5E1',
              color: '#0F172A',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
            }}
          >
            <Minus size={16} />
          </button>

          <button
            type="button"
            onClick={handleReset}
            title="Reset True North & Fit Corridor"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              backgroundColor: '#FFFFFF',
              border: '1px solid #CBD5E1',
              color: '#0284C7',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
            }}
          >
            <Compass size={16} />
          </button>

          {/* Map Layer Switcher Button */}
          <button
            type="button"
            data-testid="map-layers-toggle-btn"
            onClick={() => setIsLayerMenuOpen((prev) => !prev)}
            title="Map Views & Details (Satellite, Road, Terrain, Alerts, Incidents)"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              backgroundColor: isLayerMenuOpen || mapType !== 'road' ? '#0284C7' : '#FFFFFF',
              border: isLayerMenuOpen || mapType !== 'road' ? '1px solid #0284C7' : '1px solid #CBD5E1',
              color: isLayerMenuOpen || mapType !== 'road' ? '#FFFFFF' : '#0F172A',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.08)',
            }}
          >
            <Layers size={16} />
          </button>
        </div>
      )}

      {/* GOOGLE MAPS STYLE LAYER SELECTION SHEET / POPUP */}
      {isLayerMenuOpen && (
        <div
          data-testid="map-layers-popup"
          style={{
            position: 'absolute',
            top: '12px',
            right: '52px',
            width: '290px',
            backgroundColor: '#FFFFFF',
            borderRadius: '16px',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 8px 10px -6px rgba(0, 0, 0, 0.2)',
            border: '1px solid #E2E8F0',
            padding: '16px',
            zIndex: 60,
            color: '#0F172A',
            animation: 'fadeIn 0.15s ease-out',
          }}
        >
          {/* Header */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <span style={{ fontSize: '15px', fontWeight: 700, color: '#1E293B' }}>Map type</span>
            <button
              type="button"
              onClick={() => setIsLayerMenuOpen(false)}
              aria-label="Close"
              style={{
                background: 'transparent',
                border: 'none',
                cursor: 'pointer',
                color: '#64748B',
                padding: '4px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <X size={18} />
            </button>
          </div>

          {/* 3 Map Types: Default (Road), Satellite, Terrain */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px', marginBottom: '16px' }}>
            {/* Road View / Default */}
            <div
              data-testid="layer-type-road"
              onClick={() => setMapType('road')}
              style={{ cursor: 'pointer', textAlign: 'center' }}
            >
              <div
                style={{
                  height: '66px',
                  borderRadius: '14px',
                  backgroundColor: '#E0F2FE',
                  border: mapType === 'road' ? '2.5px solid #16A34A' : '1px solid #E2E8F0',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  position: 'relative',
                  boxShadow: mapType === 'road' ? '0 0 0 2px rgba(22, 163, 74, 0.25)' : 'none',
                }}
              >
                <MapIcon size={28} color="#0284C7" />
                {mapType === 'road' && (
                  <div
                    style={{
                      position: 'absolute',
                      top: '5px',
                      right: '5px',
                      width: '16px',
                      height: '16px',
                      borderRadius: '50%',
                      backgroundColor: '#16A34A',
                      color: '#FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Check size={10} strokeWidth={3} />
                  </div>
                )}
              </div>
              <span
                style={{
                  fontSize: '11px',
                  fontWeight: mapType === 'road' ? 700 : 500,
                  color: mapType === 'road' ? '#16A34A' : '#475569',
                  marginTop: '5px',
                  display: 'block',
                }}
              >
                Default
              </span>
            </div>

            {/* Satellite View */}
            <div
              data-testid="layer-type-satellite"
              onClick={() => setMapType('satellite')}
              style={{ cursor: 'pointer', textAlign: 'center' }}
            >
              <div
                style={{
                  height: '66px',
                  borderRadius: '14px',
                  backgroundColor: '#1E293B',
                  border: mapType === 'satellite' ? '2.5px solid #16A34A' : '1px solid #E2E8F0',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  position: 'relative',
                  boxShadow: mapType === 'satellite' ? '0 0 0 2px rgba(22, 163, 74, 0.25)' : 'none',
                }}
              >
                <SatelliteIcon size={28} color="#38BDF8" />
                {mapType === 'satellite' && (
                  <div
                    style={{
                      position: 'absolute',
                      top: '5px',
                      right: '5px',
                      width: '16px',
                      height: '16px',
                      borderRadius: '50%',
                      backgroundColor: '#16A34A',
                      color: '#FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Check size={10} strokeWidth={3} />
                  </div>
                )}
              </div>
              <span
                style={{
                  fontSize: '11px',
                  fontWeight: mapType === 'satellite' ? 700 : 500,
                  color: mapType === 'satellite' ? '#16A34A' : '#475569',
                  marginTop: '5px',
                  display: 'block',
                }}
              >
                Satellite
              </span>
            </div>

            {/* Terrain View */}
            <div
              data-testid="layer-type-terrain"
              onClick={() => setMapType('terrain')}
              style={{ cursor: 'pointer', textAlign: 'center' }}
            >
              <div
                style={{
                  height: '66px',
                  borderRadius: '14px',
                  backgroundColor: '#E2E8D5',
                  border: mapType === 'terrain' ? '2.5px solid #16A34A' : '1px solid #E2E8F0',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  position: 'relative',
                  boxShadow: mapType === 'terrain' ? '0 0 0 2px rgba(22, 163, 74, 0.25)' : 'none',
                }}
              >
                <Mountain size={28} color="#4D7C0F" />
                {mapType === 'terrain' && (
                  <div
                    style={{
                      position: 'absolute',
                      top: '5px',
                      right: '5px',
                      width: '16px',
                      height: '16px',
                      borderRadius: '50%',
                      backgroundColor: '#16A34A',
                      color: '#FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Check size={10} strokeWidth={3} />
                  </div>
                )}
              </div>
              <span
                style={{
                  fontSize: '11px',
                  fontWeight: mapType === 'terrain' ? 700 : 500,
                  color: mapType === 'terrain' ? '#16A34A' : '#475569',
                  marginTop: '5px',
                  display: 'block',
                }}
              >
                Terrain
              </span>
            </div>
          </div>

          <div style={{ height: '1px', backgroundColor: '#E2E8F0', margin: '14px 0' }} />

          {/* Map Details Section */}
          <div style={{ marginBottom: '10px' }}>
            <span style={{ fontSize: '14px', fontWeight: 700, color: '#1E293B' }}>Map details</span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {/* Alerts Toggle */}
            <div
              data-testid="layer-detail-alerts"
              onClick={() => setShowAlerts((prev) => !prev)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '10px 12px',
                borderRadius: '10px',
                backgroundColor: showAlerts ? 'rgba(245, 158, 11, 0.08)' : '#F8FAFC',
                border: showAlerts ? '1.5px solid #F59E0B' : '1px solid #E2E8F0',
                cursor: 'pointer',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div
                  style={{
                    padding: '6px',
                    borderRadius: '50%',
                    backgroundColor: showAlerts ? 'rgba(245, 158, 11, 0.2)' : '#E2E8F0',
                  }}
                >
                  <AlertTriangle size={16} color={showAlerts ? '#D97706' : '#64748B'} />
                </div>
                <div>
                  <div style={{ fontSize: '12px', fontWeight: 700, color: showAlerts ? '#92400E' : '#334155' }}>
                    Alerts
                  </div>
                  <div style={{ fontSize: '10px', color: '#64748B' }}>Corridor hazards</div>
                </div>
              </div>
              <div
                style={{
                  width: '18px',
                  height: '18px',
                  borderRadius: '50%',
                  border: showAlerts ? 'none' : '2px solid #CBD5E1',
                  backgroundColor: showAlerts ? '#F59E0B' : 'transparent',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#FFFFFF',
                }}
              >
                {showAlerts && <Check size={12} strokeWidth={3} />}
              </div>
            </div>

            {/* Incidents Toggle */}
            <div
              data-testid="layer-detail-incidents"
              onClick={() => setShowIncidents((prev) => !prev)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '10px 12px',
                borderRadius: '10px',
                backgroundColor: showIncidents ? 'rgba(239, 68, 68, 0.08)' : '#F8FAFC',
                border: showIncidents ? '1.5px solid #EF4444' : '1px solid #E2E8F0',
                cursor: 'pointer',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div
                  style={{
                    padding: '6px',
                    borderRadius: '50%',
                    backgroundColor: showIncidents ? 'rgba(239, 68, 68, 0.2)' : '#E2E8F0',
                  }}
                >
                  <AlertCircle size={16} color={showIncidents ? '#DC2626' : '#64748B'} />
                </div>
                <div>
                  <div style={{ fontSize: '12px', fontWeight: 700, color: showIncidents ? '#991B1B' : '#334155' }}>
                    Incidents
                  </div>
                  <div style={{ fontSize: '10px', color: '#64748B' }}>Field reports</div>
                </div>
              </div>
              <div
                style={{
                  width: '18px',
                  height: '18px',
                  borderRadius: '50%',
                  border: showIncidents ? 'none' : '2px solid #CBD5E1',
                  backgroundColor: showIncidents ? '#EF4444' : 'transparent',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#FFFFFF',
                }}
              >
                {showIncidents && <Check size={12} strokeWidth={3} />}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* BOTTOM-LEFT GIS SCALE BAR */}
      <div
        style={{
          position: 'absolute',
          bottom: '10px',
          left: '12px',
          backgroundColor: 'rgba(255, 255, 255, 0.94)',
          padding: '4px 8px',
          borderRadius: '4px',
          border: '1px solid #CBD5E1',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: '2px',
          boxShadow: '0 2px 6px rgba(0,0,0,0.06)',
          zIndex: 10,
        }}
      >
        <div style={{ width: '80px', height: '3px', backgroundColor: '#0284C7' }} />
        <span style={{ fontSize: '9px', color: '#334155', fontWeight: 700 }}>
          {scaleBarKm > 0 ? `${scaleBarKm} km` : '25 km'} · Open GIS
        </span>
      </div>

      {/* BOTTOM-RIGHT LEGEND */}
      <div
        style={{
          position: 'absolute',
          bottom: '10px',
          right: '12px',
          backgroundColor: 'rgba(255, 255, 255, 0.94)',
          padding: '6px 10px',
          borderRadius: '6px',
          border: '1px solid #CBD5E1',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          fontSize: '11px',
          color: '#334155',
          boxShadow: '0 2px 6px rgba(0,0,0,0.06)',
          zIndex: 10,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
          <span style={{ width: '10px', height: '3px', backgroundColor: '#0284C7' }} />
          <span style={{ fontWeight: 600 }}>Safest Route</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
          <span style={{ width: '10px', height: '3px', backgroundColor: '#F59E0B' }} />
          <span style={{ fontWeight: 600 }}>Faster Bypass</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
          <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#EF4444' }} />
          <span style={{ fontWeight: 600 }}>Active Hazard</span>
        </div>
      </div>

      {/* Embedded Distance Clauses Audit Modal */}
      <DistanceClausesModal
        isOpen={isClausesModalOpen}
        onClose={() => setIsClausesModalOpen(false)}
        breakdown={breakdown}
        originName={originName}
        destName={destName}
        vehicleName={vehicleName}
        cargoName={cargoName}
        routeName={routeName}
      />
    </div>
  );
};
