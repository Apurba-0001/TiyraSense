import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Route as RouteIcon,
  Shield,
  AlertTriangle,
  AlertOctagon,
  RefreshCw,
  Download,
  TrendingDown,
  TrendingUp,
  CheckCircle,
  Navigation,
  Search,
  FileText,
  Users,
  Settings,
  Truck,
  MapPin,
  Phone,
  Gauge,
  Server,
  Bell,
  HardDrive,
  Eye,
  X,
  Camera,
  ZoomIn,
} from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { VectorGisMap, FleetVehicle } from '../components/VectorGisMap';
import { DistanceClausesModal } from '../components/DistanceClausesModal';
import { computeDetailedBreakdown, DistanceBreakdown } from '../utils/distanceUtils';
import { JourneyPlanningModal } from '../components/JourneyPlanningModal';
import {
  fetchCorridors,
  fetchAlerts,
  acknowledgeAlert,
  fetchActiveJourneys,
  fetchRegionalWeather,
  fetchFieldReports,
  getAssetUrl,
  WebFieldReport,
  RegionalWeatherObservation,
} from '../services/api';

interface CorridorRow {
  id: string;
  name: string;
  routeId: string;
  status: 'PASSABLE' | 'CAUTION' | 'HIGH RISK' | 'BLOCKED';
  riskScore: number;
  disruptionProb: number;
  lastReport: string;
}

interface LiveAlert {
  id: string;
  severity: 'EMERGENCY' | 'CAUTION' | 'INFO';
  corridor: string;
  time: string;
  title: string;
  description: string;
  acknowledged: boolean;
}

const INITIAL_FLEET_VEHICLES: FleetVehicle[] = [
  {
    id: 'TRK-01',
    vehicleNumber: 'AS-01-GC-4921',
    model: 'Tata Prima 31T Heavy Hauler',
    driverName: 'Rajeshwar Sharma',
    driverPhone: '+91 94350-29184',
    role: 'DRIVER',
    cargo: 'FMCG Critical & Essential Dry Goods',
    originName: 'Guwahati Port Hub',
    destName: 'Shillong Terminal Hub',
    originCoords: { lat: 26.1445, lng: 91.7362 },
    destCoords: { lat: 25.5788, lng: 91.8933 },
    routeName: 'NH-06 via Nongpoh',
    currentCoords: { lat: 25.8617, lng: 91.8148 },
    speedKmh: 42,
    progress: 0.52,
    status: 'IN_TRANSIT',
    lastPing: '12s ago',
    hazardAhead: 'KM 52 Landslide boulder roll-down (Speed restricted to 25 km/h)',
  },
  {
    id: 'TRK-02',
    vehicleNumber: 'AS-09-C-8812',
    model: 'BharatBenz 2823R Multi-Axle',
    driverName: 'Bikramjit Gogoi',
    driverPhone: '+91 98540-31049',
    role: 'DRIVER',
    cargo: 'Pharmaceuticals & Vaccines (Cold-Chain)',
    originName: 'Nagaon Logistics Depot',
    destName: 'Silchar Supply Terminal',
    originCoords: { lat: 26.3465, lng: 92.6840 },
    destCoords: { lat: 24.8333, lng: 92.7789 },
    routeName: 'NH-29 via Dabaka & Silchar Pass',
    currentCoords: { lat: 25.4200, lng: 92.7100 },
    speedKmh: 31,
    progress: 0.61,
    status: 'HAZARD_SLOWED',
    lastPing: '28s ago',
    hazardAhead: 'KM 81-86 Flash Flood & Shoulder Waterlogging',
  },
  {
    id: 'TRK-03',
    vehicleNumber: 'NL-01-A-3409',
    model: 'Ashok Leyland 1618 EcoTruck',
    driverName: 'Kevichüsa Angami',
    driverPhone: '+91 94360-11245',
    role: 'DRIVER',
    cargo: 'Relief Grain & Rice Bags',
    originName: 'Dimapur Rail Yard',
    destName: 'Kohima South Depot',
    originCoords: { lat: 25.9068, lng: 93.7275 },
    destCoords: { lat: 25.6751, lng: 94.1086 },
    routeName: 'NH-29 Dimapur-Kohima Pass',
    currentCoords: { lat: 25.7900, lng: 93.9100 },
    speedKmh: 28,
    progress: 0.44,
    status: 'IN_TRANSIT',
    lastPing: '5s ago',
  },
  {
    id: 'MED-04',
    vehicleNumber: 'ML-05-F-2018',
    model: 'Mahindra Bolero Camper 4x4',
    driverName: 'Sanborlang Lyngdoh',
    driverPhone: '+91 87940-54211',
    role: 'FIELD_WORKER',
    cargo: 'Emergency First Responder & Mobile Clinic',
    originName: 'Paikan Base',
    destName: 'Tura Civil Hospital',
    originCoords: { lat: 25.9500, lng: 90.5800 },
    destCoords: { lat: 25.5144, lng: 90.2033 },
    routeName: 'NH-51 Paikan-Tura Highway',
    currentCoords: { lat: 25.7200, lng: 90.3900 },
    speedKmh: 48,
    progress: 0.70,
    status: 'CONVOY_ESCORT',
    lastPing: '14s ago',
  },
  {
    id: 'RECON-05',
    vehicleNumber: 'TR-01-T-7740',
    model: 'Force Gurkha 4x4 Recon Patrol',
    driverName: 'Debabrata Debbarma',
    driverPhone: '+91 97740-88123',
    role: 'FIELD_WORKER',
    cargo: 'Geotechnical Acoustic Sensor & LIDAR Kit',
    originName: 'Jorabat Patrol Post',
    destName: 'Ladrymbai Outpost',
    originCoords: { lat: 26.1100, lng: 91.8700 },
    destCoords: { lat: 25.3200, lng: 92.3500 },
    routeName: 'NH-40 Jorabat-Ladrymbai Ridge',
    currentCoords: { lat: 25.4800, lng: 92.2000 },
    speedKmh: 0,
    progress: 0.82,
    status: 'HALTED_CHECKPOINT',
    lastPing: '40s ago',
    hazardAhead: 'Structure 14B Acoustic Checkpoint Inspection',
  },
];

