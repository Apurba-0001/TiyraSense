import React, { useEffect, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { fetchHealthStatus } from '../services/api';
import {
  AlertTriangle,
  Layers,
  Navigation,
  Compass,
  ShieldCheck,
  Radio,
  Clock,
  AlertOctagon,
  Satellite,
  Check,
  X,
} from 'lucide-react';

interface CorridorData {
  id: string;
  name: string;
  route: string;
  status: 'PASSABLE' | 'MONITORED' | 'DISRUPTED';
  riskScore: number;
  activeVehicles: number;
  lastVerified: string;
  weather: string;
  slopeInstability: string;
  rainIntensity: string;
}

const CORRIDORS: CorridorData[] = [
  {
    id: 'NH-06',
    name: 'Guwahati – Shillong Expressway',
    route: 'Jorabat → Nongpoh → Umiam → Mawlai',
    status: 'PASSABLE',
    riskScore: 0.22,
    activeVehicles: 34,
    lastVerified: '3 mins ago',
    weather: 'Light Rain (8mm/h)',
    slopeInstability: 'Low (12%)',
    rainIntensity: '8 mm/h',
  },
  {
    id: 'NH-27',
    name: 'East-West Transit Corridor',
    route: 'Dispur → Jagiroad → Nagaon → Doboka',
    status: 'PASSABLE',
    riskScore: 0.15,
    activeVehicles: 58,
    lastVerified: 'Just now',
    weather: 'Overcast (28°C)',
    slopeInstability: 'Minimal (4%)',
    rainIntensity: '2 mm/h',
  },
  {
    id: 'NH-29',
    name: 'Nagaon – Dimapur – Kohima Route',
    route: 'Nagaon → Dabaka → Chumukedima',
    status: 'MONITORED',
    riskScore: 0.58,
    activeVehicles: 19,
    lastVerified: '12 mins ago',
    weather: 'Heavy Rain • Landslide Watch',
    slopeInstability: 'High (68%)',
    rainIntensity: '24 mm/h',
  },
  {
    id: 'NH-102',
    name: 'Imphal – Moreh Border Transit',
    route: 'Imphal → Thoubal → Pallel → Tengnoupal',
    status: 'DISRUPTED',
    riskScore: 0.84,
    activeVehicles: 6,
    lastVerified: '25 mins ago',
    weather: 'Mudflow Advisory Active',
    slopeInstability: 'Critical (88%)',
    rainIntensity: '32 mm/h',
  },
];

interface IncidentReport {
  id: string;
  type: string;
  location: string;
  coords: string;
  severity: 'HIGH' | 'CRITICAL' | 'MODERATE';
  time: string;
  verified: boolean;
}

const INITIAL_INCIDENTS: IncidentReport[] = [
  {
    id: 'INC-2601',
    type: 'Boulder Fall & Shoulder Erosion',
    location: 'NH-29 Km 14.8 (Pagla Pahar)',
    coords: '25.7124° N, 93.7412° E',
    severity: 'HIGH',
    time: '8 mins ago',
    verified: false,
  },
  {
    id: 'INC-2602',
    type: 'Culvert Water Inundation (28cm)',
    location: 'NH-06 Km 38.2 near Jorabat',
    coords: '26.1102° N, 91.8904° E',
    severity: 'MODERATE',
    time: '24 mins ago',
    verified: true,
  },
  {
    id: 'INC-2603',
    type: 'Mudflow Deposit (Single Lane)',
    location: 'NH-102 Km 64.1 near Tengnoupal',
    coords: '24.4182° N, 94.1205° E',
    severity: 'CRITICAL',
    time: '42 mins ago',
    verified: false,
  },
];

export const Dashboard: React.FC = () => {
  const [health, setHealth] = useState<{
    status: string;
    database: string;
    postgis_version: string;
  } | null>(null);
  const [isLoadingHealth, setIsLoadingHealth] = useState(true);
  const [activeLayer, setActiveLayer] = useState<'all' | 'risk' | 'weather'>('all');
  const [selectedCorridor, setSelectedCorridor] = useState<string>('NH-06');
  const [incidents, setIncidents] = useState<IncidentReport[]>(INITIAL_INCIDENTS);
  const [currentTime, setCurrentTime] = useState<string>('');

  useEffect(() => {
    async function loadHealth() {
      try {
        const res = await fetchHealthStatus();
        setHealth(res);
      } catch {
        setHealth({ status: 'offline', database: 'disconnected', postgis_version: 'unknown' });
      } finally {
        setIsLoadingHealth(false);
      }
    }
    loadHealth();

    const updateClock = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString('en-IN', {
          timeZone: 'Asia/Kolkata',
          hour12: false,
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
        }) + ' IST'
      );
    };
    updateClock();
    const interval = setInterval(updateClock, 1000);
    return () => clearInterval(interval);
  }, []);

  const handleVerifyIncident = (id: string) => {
    setIncidents((prev) =>
      prev.map((inc) => (inc.id === id ? { ...inc, verified: true } : inc))
    );
  };

  const handleDismissIncident = (id: string) => {
    setIncidents((prev) => prev.filter((inc) => inc.id !== id));
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', width: '100%', maxWidth: '1920px', margin: '0 auto' }}>
      {/* High-Resolution Mission Control Header (Light Theme) */}
      <div
        className="glass-panel"
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: '1.25rem',
          padding: '1.25rem 2rem',
          borderRadius: 'var(--radius-xl)',
          backgroundColor: 'var(--surface)',
          color: 'var(--text-primary)',
          border: '1px solid var(--border)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div
            style={{
              width: '42px',
              height: '42px',
              borderRadius: 'var(--radius-md)',
              backgroundColor: 'var(--primary-light)',
              border: '1px solid var(--info-border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Compass size={22} color="var(--primary)" />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
                TACTICAL COMMAND CONSOLE • NER
              </span>
              <span style={{ color: 'var(--text-muted)' }}>•</span>
              <span style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', fontFamily: 'monospace' }}>
                EPSG:4326 WGS-84
              </span>
            </div>
            <h1 style={{ fontSize: '1.65rem', fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--text-primary)', lineHeight: 1.2 }}>
              State Emergency Operations Center (ASDMA)
            </h1>
          </div>
        </div>

        {/* Telemetry Clock & Systems Status */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              backgroundColor: 'var(--bg-subtle)',
              padding: '0.45rem 0.95rem',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
              fontFamily: 'monospace',
              fontSize: '0.85rem',
              color: 'var(--primary)',
            }}
          >
            <Clock size={16} color="var(--primary)" />
            <span>{currentTime || '12:00:00 IST'}</span>
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              backgroundColor: 'var(--success-bg)',
              padding: '0.45rem 0.95rem',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--success-border)',
            }}
          >
            <Satellite size={16} color="var(--success)" />
            <span style={{ fontSize: '0.78rem', color: 'var(--success)', fontWeight: 700 }}>
              GPS + NavIC LOCKED
            </span>
          </div>

          <StatusBadge
            label={
              isLoadingHealth
                ? 'Querying PostGIS...'
                : health?.database === 'connected'
                ? 'PostGIS 3.4 Connected'
                : 'Database Offline'
            }
            variant={isLoadingHealth ? 'info' : health?.database === 'connected' ? 'healthy' : 'critical'}
          />

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              backgroundColor: 'var(--critical-bg)',
              border: '1px solid var(--critical-border)',
              padding: '0.45rem 0.85rem',
              borderRadius: 'var(--radius-full)',
              color: 'var(--critical)',
              fontSize: '0.75rem',
              fontWeight: 700,
            }}
          >
            <AlertOctagon size={14} />
            <span>3 Active Disruptions</span>
          </div>
        </div>
      </div>

      {/* Responsive Command Grid (3-column on Desktop, 2-column on Tablet, 1-column on Mobile) */}
      <div className="dashboard-grid">
        {/* COLUMN 1 (LEFT): Live Corridor Telemetry Feed */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div
            className="glass-panel"
            style={{
              padding: '1.25rem 1.5rem',
              borderRadius: 'var(--radius-xl)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 700, letterSpacing: '-0.01em' }}>
                  Critical Highway Corridors
                </h3>
                <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                  Sensory telemetry & slope monitoring
                </p>
              </div>
              <Layers size={18} color="var(--primary)" />
            </div>

            {/* Corridor List */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              {CORRIDORS.map((c) => (
                <div
                  key={c.id}
                  onClick={() => setSelectedCorridor(c.id)}
                  style={{
                    padding: '1rem',
                    borderRadius: 'var(--radius-lg)',
                    border: selectedCorridor === c.id ? '2px solid var(--primary)' : '1px solid var(--border)',
                    backgroundColor: selectedCorridor === c.id ? 'var(--primary-light)' : 'var(--surface)',
                    cursor: 'pointer',
                    transition: 'all var(--transition-snappy)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <span style={{ fontWeight: 800, color: 'var(--primary)', fontSize: '0.95rem' }}>
                        {c.id}
                      </span>
                      <span style={{ fontSize: '0.8rem', fontWeight: 600 }}>{c.name}</span>
                    </div>
                    <StatusBadge
                      label={c.status}
                      variant={c.status === 'PASSABLE' ? 'healthy' : c.status === 'MONITORED' ? 'warning' : 'critical'}
                      size="sm"
                    />
                  </div>

                  <div style={{ fontSize: '0.74rem', color: 'var(--text-secondary)', marginTop: '0.35rem' }}>
                    {c.route}
                  </div>

                  {/* Micro telemetry bars */}
                  <div
                    style={{
                      display: 'grid',
                      gridTemplateColumns: '1fr 1fr',
                      gap: '0.5rem',
                      marginTop: '0.75rem',
                      paddingTop: '0.65rem',
                      borderTop: '1px solid var(--border-subtle)',
                      fontSize: '0.72rem',
                    }}
                  >
                    <div>
                      <span style={{ color: 'var(--text-muted)' }}>Slope Instability:</span>
                      <div style={{ fontWeight: 700, color: c.riskScore > 0.5 ? 'var(--critical)' : 'var(--success)' }}>
                        {c.slopeInstability}
                      </div>
                    </div>
                    <div>
                      <span style={{ color: 'var(--text-muted)' }}>Rainfall Radar:</span>
                      <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{c.rainIntensity}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Metrics Summary */}
          <div
            className="glass-panel"
            style={{
              padding: '1.25rem 1.5rem',
              borderRadius: 'var(--radius-xl)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
              <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                Supply Chain Clearance
              </span>
              <ShieldCheck size={16} color="var(--success)" />
            </div>
            <div style={{ fontSize: '2rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'var(--primary)' }}>
              92.8% Passable
            </div>
            <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
              117 of 128 monitored highway segments open for multi-axle freight convoys.
            </p>
          </div>
        </div>

        {/* COLUMN 2 (CENTER): High-Resolution Tactical GIS Spatial Radar */}
        <div className="dashboard-center-col" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div
            className="glass-panel"
            style={{
              borderRadius: 'var(--radius-xl)',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
              backgroundColor: 'var(--surface)',
              border: '1px solid var(--border)',
            }}
          >
            {/* GIS Toolbar */}
            <div
              style={{
                padding: '1rem 1.5rem',
                borderBottom: '1px solid var(--border)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                backgroundColor: 'var(--bg-subtle)',
                color: 'var(--text-primary)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
                <Radio size={16} color="var(--primary)" className="pulse-beacon" />
                <span style={{ fontSize: '0.82rem', fontWeight: 700, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
                  Live Spatial Map Engine • {selectedCorridor} Focus
                </span>
              </div>

              {/* Layer Toggles */}
              <div style={{ display: 'flex', gap: '0.4rem' }}>
                {(['all', 'risk', 'weather'] as const).map((layer) => (
                  <button
                    key={layer}
                    onClick={() => setActiveLayer(layer)}
                    style={{
                      padding: '0.35rem 0.75rem',
                      borderRadius: 'var(--radius-full)',
                      fontSize: '0.72rem',
                      fontWeight: 700,
                      backgroundColor: activeLayer === layer ? 'var(--primary)' : 'var(--surface)',
                      color: activeLayer === layer ? '#ffffff' : 'var(--text-secondary)',
                      border: '1px solid var(--border)',
                      cursor: 'pointer',
                    }}
                  >
                    {layer === 'all' ? 'All Overlays' : layer === 'risk' ? 'Landslide Heat' : 'Rain Bands'}
                  </button>
                ))}
              </div>
            </div>

            {/* High-Resolution Tactical Vector Display (Light Theme Map Canvas) */}
            <div
              style={{
                position: 'relative',
                height: '460px',
                backgroundColor: '#f1f5f9',
                backgroundImage:
                  'radial-gradient(ellipse at 50% 50%, rgba(2, 132, 199, 0.08) 0%, transparent 80%), linear-gradient(rgba(2, 132, 199, 0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(2, 132, 199, 0.05) 1px, transparent 1px)',
                backgroundSize: '100% 100%, 36px 36px, 36px 36px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
              }}
            >
              {/* Scalable Topographic Vector Curves */}
              <svg
                style={{
                  position: 'absolute',
                  width: '100%',
                  height: '100%',
                  opacity: 0.35,
                  pointerEvents: 'none',
                }}
                viewBox="0 0 1000 500"
              >
                <path d="M0 320 Q250 140 500 280 T1000 220" fill="none" stroke="#38bdf8" strokeWidth="1.5" strokeDasharray="5,5" />
                <path d="M0 400 Q300 200 650 360 T1000 300" fill="none" stroke="#06b6d4" strokeWidth="1.5" />
                <path d="M0 200 Q350 80 750 240 T1000 160" fill="none" stroke="#0284c7" strokeWidth="1" />
              </svg>

              {/* Highway Corridor Polylines & Live Nodes */}
              <svg
                style={{
                  position: 'absolute',
                  width: '100%',
                  height: '100%',
                  zIndex: 1,
                }}
                viewBox="0 0 1000 500"
              >
                {/* NH-06 Primary Route */}
                <path
                  d="M 200 380 C 320 320, 460 270, 600 210 S 780 130, 860 110"
                  fill="none"
                  stroke="#38bdf8"
                  strokeWidth="5"
                  strokeLinecap="round"
                  filter="drop-shadow(0 0 10px rgba(56, 189, 248, 0.8))"
                />

                {/* NH-27 East-West Axis */}
                <path
                  d="M 200 380 Q 420 390 650 410 T 940 440"
                  fill="none"
                  stroke="#10b981"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  strokeDasharray="6,4"
                />

                {/* Waypoint 1: Guwahati Port Hub */}
                <circle cx="200" cy="380" r="9" fill="#10b981" stroke="#ffffff" strokeWidth="3" />
                <text x="175" y="415" fill="#0f172a" fontSize="13" fontWeight="700" fontFamily="Inter">
                  Guwahati Port (Origin)
                </text>

                {/* Waypoint 2: Jorabat Jct */}
                <circle cx="410" cy="300" r="6" fill="#0284c7" stroke="#ffffff" strokeWidth="2" />
                <text x="425" y="305" fill="#475569" fontSize="11" fontFamily="Inter" fontWeight="600">
                  Jorabat Jct
                </text>

                {/* Waypoint 3: Nongpoh */}
                <circle cx="600" cy="210" r="7" fill="#f59e0b" stroke="#ffffff" strokeWidth="2.5" />
                <text x="615" y="215" fill="#b45309" fontSize="12" fontWeight="700" fontFamily="Inter">
                  Nongpoh (Rain 8mm/h)
                </text>

                {/* Waypoint 4: Shillong Terminal */}
                <circle cx="860" cy="110" r="9" fill="#0284c7" stroke="#ffffff" strokeWidth="3" />
                <text x="815" y="85" fill="#0f172a" fontSize="13" fontWeight="700" fontFamily="Inter">
                  Shillong (Dest)
                </text>
              </svg>

              {/* Floating Tactical Overlay Card (Light Theme) */}
              <div
                style={{
                  position: 'absolute',
                  top: '1.25rem',
                  left: '1.5rem',
                  backgroundColor: 'rgba(255, 255, 255, 0.95)',
                  backdropFilter: 'blur(10px)',
                  border: '1px solid var(--border)',
                  boxShadow: 'var(--shadow-md)',
                  borderRadius: 'var(--radius-md)',
                  padding: '1rem 1.4rem',
                  color: 'var(--text-primary)',
                  zIndex: 2,
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.4rem' }}>
                  <Radio size={14} color="var(--primary)" className="pulse-beacon" />
                  <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--primary)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                    Active Convoy Segment
                  </span>
                </div>
                <div style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>NH-06 Guwahati ↔ Shillong</div>
                <div style={{ display: 'flex', gap: '1.25rem', marginTop: '0.5rem', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                  <span>Distance: <strong style={{ color: 'var(--text-primary)' }}>98.4 km</strong></span>
                  <span>Avg Speed: <strong style={{ color: 'var(--text-primary)' }}>42 km/h</strong></span>
                  <span>Status: <strong style={{ color: 'var(--success)' }}>Passable</strong></span>
                </div>
              </div>

              {/* Floating Coordinates & Altitude HUD (Light Theme) */}
              <div
                style={{
                  position: 'absolute',
                  bottom: '1.25rem',
                  right: '1.5rem',
                  backgroundColor: 'rgba(255, 255, 255, 0.95)',
                  backdropFilter: 'blur(8px)',
                  border: '1px solid var(--border)',
                  boxShadow: 'var(--shadow-sm)',
                  borderRadius: 'var(--radius-sm)',
                  padding: '0.5rem 0.85rem',
                  color: 'var(--text-secondary)',
                  fontSize: '0.75rem',
                  fontFamily: 'monospace',
                  zIndex: 2,
                }}
              >
                26.1445° N, 91.7362° E • Elevation 54m → 1,496m MSL
              </div>
            </div>
          </div>
        </div>

        {/* COLUMN 3 (RIGHT): Route Optimizer & Incident Verification Queue */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Route Risk Optimizer Panel */}
          <div
            className="glass-panel"
            style={{
              padding: '1.5rem',
              borderRadius: 'var(--radius-xl)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 700, letterSpacing: '-0.01em' }}>
                  Route Risk Optimizer
                </h3>
                <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                  Decision-support comparative routing
                </p>
              </div>
              <Navigation size={18} color="var(--primary)" />
            </div>

            {/* Option A: Recommended Safe Route */}
            <div
              style={{
                padding: '1rem',
                borderRadius: 'var(--radius-lg)',
                border: '2px solid var(--success)',
                backgroundColor: 'var(--success-bg)',
                marginBottom: '0.85rem',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--success)' }}>
                  RECOMMENDED SAFE ROUTE
                </span>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--success)' }}>
                  Risk Score: 0.18
                </span>
              </div>
              <div style={{ fontSize: '0.9rem', fontWeight: 700, marginTop: '0.35rem' }}>
                via NH-06 Express Corridor
              </div>
              <div style={{ display: 'flex', gap: '1rem', fontSize: '0.78rem', color: 'var(--text-secondary)', marginTop: '0.35rem' }}>
                <span>ETA: <strong>2h 15m</strong></span>
                <span>Distance: <strong>98 km</strong></span>
              </div>
              <div
                style={{
                  marginTop: '0.65rem',
                  padding: '0.5rem 0.75rem',
                  borderRadius: 'var(--radius-sm)',
                  backgroundColor: 'rgba(255, 255, 255, 0.75)',
                  fontSize: '0.74rem',
                  color: 'var(--text-secondary)',
                }}
              >
                ✓ Bypasses 2 active landslide warning zones near Pagla Pahar.
              </div>
            </div>

            {/* Option B: Fastest Route (Elevated Risk) */}
            <div
              style={{
                padding: '1rem',
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--warning-border)',
                backgroundColor: 'var(--warning-bg)',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--warning)' }}>
                  FASTEST AVAILABLE ROUTE
                </span>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--warning)' }}>
                  Risk Score: 0.64
                </span>
              </div>
              <div style={{ fontSize: '0.9rem', fontWeight: 700, marginTop: '0.35rem' }}>
                via NH-29 Mountain Ridge
              </div>
              <div style={{ display: 'flex', gap: '1rem', fontSize: '0.78rem', color: 'var(--text-secondary)', marginTop: '0.35rem' }}>
                <span>ETA: <strong>1h 58m</strong> (-17m)</span>
                <span>Distance: <strong>89 km</strong></span>
              </div>
              <div
                style={{
                  marginTop: '0.65rem',
                  padding: '0.5rem 0.75rem',
                  borderRadius: 'var(--radius-sm)',
                  backgroundColor: 'rgba(255, 255, 255, 0.75)',
                  fontSize: '0.74rem',
                  color: 'var(--critical)',
                  fontWeight: 600,
                }}
              >
                ⚠ High risk of mudslide delays between KM 14-22.
              </div>
            </div>
          </div>

          {/* Incident Verification Queue */}
          <div
            className="glass-panel"
            style={{
              padding: '1.5rem',
              borderRadius: 'var(--radius-xl)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 700, letterSpacing: '-0.01em' }}>
                  Field Incident Queue
                </h3>
                <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                  Real-time worker submissions awaiting verification
                </p>
              </div>
              <AlertTriangle size={18} color="var(--warning)" />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {incidents.map((inc) => (
                <div
                  key={inc.id}
                  style={{
                    padding: '0.85rem',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--border)',
                    backgroundColor: 'var(--surface)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--primary)' }}>
                      {inc.id}
                    </span>
                    <StatusBadge label={inc.severity} variant={inc.severity === 'CRITICAL' ? 'critical' : 'warning'} size="sm" />
                  </div>

                  <div style={{ fontSize: '0.82rem', fontWeight: 700, marginTop: '0.25rem' }}>
                    {inc.type}
                  </div>
                  <div style={{ fontSize: '0.74rem', color: 'var(--text-secondary)' }}>
                    {inc.location}
                  </div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', fontFamily: 'monospace', marginTop: '0.2rem' }}>
                    {inc.coords} • {inc.time}
                  </div>

                  <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.65rem' }}>
                    {inc.verified ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.75rem', color: 'var(--success)', fontWeight: 700 }}>
                        <Check size={14} />
                        <span>Verified by ASDMA</span>
                      </div>
                    ) : (
                      <>
                        <button
                          onClick={() => handleVerifyIncident(inc.id)}
                          style={{
                            flex: 1,
                            padding: '0.35rem 0.5rem',
                            borderRadius: 'var(--radius-sm)',
                            backgroundColor: 'var(--primary)',
                            color: '#fff',
                            fontSize: '0.74rem',
                            fontWeight: 700,
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '0.3rem',
                          }}
                        >
                          <Check size={13} />
                          Verify & Dispatch
                        </button>
                        <button
                          onClick={() => handleDismissIncident(inc.id)}
                          style={{
                            padding: '0.35rem 0.65rem',
                            borderRadius: 'var(--radius-sm)',
                            border: '1px solid var(--border)',
                            backgroundColor: 'var(--bg)',
                            color: 'var(--text-secondary)',
                            fontSize: '0.74rem',
                            cursor: 'pointer',
                          }}
                        >
                          <X size={13} />
                        </button>
                      </>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