export const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const role = user?.role || 'OFFICIAL';
  const [corridors, setCorridors] = useState<CorridorRow[]>([]);
  const [alerts, setAlerts] = useState<LiveAlert[]>([]);
  const [fleetVehicles, setFleetVehicles] = useState<FleetVehicle[]>(INITIAL_FLEET_VEHICLES);
  const [selectedVehicleId, setSelectedVehicleId] = useState<string>('TRK-01');
  const [filterVehicleType, setFilterVehicleType] = useState<string>('ALL');
  const [filterCargoType, setFilterCargoType] = useState<string>('ALL');
  const [filterOpMode, setFilterOpMode] = useState<string>('ALL');
  const [vehicleSearchQuery, setVehicleSearchQuery] = useState<string>('');
  const [mapFleetViewMode, setMapFleetViewMode] = useState<'selected' | 'all'>('selected');
  const [weatherObs, setWeatherObs] = useState<RegionalWeatherObservation[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isJourneyModalOpen, setIsJourneyModalOpen] = useState(false);
  const [corridorQuery, setCorridorQuery] = useState('');
  const [isAuditModalOpen, setIsAuditModalOpen] = useState(false);
  const [auditBreakdown, setAuditBreakdown] = useState<DistanceBreakdown | null>(null);
  const [fieldReports, setFieldReports] = useState<WebFieldReport[]>([]);
  const [dashboardLightbox, setDashboardLightbox] = useState<string | null>(null);

  const filteredVehicles = React.useMemo(() => {
    return fleetVehicles.filter((veh) => {
      // 1. Text Search
      if (vehicleSearchQuery.trim()) {
        const q = vehicleSearchQuery.toLowerCase();
        const match =
          veh.id.toLowerCase().includes(q) ||
          veh.vehicleNumber.toLowerCase().includes(q) ||
          veh.model.toLowerCase().includes(q) ||
          veh.driverName.toLowerCase().includes(q) ||
          veh.cargo.toLowerCase().includes(q) ||
          veh.routeName.toLowerCase().includes(q) ||
          (veh.driverPhone && veh.driverPhone.toLowerCase().includes(q));
        if (!match) return false;
      }

      // 2. Vehicle Type
      if (filterVehicleType !== 'ALL') {
        const m = veh.model.toLowerCase();
        if (filterVehicleType === 'HEAVY') {
          const isHeavy =
            m.includes('heavy') ||
            m.includes('31t') ||
            m.includes('2823') ||
            m.includes('hauler') ||
            m.includes('multi-axle') ||
            m.includes('3528') ||
            m.includes('tata prima') ||
            m.includes('bharatbenz');
          if (!isHeavy) return false;
        } else if (filterVehicleType === 'MEDIUM') {
          const isMed =
            m.includes('medium') ||
            m.includes('1618') ||
            m.includes('ecotruck') ||
            m.includes('ashok leyland');
          if (!isMed) return false;
        } else if (filterVehicleType === 'LIGHT_4X4') {
          const is4x4 =
            m.includes('4x4') ||
            m.includes('gurkha') ||
            m.includes('recon') ||
            m.includes('camper') ||
            m.includes('bolero') ||
            m.includes('force');
          if (!is4x4) return false;
        } else if (filterVehicleType === 'EMERGENCY') {
          const isEmerg =
            m.includes('clinic') ||
            m.includes('medic') ||
            veh.cargo.toLowerCase().includes('clinic') ||
            veh.cargo.toLowerCase().includes('emergency');
          if (!isEmerg) return false;
        }
      }

      // 3. Cargo Type
      if (filterCargoType !== 'ALL') {
        const c = veh.cargo.toLowerCase();
        if (filterCargoType === 'DRY_GOODS') {
          if (!c.includes('fmcg') && !c.includes('dry') && !c.includes('goods')) return false;
        } else if (filterCargoType === 'PHARMA') {
          if (!c.includes('pharma') && !c.includes('vaccine') && !c.includes('cold-chain')) return false;
        } else if (filterCargoType === 'RELIEF') {
          if (!c.includes('relief') && !c.includes('grain') && !c.includes('rice') && !c.includes('food')) return false;
        } else if (filterCargoType === 'MEDICAL') {
          if (!c.includes('clinic') && !c.includes('first responder') && !c.includes('medical')) return false;
        } else if (filterCargoType === 'SENSORS') {
          if (!c.includes('sensor') && !c.includes('lidar') && !c.includes('acoustic')) return false;
        }
      }

      // 4. Operational Mode (Hazard Delayed / Stopped, In Transit, Checkpoint, Convoy)
      if (filterOpMode !== 'ALL') {
        if (filterOpMode === 'IN_TRANSIT' && veh.status !== 'IN_TRANSIT') return false;
        if (filterOpMode === 'HAZARD_SLOWED' && veh.status !== 'HAZARD_SLOWED') return false;
        if (filterOpMode === 'HALTED_CHECKPOINT' && veh.status !== 'HALTED_CHECKPOINT') return false;
        if (filterOpMode === 'CONVOY_ESCORT' && veh.status !== 'CONVOY_ESCORT') return false;
      }

      return true;
    });
  }, [fleetVehicles, vehicleSearchQuery, filterVehicleType, filterCargoType, filterOpMode]);

  // Keep selected vehicle synced if filtered list changes
  useEffect(() => {
    if (filteredVehicles.length > 0 && !filteredVehicles.some((v) => v.id === selectedVehicleId)) {
      setSelectedVehicleId(filteredVehicles[0].id);
    }
  }, [filteredVehicles, selectedVehicleId]);

  const loadDashboardData = async () => {
    setIsRefreshing(true);
    try {
      const [corridorRes, alertRes, journeysRes, weatherRes, reportsRes] = await Promise.allSettled([
        fetchCorridors(),
        fetchAlerts(),
        fetchActiveJourneys(),
        fetchRegionalWeather(),
        fetchFieldReports(),
      ]);

      if (reportsRes.status === 'fulfilled' && reportsRes.value.length > 0) {
        setFieldReports(reportsRes.value);
      }

      if (corridorRes.status === 'fulfilled' && corridorRes.value.length > 0) {
        setCorridors(
          corridorRes.value.map((c) => ({
            id: c.id,
            name: c.name,
            routeId: c.route_id,
            status: (c.status as CorridorRow['status']) || 'PASSABLE',
            riskScore: c.risk_score,
            disruptionProb: c.disruption_prob,
            lastReport: c.last_report || 'Active Radar',
          }))
        );
      }

      if (alertRes.status === 'fulfilled' && alertRes.value.length > 0) {
        setAlerts(
          alertRes.value.map((a) => ({
            id: a.id,
            severity: (a.severity as LiveAlert['severity']) || 'INFO',
            corridor: a.corridor,
            time: a.time,
            title: a.title,
            description: a.description,
            acknowledged: Boolean(a.acknowledged),
          }))
        );
      }

      if (journeysRes.status === 'fulfilled' && journeysRes.value.length > 0) {
        const liveVehicles: FleetVehicle[] = journeysRes.value.map((j, idx) => {
          const regMatch = j.driver_name.match(/\(([^)]+)\)/);
          const regNumber = j.vehicle_number || (regMatch ? regMatch[1] : `AS-0${idx + 1}-NER`);
          const rawModel = j.vehicle_name || (j.driver_name.includes('(') ? j.driver_name.split(' (')[0] : 'Logistics Carrier');
          const actualDriver = j.vehicle_name ? j.driver_name : (j.driver_name.replace(/\s*\([^)]*\)/, '') || 'Assigned Driver');
          const isCaution = j.status.includes('CAUTION') || j.status.includes('SLOW') || j.status.includes('STANDBY');

          const origLat = j.origin_coords?.latitude ?? 26.1445;
          const origLng = j.origin_coords?.longitude ?? 91.7362;
          const destLat = j.destination_coords?.latitude ?? 25.5788;
          const destLng = j.destination_coords?.longitude ?? 91.8933;
          const curLat = j.current_location?.latitude ?? origLat;
          const curLng = j.current_location?.longitude ?? origLng;

          let calculatedProgress = 0.52 + (idx * 0.1);
          const totalSpan = Math.hypot(destLat - origLat, destLng - origLng);
          const coveredSpan = Math.hypot(curLat - origLat, curLng - origLng);
          if (totalSpan > 0.005) {
            calculatedProgress = Math.min(0.98, Math.max(0.02, coveredSpan / totalSpan));
          }

          return {
            id: j.journey_id,
            vehicleNumber: regNumber,
            model: rawModel,
            driverName: actualDriver,
            driverPhone: j.driver_phone || '+91 94350-29184',
            role: 'DRIVER' as const,
            cargo: j.route_name || 'Emergency & Freight Logistics',
            originName: j.origin_name || 'Origin Hub',
            destName: j.destination_name || 'Destination Terminal',
            originCoords: { lat: origLat, lng: origLng },
            destCoords: { lat: destLat, lng: destLng },
            routeName: j.route_name || 'Monitored Corridor',
            currentCoords: { lat: curLat, lng: curLng },
            speedKmh: j.speed_kmh ?? (j.status === 'STANDBY_HALTED' ? 0 : 42),
            progress: calculatedProgress,
            status: isCaution ? 'HAZARD_SLOWED' : 'IN_TRANSIT',
            lastPing: j.last_ping_mins_ago === 0 ? 'Live radar' : `${j.last_ping_mins_ago}m ago`,
            hazardAhead: isCaution ? 'Terrain advisory / Caution alert active in sector' : undefined,
            routeGeometry: j.route_geometry,
          };
        });

        setFleetVehicles(liveVehicles);
        if (liveVehicles.length > 0) {
          const liveActive = liveVehicles.find((v) => v.lastPing === 'Live radar');
          setSelectedVehicleId((prev) => (liveVehicles.some((v) => v.id === prev) ? prev : (liveActive?.id || liveVehicles[0].id)));
        }
      }

      if (weatherRes.status === 'fulfilled' && weatherRes.value.length > 0) {
        setWeatherObs(weatherRes.value);
      }
    } catch {
      // Fallback preserves baseline resilience
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
    const interval = setInterval(() => {
      fetchActiveJourneys()
        .then((journeys) => {
          if (journeys && journeys.length > 0) {
            setFleetVehicles((prevFleet) => {
              return journeys.map((j, idx) => {
                const regMatch = j.driver_name.match(/\(([^)]+)\)/);
                const regNumber = j.vehicle_number || (regMatch ? regMatch[1] : `AS-0${idx + 1}-NER`);
                const rawModel = j.vehicle_name || (j.driver_name.includes('(') ? j.driver_name.split(' (')[0] : 'Logistics Carrier');
                const actualDriver = j.vehicle_name ? j.driver_name : (j.driver_name.replace(/\s*\([^)]*\)/, '') || 'Assigned Driver');
                const isCaution = j.status.includes('CAUTION') || j.status.includes('SLOW') || j.status.includes('STANDBY');

                const origLat = j.origin_coords?.latitude ?? 26.1445;
                const origLng = j.origin_coords?.longitude ?? 91.7362;
                const destLat = j.destination_coords?.latitude ?? 25.5788;
                const destLng = j.destination_coords?.longitude ?? 91.8933;
                const curLat = j.current_location?.latitude ?? origLat;
                const curLng = j.current_location?.longitude ?? origLng;

                const existing = prevFleet.find((f) => f.id === j.journey_id);

                let calculatedProgress = existing?.progress ?? (0.52 + (idx * 0.1));
                const totalSpan = Math.hypot(destLat - origLat, destLng - origLng);
                const coveredSpan = Math.hypot(curLat - origLat, curLng - origLng);
                if (totalSpan > 0.005) {
                  calculatedProgress = Math.min(0.98, Math.max(0.02, coveredSpan / totalSpan));
                }

                return {
                  id: j.journey_id,
                  vehicleNumber: regNumber,
                  model: rawModel,
                  driverName: actualDriver,
                  driverPhone: j.driver_phone || existing?.driverPhone || '+91 94350-29184',
                  role: 'DRIVER' as const,
                  cargo: j.route_name || existing?.cargo || 'Emergency & Freight Logistics',
                  originName: j.origin_name || existing?.originName || 'Origin Hub',
                  destName: j.destination_name || existing?.destName || 'Destination Terminal',
                  originCoords: { lat: origLat, lng: origLng },
                  destCoords: { lat: destLat, lng: destLng },
                  routeName: j.route_name || existing?.routeName || 'Monitored Corridor',
                  currentCoords: { lat: curLat, lng: curLng },
                  speedKmh: j.speed_kmh ?? (j.status === 'STANDBY_HALTED' ? 0 : 42),
                  progress: calculatedProgress,
                  status: isCaution ? 'HAZARD_SLOWED' : 'IN_TRANSIT',
                  lastPing: j.last_ping_mins_ago === 0 ? 'Live radar' : `${j.last_ping_mins_ago}m ago`,
                  hazardAhead: isCaution ? 'Terrain advisory / Caution alert active in sector' : undefined,
                  routeGeometry: j.route_geometry || existing?.routeGeometry,
                };
              });
            });
          }
        })
        .catch(() => {});
    }, 3500);

    const reportsInterval = setInterval(() => {
      fetchFieldReports()
        .then((reps) => {
          if (reps && reps.length > 0) setFieldReports(reps);
        })
        .catch(() => {});
    }, 8000);

    const onOnline = () => loadDashboardData();
    const onFocus = () => loadDashboardData();
    window.addEventListener('online', onOnline);
    window.addEventListener('focus', onFocus);

    return () => {
      clearInterval(interval);
      clearInterval(reportsInterval);
      window.removeEventListener('online', onOnline);
      window.removeEventListener('focus', onFocus);
    };
  }, []);

  const displayedCorridors = corridors.filter(
    (c) =>
      !corridorQuery.trim() ||
      c.name.toLowerCase().includes(corridorQuery.toLowerCase()) ||
      c.routeId.toLowerCase().includes(corridorQuery.toLowerCase())
  );

  const handleRefresh = () => {
    loadDashboardData();
  };

  const handleAcknowledge = async (id: string) => {
    setAlerts((prev) =>
      prev.map((alt) => (alt.id === id ? { ...alt, acknowledged: !alt.acknowledged } : alt))
    );
    try {
      await acknowledgeAlert(id);
    } catch {
      // Optimistic update retained
    }
  };

  const handleExportSituationalReport = () => {
    const headers = ['Corridor_ID', 'Corridor_Name', 'Route', 'Status', 'Risk_Score', 'Disruption_Prob_Percent', 'Last_Observation'];
    const rows = corridors.map((c) => [
      c.id,
      `"${c.name}"`,
      `"${c.routeId}"`,
      c.status,
      c.riskScore,
      `${c.disruptionProb}%`,
      `"${c.lastReport}"`,
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `TiyraSense_Situational_Summary_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const renderStatusBadge = (status: CorridorRow['status']) => {
    let dotColor = 'var(--color-success)';
    let bgColor = 'var(--color-success-bg)';
    let textColor = 'var(--color-success)';

    if (status === 'CAUTION') {
      dotColor = 'var(--color-warning)';
      bgColor = 'var(--color-warning-bg)';
      textColor = '#D97706';
    } else if (status === 'HIGH RISK') {
      dotColor = 'var(--color-danger)';
      bgColor = 'var(--color-danger-bg)';
      textColor = 'var(--color-danger)';
    } else if (status === 'BLOCKED') {
      dotColor = 'var(--color-emergency)';
      bgColor = 'var(--color-danger-bg)';
      textColor = 'var(--color-emergency)';
    }

    return (
      <span
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '5px',
          padding: '4px 9px',
          borderRadius: 'var(--radius-pill)',
          backgroundColor: bgColor,
          color: textColor,
          fontSize: '11px',
          fontWeight: 600,
          whiteSpace: 'nowrap',
        }}
      >
        <span
          style={{
            width: '6px',
            height: '6px',
            borderRadius: '50%',
            backgroundColor: dotColor,
          }}
        />
        {status}
      </span>
    );
  };

  return (
    <div style={{ maxWidth: '1440px', margin: '0 auto', display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* PAGE HEADER */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <h1
            style={{
              fontSize: '22px',
              fontWeight: 800,
              color: 'var(--color-text-primary)',
              lineHeight: 1.3,
            }}
          >
            Operations Overview
          </h1>
          <div
            style={{
              fontSize: '12px',
              color: 'var(--color-text-muted)',
              marginTop: '4px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <span>NER Logistics Intelligence</span>
            <span>·</span>
            <span>8 Corridors Monitored</span>
            <span>·</span>
            <span
              style={{
                backgroundColor: 'var(--color-success-bg)',
                color: 'var(--color-success)',
                fontWeight: 700,
                fontSize: '10px',
                padding: '1px 6px',
                borderRadius: '4px',
              }}
            >
              DATA: LIVE
            </span>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <button
            onClick={() => setIsJourneyModalOpen(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              height: '36px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--color-primary)',
              color: '#FFFFFF',
              fontSize: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              border: 'none',
              boxShadow: 'var(--card-shadow)',
              transition: 'opacity var(--transition-fast)',
            }}
          >
            <Navigation size={14} />
            <span>Plan Journey</span>
          </button>

          <button
            onClick={handleExportSituationalReport}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              height: '36px',
              padding: '0 12px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: '#FFFFFF',
              color: 'var(--color-text-secondary)',
              fontSize: '12px',
              fontWeight: 600,
              transition: 'all var(--transition-fast)',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.borderColor = 'var(--color-primary)';
              e.currentTarget.style.color = 'var(--color-primary)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.borderColor = 'var(--color-border)';
              e.currentTarget.style.color = 'var(--color-text-secondary)';
            }}
          >
            <Download size={14} />
            <span>Export Report</span>
          </button>

          {role === 'ADMIN' && (
            <button
              data-testid="admin-storage-btn"
              onClick={() => navigate('/settings?tab=storage')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                height: '36px',
                padding: '0 12px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid #BFDBFE',
                backgroundColor: '#EFF6FF',
                color: '#1D4ED8',
                fontSize: '12px',
                fontWeight: 600,
                cursor: 'pointer',
                transition: 'all var(--transition-fast)',
              }}
              title="Manage Cloud Evidence Storage & Purge Assets"
            >
              <HardDrive size={14} />
              <span>Storage & Evidence</span>
            </button>
          )}

          <button
            onClick={handleRefresh}
            aria-label="Refresh Dashboard"
            style={{
              width: '36px',
              height: '36px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: '#FFFFFF',
              color: 'var(--color-text-secondary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'all var(--transition-fast)',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.borderColor = 'var(--color-primary)';
              e.currentTarget.style.color = 'var(--color-primary)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.borderColor = 'var(--color-border)';
              e.currentTarget.style.color = 'var(--color-text-secondary)';
            }}
          >
            <RefreshCw
              size={14}
              style={{
                transform: isRefreshing ? 'rotate(180deg)' : 'none',
                transition: 'transform 0.5s ease',
              }}
            />
          </button>
        </div>
      </div>

      {/* LIVE EXTERNAL TELEMETRY RIBBON (Open-Meteo & Live Supabase Stream) */}
      {weatherObs.length > 0 && (
        <div
          data-testid="live-telemetry-ribbon"
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '12px',
            padding: '10px 16px',
            backgroundColor: 'rgba(255, 255, 255, 0.85)',
            backdropFilter: 'blur(8px)',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)',
            boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px',
                padding: '2px 8px',
                borderRadius: 'var(--radius-pill)',
                backgroundColor: 'rgba(34, 197, 94, 0.12)',
                color: '#16A34A',
                fontSize: '11px',
                fontWeight: 700,
              }}
            >
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#16A34A' }} />
              LIVE TELEMETRY
            </span>
            <span style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)' }}>
              Open-Meteo High-Resolution Atmospheric Radar (ECMWF / GFS)
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', overflowX: 'auto', maxWidth: '100%' }}>
            {weatherObs.slice(0, 4).map((w, i) => (
              <div
                key={i}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  fontSize: '12px',
                  whiteSpace: 'nowrap',
                }}
              >
                <span style={{ fontWeight: 700, color: 'var(--color-text-primary)' }}>
                  {w.hub.split(' (')[0]}:
                </span>
                <span style={{ color: 'var(--color-primary)', fontWeight: 600 }}>
                  {w.temperature_c}°C
                </span>
                <span
                  style={{
                    fontSize: '11px',
                    color: w.weather_penalty_factor > 1.2 ? '#DC2626' : 'var(--color-text-muted)',
                    fontWeight: w.weather_penalty_factor > 1.2 ? 700 : 400,
                  }}
                >
                  ({w.condition}{w.precipitation_mm > 0 ? ` · ${w.precipitation_mm}mm/h` : ''})
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ROW 1 — 4 EQUAL KPI CARDS (16px gap, white, 12px radius, 20px padding) */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: '16px',
        }}
      >
        {/* Card A */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                backgroundColor: 'var(--color-success-bg)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <RouteIcon size={20} color="var(--color-success)" />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)', lineHeight: 1.1 }}>
                8 / 8
              </div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
                Corridors Active
              </div>
            </div>
          </div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-success)', display: 'flex', alignItems: 'center', gap: '3px' }}>
            <TrendingUp size={13} />
            <span>+0 since 06:00</span>
          </div>
        </div>

        {/* Card B */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                backgroundColor: 'var(--color-primary-bg)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Shield size={20} color="var(--color-primary)" />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)', lineHeight: 1.1 }}>
                14
              </div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
                Field Teams Online
              </div>
            </div>
          </div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: '3px' }}>
            <TrendingUp size={13} />
            <span>3 synced in last 1h</span>
          </div>
        </div>

        {/* Card C */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                backgroundColor: 'var(--color-warning-bg)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <AlertTriangle size={20} color="var(--color-warning)" />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-warning)', lineHeight: 1.1 }}>
                3
              </div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
                Open Incidents
              </div>
            </div>
          </div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-warning)', display: 'flex', alignItems: 'center', gap: '3px' }}>
            <TrendingDown size={13} />
            <span>1 resolved today</span>
          </div>
        </div>

        {/* Card D */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                backgroundColor: 'var(--color-danger-bg)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <AlertOctagon size={20} color="var(--color-danger)" />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-danger)', lineHeight: 1.1 }}>
                1
              </div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
                Emergency Alerts
              </div>
            </div>
          </div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-danger)' }}>
            NH-06 KM 52
          </div>
        </div>
      </div>

      {/* ROLE-BASED OPERATIONAL HUB & LIVE GIS TELEMETRY */}
      <div
        className="tiyra-card"
        style={{
          padding: '20px',
          borderLeft: `4px solid ${
            role === 'DRIVER'
              ? '#0284C7'
              : role === 'FIELD_WORKER'
              ? '#10B981'
              : role === 'ADMIN'
              ? '#7C3AED'
              : '#D97706'
          }`,
        }}
      >
        {/* Role Banner */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '16px',
            flexWrap: 'wrap',
            gap: '12px',
          }}
        >
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span
                style={{
                  fontSize: '10px',
                  fontWeight: 800,
                  padding: '2px 8px',
                  borderRadius: 'var(--radius-pill)',
                  backgroundColor:
                    role === 'DRIVER'
                      ? 'var(--color-primary-bg)'
                      : role === 'FIELD_WORKER'
                      ? 'var(--color-success-bg)'
                      : role === 'ADMIN'
                      ? '#EDE9FE'
                      : '#FEF3C7',
                  color:
                    role === 'DRIVER'
                      ? 'var(--color-primary)'
                      : role === 'FIELD_WORKER'
                      ? 'var(--color-success)'
                      : role === 'ADMIN'
                      ? '#6D28D9'
                      : '#B45309',
                }}
              >
                ROLE: {role}
              </span>
              <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
                {role === 'DRIVER' && `Driver Console · ${user?.full_name || 'Vehicle Unit 04'}`}
                {role === 'FIELD_WORKER' && `Ground Truth Station · ${user?.full_name || 'Ground Unit'}`}
                {role === 'OFFICIAL' && `NER Logistics Operations Console · ${user?.full_name || 'Coordinator'}`}
                {role === 'ADMIN' && `System Administration Console · ${user?.full_name || 'Administrator'}`}
              </h2>
            </div>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '3px' }}>
              {role === 'DRIVER' && 'Live GPS beacon telemetry, mountain curvature distance clauses, and active corridor hazard routing.'}
              {role === 'FIELD_WORKER' && `Sector verification: ${user?.organization || 'ASDMA / BRO Regional Patrol'} · Geo-tagged incident logging.`}
              {role === 'OFFICIAL' && 'Multi-corridor fleet transit oversight, deterministic risk-weighted routing, and emergency coordination.'}
              {role === 'ADMIN' && 'Regional infrastructure telemetry, model calibration, user access control, and master logs.'}
            </p>
          </div>

          {/* Quick Action Buttons according to role */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            {role === 'DRIVER' && (
              <>
                <button
                  type="button"
                  onClick={() => setIsJourneyModalOpen(true)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-primary)',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Navigation size={14} />
                  <span>Plan Journey</span>
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/reports')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#FEF2F2',
                    border: '1px solid #FECACA',
                    color: '#DC2626',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <AlertTriangle size={14} />
                  <span>Report Road Hazard</span>
                </button>
              </>
            )}

            {role === 'FIELD_WORKER' && (
              <>
                <button
                  type="button"
                  onClick={() => navigate('/reports')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-success)',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <FileText size={14} />
                  <span>Submit Field Report</span>
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/alerts')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#FFFBEB',
                    border: '1px solid #FDE68A',
                    color: '#D97706',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <AlertTriangle size={14} />
                  <span>View Alerts Feed</span>
                </button>
              </>
            )}

            {role === 'OFFICIAL' && (
              <>
                <button
                  type="button"
                  data-testid="official-trigger-alert-btn"
                  onClick={() => navigate('/alerts')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-danger)',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: 'var(--card-shadow)',
                  }}
                >
                  <Bell size={14} />
                  <span>Trigger Corridor Alert</span>
                </button>
                <button
                  type="button"
                  data-testid="official-verify-reports-btn"
                  onClick={() => navigate('/reports')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-primary)',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: 'var(--card-shadow)',
                  }}
                >
                  <CheckCircle size={14} />
                  <span>Review & Verify Reports</span>
                </button>
                <button
                  type="button"
                  data-testid="official-plan-journey-btn"
                  onClick={() => setIsJourneyModalOpen(true)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#F8FAFC',
                    border: '1px solid var(--color-border)',
                    color: 'var(--color-text-primary)',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Navigation size={14} />
                  <span>Plan Safe Route</span>
                </button>
              </>
            )}

            {role === 'ADMIN' && (
              <>
                <button
                  type="button"
                  data-testid="admin-manage-users-btn"
                  onClick={() => navigate('/users')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#7C3AED',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: 'var(--card-shadow)',
                  }}
                >
                  <Users size={14} />
                  <span>User Management</span>
                </button>
                <button
                  type="button"
                  data-testid="admin-data-sources-btn"
                  onClick={() => navigate('/settings')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#0D9488',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    boxShadow: 'var(--card-shadow)',
                  }}
                >
                  <Server size={14} />
                  <span>Data Source Health</span>
                </button>
                <button
                  type="button"
                  data-testid="admin-system-settings-btn"
                  onClick={() => navigate('/settings')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#F3F4F6',
                    border: '1px solid #E5E7EB',
                    color: '#374151',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Settings size={14} />
                  <span>System Governance & Logs</span>
                </button>
                <button
                  type="button"
                  data-testid="admin-storage-btn"
                  onClick={() => navigate('/settings?tab=storage')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#EFF6FF',
                    border: '1px solid #BFDBFE',
                    color: '#2563EB',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <HardDrive size={14} />
                  <span>Cloud Storage & Evidence</span>
                </button>
              </>
            )}

            <button
              type="button"
              onClick={() => navigate('/corridors')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 14px',
                borderRadius: 'var(--radius-sm)',
                backgroundColor: '#FFFFFF',
                border: '1px solid var(--color-border)',
                color: 'var(--color-text-secondary)',
                fontSize: '12px',
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              <RouteIcon size={14} />
              <span>Corridor Details</span>
            </button>
          </div>
        </div>

        {/* For Admin: System Health & Data Source Governance Console */}
        {role === 'ADMIN' && (
          <div
            data-testid="admin-system-health-console"
            style={{
              backgroundColor: '#111827',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid #374151',
              padding: '16px 18px',
              marginBottom: '10px',
              color: '#F9FAFB',
            }}
          >
            {/* Header */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '10px',
                marginBottom: '14px',
                borderBottom: '1px solid #1F2937',
                paddingBottom: '10px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Server size={18} color="#A78BFA" />
                <span style={{ fontSize: '14px', fontWeight: 800, color: '#F3F4F6' }}>
                  System Health & Data Source Diagnostics Console
                </span>
                <span
                  style={{
                    fontSize: '10px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: 'rgba(167, 139, 250, 0.15)',
                    color: '#C4B5FD',
                    border: '1px solid rgba(167, 139, 250, 0.3)',
                  }}
                >
                  ADMIN GOVERNANCE · ALL SYSTEMS NOMINAL
                </span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <button
                  type="button"
                  data-testid="dashboard-manage-users-shortcut"
                  onClick={() => navigate('/users')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '5px',
                    padding: '5px 10px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#7C3AED',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '11px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Users size={12} />
                  <span>Manage Users (8)</span>
                </button>
                <button
                  type="button"
                  data-testid="dashboard-full-diagnostics-shortcut"
                  onClick={() => navigate('/settings')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '5px',
                    padding: '5px 10px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: '#374151',
                    color: '#E5E7EB',
                    border: '1px solid #4B5563',
                    fontSize: '11px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Settings size={12} />
                  <span>Full Diagnostics & Logs</span>
                </button>
              </div>
            </div>

            {/* Grid of 4 Core Data Sources & System KPIs */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
                gap: '12px',
              }}
            >
              {/* PostGIS Database */}
              <div
                style={{
                  backgroundColor: '#1F2937',
                  borderRadius: 'var(--radius-sm)',
                  padding: '12px 14px',
                  border: '1px solid #374151',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: '#9CA3AF' }}>POSTGIS DATABASE</span>
                  <span style={{ fontSize: '10px', fontWeight: 700, color: '#34D399', backgroundColor: 'rgba(16,185,129,0.15)', padding: '1px 6px', borderRadius: '4px' }}>
                    CONNECTED
                  </span>
                </div>
                <div style={{ fontSize: '15px', fontWeight: 800, color: '#F9FAFB' }}>12ms Latency</div>
                <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '3px' }}>Connection Pool: 8/20 · Spatial ST_DWithin Active</div>
              </div>

              {/* OSRM Routing Engine */}
              <div
                style={{
                  backgroundColor: '#1F2937',
                  borderRadius: 'var(--radius-sm)',
                  padding: '12px 14px',
                  border: '1px solid #374151',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: '#9CA3AF' }}>OSRM ROUTING ENGINE</span>
                  <span style={{ fontSize: '10px', fontWeight: 700, color: '#38BDF8', backgroundColor: 'rgba(56,189,248,0.15)', padding: '1px 6px', borderRadius: '4px' }}>
                    OPERATIONAL
                  </span>
                </div>
                <div style={{ fontSize: '15px', fontWeight: 800, color: '#F9FAFB' }}>24ms Latency</div>
                <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '3px' }}>NER Mountain Topography Graph · IRC:SP:48 Clauses</div>
              </div>

              {/* IMD Weather Stream */}
              <div
                style={{
                  backgroundColor: '#1F2937',
                  borderRadius: 'var(--radius-sm)',
                  padding: '12px 14px',
                  border: '1px solid #374151',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: '#9CA3AF' }}>WEATHER & RADAR FEED</span>
                  <span style={{ fontSize: '10px', fontWeight: 700, color: '#34D399', backgroundColor: 'rgba(16,185,129,0.15)', padding: '1px 6px', borderRadius: '4px' }}>
                    LIVE STREAM
                  </span>
                </div>
                <div style={{ fontSize: '15px', fontWeight: 800, color: '#F9FAFB' }}>45ms Latency</div>
                <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '3px' }}>IMD Doppler Uplink · 5-min Polling Active</div>
              </div>

              {/* App Health & Uptime */}
              <div
                style={{
                  backgroundColor: '#1F2937',
                  borderRadius: 'var(--radius-sm)',
                  padding: '12px 14px',
                  border: '1px solid #374151',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: '#9CA3AF' }}>APP UPTIME & HEALTH</span>
                  <span style={{ fontSize: '10px', fontWeight: 700, color: '#A78BFA', backgroundColor: 'rgba(167,139,250,0.15)', padding: '1px 6px', borderRadius: '4px' }}>
                    99.94% UPTIME
                  </span>
                </div>
                <div style={{ fontSize: '15px', fontWeight: 800, color: '#F9FAFB' }}>0.02% Error Rate</div>
                <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '3px' }}>14 Active Sessions · 0 Sync Conflicts</div>
              </div>
            </div>
          </div>
        )}

        {/* For Official & Admin: Live Fleet Location Tracking & Telemetry Console */}
        {(role === 'OFFICIAL' || role === 'ADMIN') && (
          <div
            data-testid="fleet-tracking-console"
            style={{
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              padding: '14px 16px',
              marginBottom: '10px',
              color: '#0F172A',
              boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
            }}
          >
            {/* Console Header & View Mode Switch */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '12px',
                marginBottom: '14px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span
                  style={{
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    backgroundColor: '#10B981',
                    boxShadow: '0 0 8px #10B981',
                  }}
                />
                <span style={{ fontSize: '14px', fontWeight: 800, letterSpacing: '0.02em', color: '#0F172A' }}>
                  NER Fleet Live Location Tracking & Telemetry Console
                </span>
                <span
                  style={{
                    fontSize: '10px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: '#F0F9FF',
                    color: '#0284C7',
                    border: '1px solid #BAE6FD',
                  }}
                >
                  LIVE GPS FEED · {fleetVehicles.length} ACTIVE UNITS
                </span>
              </div>

              {/* View Mode Segmented Switch on Console */}
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  padding: '3px',
                  borderRadius: 'var(--radius-pill)',
                  backgroundColor: '#F1F5F9',
                  border: '1px solid #CBD5E1',
                  gap: '4px',
                }}
              >
                <button
                  type="button"
                  data-testid="console-view-mode-selected"
                  onClick={() => setMapFleetViewMode('selected')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '4px 10px',
                    borderRadius: 'var(--radius-pill)',
                    border: 'none',
                    backgroundColor: mapFleetViewMode === 'selected' ? '#0284C7' : 'transparent',
                    color: mapFleetViewMode === 'selected' ? '#FFFFFF' : '#64748B',
                    fontSize: '11px',
                    fontWeight: mapFleetViewMode === 'selected' ? 700 : 500,
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <Navigation size={11} />
                  <span>Selected Route Track</span>
                </button>
                <button
                  type="button"
                  data-testid="console-view-mode-all"
                  onClick={() => setMapFleetViewMode('all')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '4px 10px',
                    borderRadius: 'var(--radius-pill)',
                    border: 'none',
                    backgroundColor: mapFleetViewMode === 'all' ? '#0284C7' : 'transparent',
                    color: mapFleetViewMode === 'all' ? '#FFFFFF' : '#64748B',
                    fontSize: '11px',
                    fontWeight: mapFleetViewMode === 'all' ? 700 : 500,
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <Eye size={11} />
                  <span>All Locations Only</span>
                </button>
              </div>
            </div>

            {/* MINIMAL & MODERN MULTI-ASPECT FLEET FILTER TOOLBAR */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '10px',
                padding: '10px 12px',
                marginBottom: '12px',
                borderRadius: '8px',
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0',
              }}
            >
              {/* Search input */}
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  height: '32px',
                  padding: '0 8px',
                  borderRadius: '6px',
                  backgroundColor: '#FFFFFF',
                  border: '1px solid #CBD5E1',
                  minWidth: '200px',
                  flex: '1 1 200px',
                }}
              >
                <Search size={13} color="#64748B" />
                <input
                  type="text"
                  data-testid="fleet-search-input"
                  placeholder="Search vehicle, driver, cargo..."
                  value={vehicleSearchQuery}
                  onChange={(e) => setVehicleSearchQuery(e.target.value)}
                  style={{
                    border: 'none',
                    outline: 'none',
                    backgroundColor: 'transparent',
                    color: '#0F172A',
                    fontSize: '12px',
                    width: '100%',
                  }}
                />
                {vehicleSearchQuery && (
                  <button
                    type="button"
                    onClick={() => setVehicleSearchQuery('')}
                    style={{ background: 'none', border: 'none', color: '#64748B', cursor: 'pointer', padding: 0 }}
                  >
                    <X size={12} />
                  </button>
                )}
              </div>

              {/* Vehicle Type Filter */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '11px', color: '#475569', whiteSpace: 'nowrap' }}>Type:</span>
                <select
                  data-testid="filter-vehicle-type"
                  value={filterVehicleType}
                  onChange={(e) => setFilterVehicleType(e.target.value)}
                  style={{
                    height: '32px',
                    padding: '0 8px',
                    borderRadius: '6px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #CBD5E1',
                    color: '#0F172A',
                    fontSize: '11px',
                    fontWeight: 600,
                    outline: 'none',
                    cursor: 'pointer',
                  }}
                >
                  <option value="ALL">All Vehicle Types</option>
                  <option value="HEAVY">Heavy Haulers / Multi-Axle</option>
                  <option value="MEDIUM">Medium Logistics (EcoTruck)</option>
                  <option value="LIGHT_4X4">Light 4x4 / Recon Camper</option>
                  <option value="EMERGENCY">Emergency / Mobile Clinic</option>
                </select>
              </div>

              {/* Cargo Type Filter */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '11px', color: '#475569', whiteSpace: 'nowrap' }}>Cargo:</span>
                <select
                  data-testid="filter-cargo-type"
                  value={filterCargoType}
                  onChange={(e) => setFilterCargoType(e.target.value)}
                  style={{
                    height: '32px',
                    padding: '0 8px',
                    borderRadius: '6px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #CBD5E1',
                    color: '#0F172A',
                    fontSize: '11px',
                    fontWeight: 600,
                    outline: 'none',
                    cursor: 'pointer',
                  }}
                >
                  <option value="ALL">All Cargo Types</option>
                  <option value="DRY_GOODS">FMCG & Critical Dry Goods</option>
                  <option value="PHARMA">Pharmaceuticals & Cold-Chain</option>
                  <option value="RELIEF">Relief Grain & Food Supply</option>
                  <option value="MEDICAL">Medical Clinic Responder</option>
                  <option value="SENSORS">Geotechnical LIDAR & Sensors</option>
                </select>
              </div>

              {/* Operational Mode Filter */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '11px', color: '#475569', whiteSpace: 'nowrap' }}>Mode:</span>
                <select
                  data-testid="filter-op-mode"
                  value={filterOpMode}
                  onChange={(e) => setFilterOpMode(e.target.value)}
                  style={{
                    height: '32px',
                    padding: '0 8px',
                    borderRadius: '6px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #CBD5E1',
                    color: '#0F172A',
                    fontSize: '11px',
                    fontWeight: 600,
                    outline: 'none',
                    cursor: 'pointer',
                  }}
                >
                  <option value="ALL">All Operational Modes</option>
                  <option value="IN_TRANSIT">In Transit (Moving)</option>
                  <option value="HAZARD_SLOWED">⚠️ Stopped / Hazard Delayed</option>
                  <option value="HALTED_CHECKPOINT">⏸️ Halted at Checkpoint</option>
                  <option value="CONVOY_ESCORT">🛡️ Convoy Escort</option>
                </select>
              </div>

              {/* Reset Filters & Match count */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginLeft: 'auto' }}>
                <span
                  style={{
                    fontSize: '11px',
                    color: '#0284C7',
                    fontWeight: 700,
                    backgroundColor: '#E0F2FE',
                    padding: '3px 8px',
                    borderRadius: '4px',
                  }}
                >
                  {filteredVehicles.length} of {fleetVehicles.length} units
                </span>

                {(filterVehicleType !== 'ALL' || filterCargoType !== 'ALL' || filterOpMode !== 'ALL' || vehicleSearchQuery) && (
                  <button
                    type="button"
                    data-testid="clear-fleet-filters"
                    onClick={() => {
                      setFilterVehicleType('ALL');
                      setFilterCargoType('ALL');
                      setFilterOpMode('ALL');
                      setVehicleSearchQuery('');
                    }}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '4px',
                      padding: '4px 8px',
                      borderRadius: '4px',
                      backgroundColor: '#FEF2F2',
                      border: '1px solid #FECACA',
                      color: '#DC2626',
                      fontSize: '11px',
                      fontWeight: 600,
                      cursor: 'pointer',
                    }}
                  >
                    <X size={12} />
                    <span>Reset</span>
                  </button>
                )}
              </div>
            </div>

            {/* Fleet Unit Selector Bar */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                overflowX: 'auto',
                paddingBottom: '6px',
                marginBottom: '12px',
              }}
            >
              {filteredVehicles.length === 0 ? (
                <div style={{ padding: '10px 14px', color: '#64748B', fontSize: '12px', width: '100%', textAlign: 'center' }}>
                  No fleet vehicles match active filter.
                </div>
              ) : (
                filteredVehicles.map((veh) => {
                  const isSelected = veh.id === selectedVehicleId;
                  const statusDotColor =
                    veh.status === 'HAZARD_SLOWED'
                      ? '#EF4444'
                      : veh.status === 'HALTED_CHECKPOINT'
                      ? '#F59E0B'
                      : veh.status === 'CONVOY_ESCORT'
                      ? '#6366F1'
                      : '#10B981';

                  return (
                    <button
                      key={veh.id}
                      type="button"
                      onClick={() => setSelectedVehicleId(veh.id)}
                      data-testid={`select-vehicle-${veh.id}`}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        padding: '8px 12px',
                        borderRadius: 'var(--radius-sm)',
                        backgroundColor: isSelected ? '#F0F9FF' : '#F8FAFC',
                        border: isSelected ? '1.5px solid #0284C7' : '1px solid #E2E8F0',
                        color: isSelected ? '#0284C7' : '#475569',
                        cursor: 'pointer',
                        fontSize: '12px',
                        fontWeight: isSelected ? 700 : 500,
                        whiteSpace: 'nowrap',
                        transition: 'all 0.15s ease',
                        boxShadow: isSelected ? '0 0 8px rgba(2, 132, 199, 0.15)' : 'none',
                      }}
                    >
                      <span
                        style={{
                          width: '7px',
                          height: '7px',
                          borderRadius: '50%',
                          backgroundColor: statusDotColor,
                          boxShadow: `0 0 6px ${statusDotColor}`,
                        }}
                      />
                      <Truck size={14} color={isSelected ? '#0284C7' : '#64748B'} />
                      <span style={{ color: isSelected ? '#0284C7' : '#0F172A', fontWeight: 700 }}>{veh.model}</span>
                      <span
                        style={{
                          fontSize: '11px',
                          color: '#475569',
                          fontWeight: 600,
                          backgroundColor: isSelected ? '#E0F2FE' : '#F1F5F9',
                          padding: '1px 6px',
                          borderRadius: '4px',
                        }}
                      >
                        {veh.vehicleNumber}
                      </span>
                      <span
                        style={{
                          fontSize: '10px',
                          padding: '1px 5px',
                          borderRadius: '3px',
                          backgroundColor: isSelected ? '#E0F2FE' : '#E2E8F0',
                          color: isSelected ? '#0284C7' : '#334155',
                          fontWeight: 700,
                        }}
                      >
                        {veh.speedKmh} km/h
                      </span>
                      {veh.status === 'HAZARD_SLOWED' && (
                        <span
                          style={{
                            fontSize: '9px',
                            fontWeight: 800,
                            padding: '1px 4px',
                            borderRadius: '3px',
                            backgroundColor: '#FEE2E2',
                            color: '#DC2626',
                          }}
                        >
                          ⚠️ HAZARD
                        </span>
                      )}
                    </button>
                  );
                })
              )}
            </div>

            {/* Selected Vehicle Telemetry Inspector Card */}
            {(() => {
              const cur = fleetVehicles.find((v) => v.id === selectedVehicleId) || fleetVehicles[0];
              if (!cur) {
                return (
                  <div
                    data-testid="vehicle-telemetry-inspector"
                    style={{
                      backgroundColor: '#F8FAFC',
                      border: '1px solid #E2E8F0',
                      borderRadius: 'var(--radius-sm)',
                      padding: '16px',
                      color: 'var(--color-text-muted)',
                      fontSize: '12px',
                      textAlign: 'center',
                    }}
                  >
                    No active fleet telemetry signals available.
                  </div>
                );
              }
              const statusBadgeBg =
                cur.status === 'HAZARD_SLOWED'
                  ? '#FEE2E2'
                  : cur.status === 'HALTED_CHECKPOINT'
                  ? '#FEF3C7'
                  : cur.status === 'CONVOY_ESCORT'
                  ? '#E0E7FF'
                  : '#D1FAE5';
              const statusBadgeColor =
                cur.status === 'HAZARD_SLOWED'
                  ? '#DC2626'
                  : cur.status === 'HALTED_CHECKPOINT'
                  ? '#D97706'
                  : cur.status === 'CONVOY_ESCORT'
                  ? '#4F46E5'
                  : '#059669';

              return (
                <div
                  data-testid="vehicle-telemetry-inspector"
                  style={{
                    backgroundColor: '#F8FAFC',
                    border: '1px solid #E2E8F0',
                    borderRadius: 'var(--radius-sm)',
                    padding: '12px 14px',
                  }}
                >
                  <div
                    style={{
                      display: 'grid',
                      gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
                      gap: '12px',
                    }}
                  >
                    {/* Col 1: Vehicle & Driver Identity */}
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontSize: '14px', fontWeight: 800, color: '#0F172A' }}>
                          {cur.model}
                        </span>
                        <span
                          style={{
                            fontSize: '11px',
                            fontWeight: 700,
                            padding: '1px 6px',
                            borderRadius: '3px',
                            backgroundColor: '#E2E8F0',
                            color: '#334155',
                          }}
                        >
                          {cur.vehicleNumber}
                        </span>
                      </div>
                      <div
                        style={{
                          fontSize: '11px',
                          color: '#64748B',
                          marginTop: '4px',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px',
                        }}
                      >
                        <Phone size={11} />
                        <span>
                          Driver: <strong style={{ color: '#0F172A' }}>{cur.driverName}</strong> ({cur.driverPhone})
                        </span>
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                        Cargo: <strong style={{ color: '#0F172A' }}>{cur.cargo}</strong>
                      </div>
                    </div>

                    {/* Col 2: GPS Location & Corridor Landmark */}
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <MapPin size={13} color="#0284C7" />
                        <span style={{ fontSize: '12px', fontWeight: 700, color: '#0284C7' }}>
                          Live Location: {cur.currentCoords.lat.toFixed(4)}°N, {cur.currentCoords.lng.toFixed(4)}°E
                        </span>
                      </div>
                      <div style={{ fontSize: '11px', color: '#334155', marginTop: '4px' }}>
                        Corridor: <strong>{cur.routeName}</strong>
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                        Route: {cur.originName} → {cur.destName}
                      </div>
                    </div>

                    {/* Col 3: Telemetry Dynamics */}
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span
                          style={{
                            fontSize: '10px',
                            fontWeight: 800,
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-pill)',
                            backgroundColor: statusBadgeBg,
                            color: statusBadgeColor,
                            border: `1px solid ${statusBadgeColor}`,
                          }}
                        >
                          {cur.status.replace('_', ' ')}
                        </span>
                        <span style={{ fontSize: '12px', fontWeight: 700, color: '#0F172A' }}>
                          <Gauge size={12} style={{ display: 'inline', marginRight: '4px' }} />
                          {cur.speedKmh} km/h
                        </span>
                        <span style={{ fontSize: '10px', color: '#64748B', marginLeft: 'auto' }}>
                          Ping {cur.lastPing}
                        </span>
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748B', marginTop: '6px' }}>
                        Transit Progress: <strong style={{ color: '#0284C7' }}>{Math.round(cur.progress * 100)}%</strong> completed
                      </div>
                      {cur.hazardAhead && (
                        <div
                          style={{
                            fontSize: '11px',
                            color: '#DC2626',
                            backgroundColor: '#FEF2F2',
                            padding: '3px 6px',
                            borderRadius: '4px',
                            marginTop: '4px',
                            border: '1px solid #FECACA',
                          }}
                        >
                          ⚠️ Hazard Ahead: {cur.hazardAhead}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })()}
          </div>
        )}

        {/* Embedded Vector GIS Spatial Tracking */}
        <div style={{ marginTop: '8px' }}>
          {(() => {
            const currentVeh = fleetVehicles.find((v) => v.id === selectedVehicleId) || fleetVehicles[0];
            const isFleetMode = (role === 'OFFICIAL' || role === 'ADMIN') && !!currentVeh;

            return (
              <VectorGisMap
                originName={isFleetMode ? currentVeh.originName : 'Guwahati Port Hub'}
                destName={isFleetMode ? currentVeh.destName : 'Shillong Terminal Hub'}
                originCoords={isFleetMode ? currentVeh.originCoords : { lat: 26.1445, lng: 91.7362 }}
                destCoords={isFleetMode ? currentVeh.destCoords : { lat: 25.5788, lng: 91.8933 }}
                routeName={isFleetMode ? currentVeh.routeName : 'NH-06 via Nongpoh'}
                vehicleName={
                  isFleetMode ? currentVeh.model : role === 'DRIVER' ? 'Tata Prima 31T' : 'Ashok Leyland 1618'
                }
                cargoName={isFleetMode ? currentVeh.cargo : 'FMCG Critical'}
                roleMode={
                  role === 'DRIVER' ? 'driver' : role === 'FIELD_WORKER' ? 'field_worker' : role === 'ADMIN' ? 'admin' : 'official'
                }
                height={isFleetMode ? 440 : 360}
                vehicles={isFleetMode ? filteredVehicles : undefined}
                selectedVehicleId={selectedVehicleId}
                onSelectVehicle={(veh) => setSelectedVehicleId(veh.id)}
                fleetViewMode={mapFleetViewMode}
                onFleetViewModeChange={(m) => setMapFleetViewMode(m)}
                onOpenClauses={() => {
                  const b = computeDetailedBreakdown({
                    lat1: isFleetMode ? currentVeh.originCoords.lat : 26.1445,
                    lon1: isFleetMode ? currentVeh.originCoords.lng : 91.7362,
                    lat2: isFleetMode ? currentVeh.destCoords.lat : 25.5788,
                    lon2: isFleetMode ? currentVeh.destCoords.lng : 91.8933,
                    vehicleTitle: isFleetMode ? currentVeh.model : 'Tata Prima 31T',
                    cargoTitle: isFleetMode ? currentVeh.cargo : 'FMCG Critical',
                    isSafestRoute: true,
                  });
                  setAuditBreakdown(b);
                  setIsAuditModalOpen(true);
                }}
              />
            );
          })()}
        </div>
      </div>

      {/* ROW 2 — TWO COLUMNS (60% + 40%, 16px gap) */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.4fr) minmax(0, 1fr)',
          gap: '16px',
        }}
      >
        {/* LEFT — Corridor Status Table */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '16px',
              flexWrap: 'wrap',
              gap: '10px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                Corridor Status
              </h2>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  height: '32px',
                  padding: '0 8px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: '#FFFFFF',
                  width: '180px',
                }}
              >
                <Search size={13} color="var(--color-text-muted)" />
                <input
                  type="text"
                  placeholder="Filter corridor..."
                  value={corridorQuery}
                  onChange={(e) => setCorridorQuery(e.target.value)}
                  style={{
                    border: 'none',
                    outline: 'none',
                    width: '100%',
                    fontSize: '12px',
                    color: 'var(--color-text-primary)',
                  }}
                />
              </div>
            </div>

            <button
              onClick={() => navigate('/corridors')}
              style={{
                fontSize: '12px',
                fontWeight: 600,
                color: 'var(--color-primary)',
                padding: '4px 10px',
                borderRadius: 'var(--radius-pill)',
                border: '1px solid var(--color-border)',
                backgroundColor: '#FFFFFF',
                cursor: 'pointer',
              }}
            >
              All Corridors
            </button>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr
                  style={{
                    height: '40px',
                    backgroundColor: 'var(--color-canvas)',
                    borderBottom: '1px solid var(--color-border)',
                    fontSize: '11px',
                    fontWeight: 700,
                    color: 'var(--color-text-disabled)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                  }}
                >
                  <th style={{ padding: '0 12px' }}>Corridor</th>
                  <th style={{ padding: '0 12px' }}>Status</th>
                  <th style={{ padding: '0 12px' }}>Risk Score</th>
                  <th style={{ padding: '0 12px' }}>Disruption</th>
                  <th style={{ padding: '0 12px' }}>Last Report</th>
                  <th style={{ padding: '0 12px', textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {displayedCorridors.map((c) => (
                  <tr
                    key={c.id}
                    style={{
                      height: '52px',
                      borderBottom: '1px solid var(--color-border)',
                      fontSize: '13px',
                      transition: 'background-color var(--transition-fast)',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = 'var(--color-canvas)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor = 'transparent';
                    }}
                  >
                    <td style={{ padding: '0 12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <RouteIcon size={14} color="var(--color-text-muted)" />
                        <div>
                          <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>{c.name}</div>
                          <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{c.routeId}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '0 12px' }}>{renderStatusBadge(c.status)}</td>
                    <td style={{ padding: '0 12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span
                          style={{
                            fontWeight: 700,
                            color:
                              c.riskScore > 75
                                ? 'var(--color-danger)'
                                : c.riskScore > 50
                                ? 'var(--color-warning)'
                                : 'var(--color-success)',
                          }}
                        >
                          {c.riskScore}
                        </span>
                        <div
                          style={{
                            width: '45px',
                            height: '4px',
                            borderRadius: '2px',
                            backgroundColor: 'var(--color-container)',
                            overflow: 'hidden',
                          }}
                        >
                          <div
                            style={{
                              width: `${c.riskScore}%`,
                              height: '100%',
                              backgroundColor:
                                c.riskScore > 75
                                  ? 'var(--color-danger)'
                                  : c.riskScore > 50
                                  ? 'var(--color-warning)'
                                  : 'var(--color-success)',
                            }}
                          />
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '0 12px' }}>
                      <span className="mono" style={{ fontWeight: 600 }}>
                        {c.disruptionProb}%
                      </span>
                    </td>
                    <td style={{ padding: '0 12px' }}>
                      <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                        {c.lastReport}
                      </span>
                    </td>
                    <td style={{ padding: '0 12px', textAlign: 'right' }}>
                      <button
                        onClick={() => navigate(`/corridors?id=${c.id}`)}
                        style={{
                          fontSize: '12px',
                          fontWeight: 600,
                          color: 'var(--color-primary)',
                        }}
                      >
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* RIGHT — Live Alert Feed */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '16px',
            }}
          >
            <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
              Live Alerts
            </h2>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px',
                backgroundColor: 'var(--color-success-bg)',
                color: 'var(--color-success)',
                padding: '3px 8px',
                borderRadius: 'var(--radius-pill)',
                fontSize: '10px',
                fontWeight: 700,
              }}
            >
              <span
                className="pulse-beacon"
                style={{
                  width: '5px',
                  height: '5px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--color-success)',
                }}
              />
              <span>LIVE</span>
            </div>
          </div>

          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '10px',
              maxHeight: '420px',
              overflowY: 'auto',
            }}
          >
            {alerts.map((alt) => {
              let bg = 'var(--color-primary-bg)';
              let borderStrip = 'var(--color-primary)';
              let badgeColor = 'var(--color-primary)';
              let badgeBg = 'var(--color-primary-light)';

              if (alt.severity === 'EMERGENCY') {
                bg = 'var(--color-danger-bg)';
                borderStrip = 'var(--color-emergency)';
                badgeColor = 'var(--color-emergency)';
                badgeBg = '#FEE2E2';
              } else if (alt.severity === 'CAUTION') {
                bg = 'var(--color-warning-bg)';
                borderStrip = 'var(--color-warning)';
                badgeColor = '#B45309';
                badgeBg = '#FEF3C7';
              }

              return (
                <div
                  key={alt.id}
                  style={{
                    backgroundColor: bg,
                    borderLeft: `4px solid ${borderStrip}`,
                    borderRadius: 'var(--radius-md)',
                    padding: '12px 14px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '6px',
                    opacity: alt.acknowledged ? 0.7 : 1,
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span
                        style={{
                          fontSize: '10px',
                          fontWeight: 700,
                          padding: '2px 6px',
                          borderRadius: '4px',
                          backgroundColor: badgeBg,
                          color: badgeColor,
                        }}
                      >
                        {alt.severity}
                      </span>
                      <span className="mono" style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-secondary)' }}>
                        {alt.corridor}
                      </span>
                    </div>
                    <span className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      {alt.time}
                    </span>
                  </div>

                  <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                    {alt.title}
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)', lineHeight: 1.4 }}>
                    {alt.description}
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '2px' }}>
                    <button
                      onClick={() => handleAcknowledge(alt.id)}
                      style={{
                        fontSize: '11px',
                        fontWeight: 600,
                        color: alt.acknowledged ? 'var(--color-success)' : 'var(--color-primary)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px',
                      }}
                    >
                      {alt.acknowledged ? (
                        <>
                          <CheckCircle size={12} />
                          <span>Acknowledged</span>
                        </>
                      ) : (
                        <span>Acknowledge</span>
                      )}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* For Official & Admin: Ground Recon Reports Verification Queue */}
      {(role === 'OFFICIAL' || role === 'ADMIN') && (
        <div
          data-testid="official-reports-verification-queue"
          className="tiyra-card"
          style={{ padding: '20px' }}
        >
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '14px',
              flexWrap: 'wrap',
              gap: '8px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <CheckCircle size={17} color="var(--color-primary)" />
              <h2 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                Field Incident Verification Queue
              </h2>
              <span
                style={{
                  fontSize: '10px',
                  fontWeight: 700,
                  padding: '2px 7px',
                  borderRadius: 'var(--radius-pill)',
                  backgroundColor: 'var(--color-warning-bg)',
                  color: '#B45309',
                  border: '1px solid #FDE68A',
                }}
              >
                OFFICIAL ACTION REQUIRED
              </span>
            </div>

            <button
              type="button"
              onClick={() => navigate('/reports')}
              style={{
                fontSize: '12px',
                fontWeight: 600,
                color: 'var(--color-primary)',
                backgroundColor: 'transparent',
                border: 'none',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              <span>View All {fieldReports.length > 0 ? fieldReports.length : 6} Recon Reports →</span>
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '12px' }}>
            {(fieldReports.length > 0
              ? fieldReports.slice(0, 4).map((r) => ({
                  id: r.id,
                  corridor: r.corridor_name || 'NH-06',
                  km: r.km_marker || 'KM 00.0',
                  hazard: r.hazard_type,
                  severity: r.severity,
                  status: r.status,
                  worker: `${r.reporter_name} (${r.reporter_unit || 'Field Scout'})`,
                  time: r.submitted_at || 'Just now',
                  desc: r.description,
                  photoUrl: r.photo_url ? getAssetUrl(r.photo_url) : undefined,
                }))
              : [
                  {
                    id: 'RP-2847',
                    corridor: 'NH-06',
                    km: 'KM 52.3',
                    hazard: 'Landslide',
                    severity: 'FULL BLOCKAGE',
                    status: 'PENDING',
                    worker: 'Sanjay Kumar (Field Unit 4)',
                    time: '6m ago',
                    desc: 'Large boulder roll-down obstructing both lanes. Earth-mover clearance requested.',
                    photoUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?auto=format&fit=crop&w=800&q=80',
                  },
                  {
                    id: 'RP-2846',
                    corridor: 'NH-29',
                    km: 'KM 81.1',
                    hazard: 'Flash Flood',
                    severity: 'PARTIAL',
                    status: 'VERIFIED',
                    worker: 'Priya Mao (Field Unit 2)',
                    time: '18m ago',
                    desc: 'Mountain stream overflow depositing gravel across 40m. 20cm water depth.',
                    photoUrl: 'https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80',
                  },
                ]
            ).map((rep) => (
              <div
                key={rep.id}
                style={{
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-sm)',
                  backgroundColor: 'var(--color-canvas)',
                  border: '1px solid var(--color-border)',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '6px',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span className="mono" style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                      {rep.id}
                    </span>
                    <span
                      style={{
                        fontSize: '10px',
                        fontWeight: 700,
                        padding: '1px 6px',
                        borderRadius: '4px',
                        backgroundColor: rep.status === 'VERIFIED' ? 'var(--color-success-bg)' : 'var(--color-warning-bg)',
                        color: rep.status === 'VERIFIED' ? 'var(--color-success)' : '#B45309',
                      }}
                    >
                      {rep.status}
                    </span>
                    <span style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-secondary)' }}>
                      {rep.corridor} · {rep.km}
                    </span>
                  </div>
                  <span className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    {rep.time}
                  </span>
                </div>

                <div style={{ fontSize: '12px', color: 'var(--color-text-primary)', fontWeight: 600 }}>
                  {rep.hazard} — {rep.severity}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', lineHeight: 1.35 }}>
                  {rep.desc}
                </div>

                {rep.photoUrl && (
                  <div
                    style={{
                      position: 'relative',
                      height: '110px',
                      borderRadius: '6px',
                      overflow: 'hidden',
                      border: '1px solid #CBD5E1',
                      cursor: 'pointer',
                      backgroundColor: '#0F172A',
                      marginTop: '4px',
                    }}
                    onClick={() => setDashboardLightbox(getAssetUrl(rep.photoUrl!))}
                    title="Click to zoom evidence photo"
                  >
                    <img
                      src={getAssetUrl(rep.photoUrl)}
                      alt="Incident Evidence"
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      onError={(e) => {
                        (e.currentTarget as HTMLElement).style.display = 'none';
                      }}
                    />
                    <div
                      style={{
                        position: 'absolute',
                        top: '6px',
                        left: '6px',
                        backgroundColor: 'rgba(15, 23, 42, 0.82)',
                        color: '#34D399',
                        fontSize: '9px',
                        fontWeight: 700,
                        padding: '2px 6px',
                        borderRadius: '4px',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px',
                      }}
                    >
                      <Camera size={10} />
                      <span>ON-SITE PHOTO EVIDENCE</span>
                    </div>
                    <div
                      style={{
                        position: 'absolute',
                        bottom: '6px',
                        right: '6px',
                        backgroundColor: 'rgba(0,0,0,0.65)',
                        color: '#FFFFFF',
                        fontSize: '10px',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '3px',
                      }}
                    >
                      <ZoomIn size={11} />
                      <span>Inspect</span>
                    </div>
                  </div>
                )}

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '4px' }}>
                  <span style={{ fontSize: '10px', color: 'var(--color-text-muted)' }}>
                    Observer: {rep.worker}
                  </span>
                  <button
                    type="button"
                    onClick={() => navigate('/reports')}
                    style={{
                      fontSize: '11px',
                      fontWeight: 700,
                      color: 'var(--color-primary)',
                      backgroundColor: 'var(--color-primary-bg)',
                      border: '1px solid var(--color-primary-light)',
                      padding: '3px 8px',
                      borderRadius: '4px',
                      cursor: 'pointer',
                    }}
                  >
                    Verify & Dispatch →
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ROW 3 — THREE EQUAL PANELS (16px gap, white, 12px radius, 20px padding) */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: '16px',
        }}
      >
        {/* Panel A — Disruption Probability Chart */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ marginBottom: '14px' }}>
            <h2 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
              Disruption Probability — Next 48h
            </h2>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
              ML forecast · HISTORICAL + LIVE
            </div>
          </div>

          {/* SVG Line Chart */}
          <div style={{ height: '180px', width: '100%', position: 'relative' }}>
            <svg viewBox="0 0 320 140" style={{ width: '100%', height: '100%' }}>
              {/* Grid Lines */}
              <line x1="20" y1="20" x2="310" y2="20" stroke="#F1F5F9" strokeWidth="1" />
              <line x1="20" y1="55" x2="310" y2="55" stroke="#F1F5F9" strokeWidth="1" />
              <line x1="20" y1="90" x2="310" y2="90" stroke="#F1F5F9" strokeWidth="1" />
              <line x1="20" y1="125" x2="310" y2="125" stroke="#E2E8F0" strokeWidth="1" />

              {/* Blue line: NH-06 */}
              <polyline
                fill="none"
                stroke="#0284C7"
                strokeWidth="2.5"
                points="20,110 70,100 120,92 170,105 220,98 270,85 310,88"
              />
              {/* Amber line: NH-29 */}
              <polyline
                fill="none"
                stroke="#F59E0B"
                strokeWidth="2.5"
                strokeDasharray="4 2"
                points="20,80 70,72 120,50 170,42 220,38 270,55 310,48"
              />
            </svg>
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              fontSize: '11px',
              color: 'var(--color-text-muted)',
              borderTop: '1px solid var(--color-border)',
              paddingTop: '10px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ width: '8px', height: '8px', backgroundColor: '#0284C7', borderRadius: '2px' }} />
              <span>NH-06 (Shillong)</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ width: '8px', height: '8px', backgroundColor: '#F59E0B', borderRadius: '2px' }} />
              <span>NH-29 (Silchar)</span>
            </div>
            <span className="mono">+48h Horizon</span>
          </div>
        </div>

        {/* Panel B — Field Coverage by Sector */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ marginBottom: '14px' }}>
            <h2 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
              Field Coverage by Sector
            </h2>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
              Ground telemetry & verified worker presence
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {[
              { name: 'NH-06 (Khasi Hills)', pct: 88, color: 'var(--color-success)' },
              { name: 'NH-29 (Barail Range)', pct: 65, color: 'var(--color-warning)' },
              { name: 'NH-37 (Brahmaputra South)', pct: 22, color: 'var(--color-danger)' },
              { name: 'NH-40 (Jaintia Hills)', pct: 75, color: 'var(--color-warning)' },
              { name: 'NH-51 (Garo Hills)', pct: 91, color: 'var(--color-success)' },
            ].map((sec) => (
              <div key={sec.name}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                  <span style={{ fontWeight: 500, color: 'var(--color-text-secondary)' }}>{sec.name}</span>
                  <span className="mono" style={{ fontWeight: 600, color: sec.color }}>
                    {sec.pct}%
                  </span>
                </div>
                <div
                  style={{
                    height: '6px',
                    borderRadius: '3px',
                    backgroundColor: 'var(--color-container)',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      width: `${sec.pct}%`,
                      height: '100%',
                      backgroundColor: sec.color,
                    }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Panel C — Activity Timeline */}
        <div className="tiyra-card" style={{ padding: '20px' }}>
          <div style={{ marginBottom: '14px' }}>
            <h2 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
              Recent Activity
            </h2>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
              Verified ground events & dispatch logs
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {[
              { actor: 'Sanjay Kumar', action: 'Uploaded landslide report at KM 52.3', time: '6m ago', dot: 'var(--color-danger)' },
              { actor: 'Dr. Anamika Barua', action: 'Issued regional caution advisory for NH-29', time: '18m ago', dot: 'var(--color-warning)' },
              { actor: 'Priya Mao', action: 'Confirmed clear passage on NH-40 Jowai segment', time: '34m ago', dot: 'var(--color-success)' },
              { actor: 'System ML', action: 'Re-evaluated NH-37 flood probability to 78%', time: '1h ago', dot: 'var(--color-primary)' },
              { actor: 'Ratan Das', action: 'Logged offline checkpoint sync at Nongpoh', time: '2h ago', dot: 'var(--color-success)' },
            ].map((item, idx) => (
              <div key={idx} style={{ display: 'flex', alignItems: 'flex-start', gap: '10px' }}>
                <span
                  style={{
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    backgroundColor: item.dot,
                    marginTop: '5px',
                    flexShrink: 0,
                  }}
                />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '13px', color: 'var(--color-text-primary)', lineHeight: 1.3 }}>
                    <span style={{ fontWeight: 600 }}>{item.actor}</span>{' '}
                    <span style={{ color: 'var(--color-text-secondary)' }}>{item.action}</span>
                  </div>
                  <span className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    {item.time}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Interactive Journey Planning Modal */}
      <JourneyPlanningModal
        isOpen={isJourneyModalOpen}
        onClose={() => setIsJourneyModalOpen(false)}
      />

      {/* Distance Clauses Audit Modal */}
      <DistanceClausesModal
        isOpen={isAuditModalOpen}
        onClose={() => setIsAuditModalOpen(false)}
        breakdown={auditBreakdown}
        originName="Guwahati Port Hub"
        destName="Shillong Terminal Hub"
        vehicleName={role === 'DRIVER' ? 'Tata Prima 31T' : 'Ashok Leyland 1618'}
        cargoName="FMCG Critical"
        routeName="NH-06 via Nongpoh (Safest)"
      />

      {/* High-Resolution Field Evidence Lightbox Modal */}
      {dashboardLightbox && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 9999,
            backgroundColor: 'rgba(15, 23, 42, 0.85)',
            backdropFilter: 'blur(6px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '24px',
          }}
          onClick={() => setDashboardLightbox(null)}
        >
          <div
            style={{
              position: 'relative',
              maxWidth: '90vw',
              maxHeight: '90vh',
              borderRadius: '12px',
              overflow: 'hidden',
              boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
              backgroundColor: '#0F172A',
              border: '1px solid rgba(255,255,255,0.1)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ position: 'absolute', top: '12px', right: '12px', zIndex: 10 }}>
              <button
                type="button"
                onClick={() => setDashboardLightbox(null)}
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(0, 0, 0, 0.65)',
                  border: '1px solid rgba(255, 255, 255, 0.2)',
                  color: '#FFFFFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                }}
              >
                <X size={20} />
              </button>
            </div>
            <img
              src={getAssetUrl(dashboardLightbox)}
              alt="High Resolution Incident Evidence"
              style={{
                maxWidth: '85vw',
                maxHeight: '80vh',
                objectFit: 'contain',
                display: 'block',
              }}
            />
            <div
              style={{
                padding: '12px 16px',
                backgroundColor: 'rgba(15, 23, 42, 0.95)',
                color: '#E2E8F0',
                fontSize: '12px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Camera size={14} color="#10B981" />
                <span style={{ fontWeight: 600 }}>Geo-Verified Field Recon Photo (Streamed from Mobile Scout)</span>
              </div>
              <span style={{ color: '#94A3B8', fontSize: '11px' }}>TiyraSense Ground Operations Network</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
