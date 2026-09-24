import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  TrendingDown,
  Map as MapIcon,
  Calendar,
  Search,
  Navigation,
  ArrowUpDown,
  Truck,
  Package,
  ShieldCheck,
  MapPin,
  CheckCircle2,
  ChevronDown,
  Scale,
} from 'lucide-react';
import { JourneyPlanningModal } from '../components/JourneyPlanningModal';
import { VectorGisMap } from '../components/VectorGisMap';
import { DistanceClausesModal } from '../components/DistanceClausesModal';
import { computeDetailedBreakdown, DistanceBreakdown } from '../utils/distanceUtils';
import { fetchActiveJourneys, fetchCorridors, fetchFieldReports, ActiveJourney } from '../services/api';

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

function lookupCoords(name: string, fallback: { lat: number; lng: number }): { lat: number; lng: number } {
  const lower = name.toLowerCase();
  for (const [k, v] of Object.entries(HUB_COORDINATES)) {
    if (lower.includes(k)) return v;
  }
  return fallback;
}


interface CorridorDetail {
  id: string;
  name: string;
  routeId: string;
  status: 'PASSABLE' | 'CAUTION' | 'HIGH RISK' | 'BLOCKED';
  riskScore: number;
  disruptionProb: number;
  verifiedReports: number;
  updatedAt: string;
  factors: {
    name: string;
    percentage: number;
    severity: 'GREEN' | 'AMBER' | 'RED';
    detail: string;
  }[];
  incidents: {
    date: string;
    dotColor: string;
    title: string;
    status: string;
    worker: string;
  }[];
}

const CORRIDORS: CorridorDetail[] = [
  {
    id: 'nh-06',
    name: 'NH-06 Guwahati-Shillong',
    routeId: 'Jorabat → Nongpoh → Mawlai',
    status: 'PASSABLE',
    riskScore: 28,
    disruptionProb: 14,
    verifiedReports: 6,
    updatedAt: '6m ago',
    factors: [
      { name: 'Precipitation Index', percentage: 62, severity: 'AMBER', detail: 'Monsoon intermittent shower over Ri-Bhoi district' },
      { name: 'Slope Stability', percentage: 31, severity: 'GREEN', detail: 'Reinforced rock netting stable along Nongpoh cuttings' },
      { name: 'Traffic Density', percentage: 45, severity: 'AMBER', detail: 'Heavy freight transit active at Byrnihat inter-state toll' },
      { name: 'Infrastructure Condition', percentage: 18, severity: 'GREEN', detail: 'Bitumen surface intact; culverts cleared 48h ago' },
    ],
    incidents: [
      { date: 'Sep 05, 2026', dotColor: 'var(--color-danger)', title: 'Boulder slide cleared at KM 52.3', status: 'RESOLVED', worker: 'Sanjay Kumar (Field Unit 4)' },
      { date: 'Sep 02, 2026', dotColor: 'var(--color-warning)', title: 'Shoulder runoff pooling near Nongpoh market', status: 'MONITORED', worker: 'Priya Mao (Field Unit 2)' },
      { date: 'Aug 28, 2026', dotColor: 'var(--color-success)', title: 'Routine culvert drone inspection completed', status: 'VERIFIED', worker: 'ASDMA Aerial Team' },
      { date: 'Aug 24, 2026', dotColor: 'var(--color-warning)', title: 'Slow moving heavy vehicle breakdown on incline', status: 'RESOLVED', worker: 'Highway Patrol Unit 3' },
      { date: 'Aug 19, 2026', dotColor: 'var(--color-danger)', title: 'Minor mud slip during cloudburst warning', status: 'RESOLVED', worker: 'BRO Quick Response' },
    ],
  },
  {
    id: 'nh-29',
    name: 'NH-29 Guwahati-Silchar',
    routeId: 'Nagaon → Dabaka → Silchar',
    status: 'CAUTION',
    riskScore: 61,
    disruptionProb: 52,
    verifiedReports: 9,
    updatedAt: '18m ago',
    factors: [
      { name: 'Precipitation Index', percentage: 78, severity: 'RED', detail: 'Flash flood run-off accumulating along Barail foothills' },
      { name: 'Slope Stability', percentage: 64, severity: 'AMBER', detail: 'Saturated soil warning active in Pagla Pahar cutting' },
      { name: 'Traffic Density', percentage: 55, severity: 'AMBER', detail: 'Single lane alternating transit enforced at KM 81' },
      { name: 'Infrastructure Condition', percentage: 42, severity: 'AMBER', detail: 'Culvert structural stress monitored by strain gauges' },
    ],
    incidents: [
      { date: 'Sep 04, 2026', dotColor: 'var(--color-warning)', title: 'Waterlogging across both lanes at KM 81.1', status: 'ACTIVE', worker: 'Ratan Das (Logistics Unit)' },
      { date: 'Aug 30, 2026', dotColor: 'var(--color-danger)', title: 'Temporary bridge speed restriction to 15km/h', status: 'RESTRICTED', worker: 'PWD Assam Division' },
    ],
  },
  {
    id: 'nh-37',
    name: 'NH-37 Numaligarh-Jorhat',
    routeId: 'Kaziranga → Bokakhat → Jorhat',
    status: 'HIGH RISK',
    riskScore: 84,
    disruptionProb: 78,
    verifiedReports: 4,
    updatedAt: '2h ago',
    factors: [
      { name: 'Precipitation Index', percentage: 86, severity: 'RED', detail: 'Flood wave warnings issued for Kaziranga animal corridors' },
      { name: 'Slope Stability', percentage: 22, severity: 'GREEN', detail: 'Plains topography; minimal landslide risk' },
      { name: 'Traffic Density', percentage: 89, severity: 'RED', detail: 'Animal safety speed radars triggered; convoy delays' },
      { name: 'Infrastructure Condition', percentage: 70, severity: 'RED', detail: 'Submerged shoulders at KM 120-128' },
    ],
    incidents: [
      { date: 'Sep 03, 2026', dotColor: 'var(--color-danger)', title: 'Highway submerged at Bokakhat flood-plain', status: 'HIGH RISK', worker: 'District Flood Recon' },
    ],
  },
  {
    id: 'nh-40',
    name: 'NH-40 Jorabat-Ladrymbai',
    routeId: 'Jorabat → Jowai → Ladrymbai',
    status: 'PASSABLE',
    riskScore: 32,
    disruptionProb: 19,
    verifiedReports: 5,
    updatedAt: '14m ago',
    factors: [
      { name: 'Precipitation Index', percentage: 40, severity: 'GREEN', detail: 'Moderate mist in Jaintia Hills; good visibility' },
      { name: 'Slope Stability', percentage: 38, severity: 'GREEN', detail: 'Retaining walls stable' },
      { name: 'Traffic Density', percentage: 35, severity: 'GREEN', detail: 'Light commercial coal carrier traffic' },
      { name: 'Infrastructure Condition', percentage: 25, severity: 'GREEN', detail: 'Road widening work active with adequate bypasses' },
    ],
    incidents: [
      { date: 'Aug 29, 2026', dotColor: 'var(--color-success)', title: 'Passable conditions confirmed by Field Unit 3', status: 'VERIFIED', worker: 'Field Unit 3' },
    ],
  },
  {
    id: 'nh-51',
    name: 'NH-51 Paikan-Tura',
    routeId: 'Paikan → Bajengdoba → Tura',
    status: 'PASSABLE',
    riskScore: 19,
    disruptionProb: 11,
    verifiedReports: 7,
    updatedAt: '42m ago',
    factors: [
      { name: 'Precipitation Index', percentage: 25, severity: 'GREEN', detail: 'Dry conditions across Garo Hills sector' },
      { name: 'Slope Stability', percentage: 15, severity: 'GREEN', detail: 'Stable terrain profile' },
      { name: 'Traffic Density', percentage: 20, severity: 'GREEN', detail: 'Smooth convoy progress' },
      { name: 'Infrastructure Condition', percentage: 12, severity: 'GREEN', detail: 'Freshly resurfaced state highway link' },
    ],
    incidents: [],
  },
  {
    id: 'nh-102',
    name: 'NH-102 Imphal-Moreh',
    routeId: 'Thoubal → Pallel → Tengnoupal',
    status: 'BLOCKED',
    riskScore: 92,
    disruptionProb: 95,
    verifiedReports: 2,
    updatedAt: '5m ago',
    factors: [
      { name: 'Precipitation Index', percentage: 92, severity: 'RED', detail: 'Torrential downpour triggering flash debris flow' },
      { name: 'Slope Stability', percentage: 95, severity: 'RED', detail: 'Major mudflow collapsed 40m road section near Tengnoupal' },
      { name: 'Traffic Density', percentage: 90, severity: 'RED', detail: 'Border transit halted; vehicles queued safely' },
      { name: 'Infrastructure Condition', percentage: 94, severity: 'RED', detail: 'Road surface severed; civil reconstruction required' },
    ],
    incidents: [
      { date: 'Sep 05, 2026', dotColor: 'var(--color-danger)', title: 'Catastrophic mudflow near Tengnoupal', status: 'BLOCKED', worker: 'Border Transport Auth' },
    ],
  },
  {
    id: 'nh-108',
    name: 'NH-108 Panisagar-Aizawl',
    routeId: 'Damcherra → Kanchanpur → Aizawl',
    status: 'CAUTION',
    riskScore: 54,
    disruptionProb: 46,
    verifiedReports: 3,
    updatedAt: '1h ago',
    factors: [
      { name: 'Precipitation Index', percentage: 58, severity: 'AMBER', detail: 'Heavy mist and cloud cover over Kanchanpur ridges' },
      { name: 'Slope Stability', percentage: 55, severity: 'AMBER', detail: 'Creeping slope identified at KM 34' },
      { name: 'Traffic Density', percentage: 40, severity: 'GREEN', detail: 'Moderate goods movement' },
      { name: 'Infrastructure Condition', percentage: 48, severity: 'AMBER', detail: 'Narrow mountain bends requiring cautious speed' },
    ],
    incidents: [],
  },
  {
    id: 'nh-208',
    name: 'NH-208 Kumarghat-Kailashahar',
    routeId: 'Kumarghat → Fatikroy → Kailashahar',
    status: 'PASSABLE',
    riskScore: 24,
    disruptionProb: 15,
    verifiedReports: 4,
    updatedAt: '28m ago',
    factors: [
      { name: 'Precipitation Index', percentage: 30, severity: 'GREEN', detail: 'Normal regional weather' },
      { name: 'Slope Stability', percentage: 20, severity: 'GREEN', detail: 'Gentle valley gradients' },
      { name: 'Traffic Density', percentage: 28, severity: 'GREEN', detail: 'Local transit normal' },
      { name: 'Infrastructure Condition', percentage: 19, severity: 'GREEN', detail: 'Bridge structures cleared' },
    ],
    incidents: [],
  },
];

const REGIONAL_HUBS = [
  'Guwahati Port Hub (Assam)',
  'Shillong Terminal Hub (Meghalaya)',
  'Silchar Transshipment Depot (Assam)',
  'Agartala Integrated Checkpost (Tripura)',
  'Jorhat Regional Hub (Upper Assam)',
  'Dibrugarh Logistics Center (Assam)',
  'Dimapur Freight Terminal (Nagaland)',
  'Imphal Intermodal Depot (Manipur)',
  'Aizawl Forward Staging Hub (Mizoram)',
  'Kohima Logistics Hub (Nagaland)',
];

const VEHICLE_PROFILES = [
  { id: 'tata-prima', name: 'Tata Prima 31T', category: 'Heavy Multi-Axle' },
  { id: 'ashok-leyland', name: 'Ashok Leyland 1618', category: 'Medium Cargo Truck' },
  { id: 'bolero-maxi', name: 'Mahindra Bolero Maxi', category: '4x4 Light Logistics' },
  { id: 'tata-407', name: 'Tata 407 LCV', category: 'Urban / Hill Freight' },
  { id: 'emergency-4wd', name: 'Emergency 4WD Response', category: 'Essential Relief' },
];

const CARGO_TYPES = [
  { id: 'fmcg', name: 'FMCG Critical', category: 'Essential Food & Dry Rations' },
  { id: 'medical', name: 'Medical & Disaster Relief', category: 'Life Safety Critical' },
  { id: 'pol', name: 'Petroleum & POL', category: 'Hazardous / Flammable' },
  { id: 'agri', name: 'Agricultural Perishables', category: 'Time-Sensitive Cold Chain' },
  { id: 'heavy', name: 'Heavy Construction', category: 'Excavator Spares & Culverts' },
];

export const CorridorMonitor: React.FC = () => {
  const [searchParams] = useSearchParams();
  const initialId = searchParams.get('id') || 'nh-06';
  const [selectedId, setSelectedId] = useState(initialId);
  const [filterRisk, setFilterRisk] = useState<'ALL' | 'HIGH RISK' | 'CAUTION' | 'PASSABLE'>('ALL');
  const [corridorSearch, setCorridorSearch] = useState('');
  const [dateRange, setDateRange] = useState<'24h' | '48h' | '7d' | '30d'>('24h');
  const [isJourneyModalOpen, setIsJourneyModalOpen] = useState(false);
  const [filterToast, setFilterToast] = useState<string | null>(null);

  const [activeFleet, setActiveFleet] = useState<ActiveJourney[]>([]);
  const [corridors, setCorridors] = useState<CorridorDetail[]>(CORRIDORS);

  useEffect(() => {
    const syncCorridorsAndReports = async () => {
      try {
        const [liveCorridors, reports] = await Promise.allSettled([
          fetchCorridors(),
          fetchFieldReports(),
        ]);

        const fieldReps = reports.status === 'fulfilled' ? reports.value || [] : [];

        if (liveCorridors.status === 'fulfilled' && liveCorridors.value && liveCorridors.value.length > 0) {
          setCorridors((prev) => {
            const map = new Map(prev.map((c) => [c.id, c]));
            liveCorridors.value.forEach((l) => {
              const matchedReports = fieldReps.filter((r) => {
                const cName = (r.corridor_name || '').toLowerCase();
                const lId = l.id.toLowerCase();
                const lName = l.name.toLowerCase();
                return cName.includes(lId) || lName.includes(cName) || cName.includes(l.route_id.toLowerCase());
              });

              const existing = map.get(l.id);
              if (existing) {
                map.set(l.id, {
                  ...existing,
                  status: (l.status as CorridorDetail['status']) || existing.status,
                  riskScore: l.risk_score,
                  disruptionProb: l.disruption_prob,
                  verifiedReports: matchedReports.length > 0 ? matchedReports.length : existing.verifiedReports,
                  updatedAt: l.last_report || existing.updatedAt,
                });
              } else {
                map.set(l.id, {
                  id: l.id,
                  name: l.name,
                  routeId: l.route_id,
                  status: (l.status as CorridorDetail['status']) || 'PASSABLE',
                  riskScore: l.risk_score,
                  disruptionProb: l.disruption_prob,
                  verifiedReports: Math.max(1, matchedReports.length),
                  updatedAt: l.last_report || 'Live Radar',
                  factors: [
                    {
                      name: 'Composite Road Risk',
                      percentage: l.risk_score,
                      severity: l.risk_score > 60 ? 'RED' : l.risk_score > 35 ? 'AMBER' : 'GREEN',
                      detail: `Calculated over ${l.segment_count || 1} segments`,
                    },
                  ],
                  incidents: [],
                });
              }
            });
            return Array.from(map.values());
          });
        }
      } catch (_) {}
    };

    syncCorridorsAndReports();
    fetchActiveJourneys().then(setActiveFleet).catch(() => {});

    const interval = setInterval(() => {
      fetchActiveJourneys().then(setActiveFleet).catch(() => {});
      syncCorridorsAndReports();
    }, 10000);

    return () => clearInterval(interval);
  }, []);

  // In-console journey planner states
  const [activeConsoleTab, setActiveConsoleTab] = useState<'planner' | 'map'>('planner');

  const [origin, setOrigin] = useState('Guwahati Port Hub');
  const [destination, setDestination] = useState('Shillong Terminal Hub');
  const [vehicle, setVehicle] = useState(VEHICLE_PROFILES[0].name);
  const [cargo, setCargo] = useState(CARGO_TYPES[0].name);
  const [selectedRoute, setSelectedRoute] = useState<'safest' | 'faster'>('safest');
  const [originPickerOpen, setOriginPickerOpen] = useState(false);
  const [destPickerOpen, setDestPickerOpen] = useState(false);
  const [dispatchToast, setDispatchToast] = useState<string | null>(null);
  const [auditModalOpen, setAuditModalOpen] = useState(false);
  const [activeAuditBreakdown, setActiveAuditBreakdown] = useState<DistanceBreakdown | null>(null);
  const [activeAuditRouteName, setActiveAuditRouteName] = useState('');

  const selectedCorridor = corridors.find((c) => c.id === selectedId) || corridors[0];

  const filteredCorridors = corridors.filter((c) => {
    if (filterRisk !== 'ALL') {
      if (filterRisk === 'HIGH RISK' && c.status !== 'HIGH RISK' && c.status !== 'BLOCKED') return false;
      if (filterRisk === 'CAUTION' && c.status !== 'CAUTION') return false;
      if (filterRisk === 'PASSABLE' && c.status !== 'PASSABLE') return false;
    }
    if (corridorSearch.trim()) {
      const q = corridorSearch.toLowerCase();
      return (
        c.name.toLowerCase().includes(q) ||
        c.routeId.toLowerCase().includes(q) ||
        c.id.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleSwap = () => {
    const temp = origin;
    setOrigin(destination);
    setDestination(temp);
  };

  const handleConfirmRoute = () => {
    setDispatchToast(`Confirmed ${selectedRoute === 'safest' ? 'Safest Route' : 'Faster Route'} for ${vehicle} carrying ${cargo}. Vectors dispatched to mobile field telemetry!`);
    setTimeout(() => setDispatchToast(null), 3500);
  };

  const renderStatusBadge = (status: CorridorDetail['status']) => {
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
    <div className="responsive-container" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* PAGE HEADER */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
          <h1 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
            Corridor Monitor
          </h1>
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

        {/* Filter Row */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            flexWrap: 'wrap',
            backgroundColor: '#FFFFFF',
            padding: '12px 16px',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)',
          }}
        >
          {/* Corridor selector dropdown */}
          <select
            value={selectedId}
            onChange={(e) => setSelectedId(e.target.value)}
            style={{
              height: '36px',
              padding: '0 12px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: '#FFFFFF',
              fontSize: '13px',
              color: 'var(--color-text-primary)',
              minWidth: '180px',
            }}
          >
            {corridors.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>

          {/* Search Corridor Input */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              height: '36px',
              padding: '0 10px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: '#FFFFFF',
              width: '210px',
            }}
          >
            <Search size={14} color="var(--color-text-muted)" />
            <input
              type="text"
              placeholder="Search corridor or route..."
              value={corridorSearch}
              onChange={(e) => setCorridorSearch(e.target.value)}
              style={{
                border: 'none',
                outline: 'none',
                width: '100%',
                fontSize: '12px',
                color: 'var(--color-text-primary)',
              }}
            />
            {corridorSearch && (
              <button
                type="button"
                onClick={() => setCorridorSearch('')}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)', padding: 0 }}
              >
                ×
              </button>
            )}
          </div>

          {/* Date Range Selector Dropdown */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              height: '36px',
              padding: '0 8px 0 12px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)',
              backgroundColor: '#FFFFFF',
            }}
          >
            <Calendar size={14} color="var(--color-text-muted)" />
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value as any)}
              style={{
                border: 'none',
                outline: 'none',
                backgroundColor: 'transparent',
                fontSize: '12px',
                color: 'var(--color-text-secondary)',
                cursor: 'pointer',
              }}
            >
              <option value="24h">Last 24 Hours</option>
              <option value="48h">Last 48 Hours</option>
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
            </select>
          </div>

          {/* Filter Chips */}
          <div style={{ display: 'flex', gap: '6px' }}>
            {(['ALL', 'HIGH RISK', 'CAUTION', 'PASSABLE'] as const).map((chip) => {
              const isActive = filterRisk === chip;
              return (
                <button
                  key={chip}
                  onClick={() => setFilterRisk(chip)}
                  style={{
                    height: '32px',
                    padding: '0 12px',
                    borderRadius: 'var(--radius-pill)',
                    fontSize: '11px',
                    fontWeight: 600,
                    border: '1px solid',
                    borderColor: isActive ? 'var(--color-primary)' : 'var(--color-border)',
                    backgroundColor: isActive ? 'var(--color-primary-bg)' : '#FFFFFF',
                    color: isActive ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                    transition: 'all var(--transition-fast)',
                    cursor: 'pointer',
                  }}
                >
                  {chip}
                </button>
              );
            })}
          </div>

          {/* Apply Button */}
          <button
            onClick={() => {
              setFilterToast(`Filters applied: ${filteredCorridors.length} corridors shown (${dateRange.toUpperCase()})`);
              setTimeout(() => setFilterToast(null), 2500);
            }}
            style={{
              height: '36px',
              padding: '0 16px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--color-primary)',
              color: '#FFFFFF',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
              border: 'none',
            }}
          >
            Apply
          </button>

          {/* Plan Journey Button */}
          <button
            onClick={() => setIsJourneyModalOpen(true)}
            style={{
              height: '36px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--color-primary-bg)',
              color: 'var(--color-primary)',
              border: '1px solid var(--color-primary)',
              fontSize: '12px',
              fontWeight: 700,
              marginLeft: 'auto',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <Navigation size={14} />
            <span>Plan Journey</span>
          </button>
        </div>

        {filterToast && (
          <div
            style={{
              marginTop: '10px',
              padding: '8px 14px',
              backgroundColor: 'var(--color-success-bg)',
              color: 'var(--color-success)',
              borderRadius: 'var(--radius-sm)',
              fontSize: '12px',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <CheckCircle2 size={15} />
            <span>{filterToast}</span>
          </div>
        )}

        {activeFleet.length > 0 && (
          <div
            style={{
              marginTop: '10px',
              padding: '10px 16px',
              backgroundColor: '#EFF6FF',
              border: '1px solid #BFDBFE',
              borderRadius: 'var(--radius-sm)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              fontSize: '12px',
              color: '#1E40AF',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Truck size={16} color="#2563EB" />
              <strong>{activeFleet.length} Active Fleet Unit{activeFleet.length > 1 ? 's' : ''} Transmitting Live Telemetry</strong>
            </div>
            <div style={{ fontSize: '11px', color: '#3B82F6' }}>
              Latest: {activeFleet[0]?.driver_name} · {activeFleet[0]?.route_name}
            </div>
          </div>
        )}
      </div>


      {/* SPLIT LAYOUT: Responsive Left Corridor List + Flex Right */}
      <div className="grid-corridor-split-responsive" style={{ alignItems: 'start' }}>
        {/* LEFT PANEL — Corridor List */}
        <div className="tiyra-card" style={{ padding: '0', overflow: 'hidden' }}>
          <div
            style={{
              padding: '14px 16px',
              borderBottom: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-canvas)',
              fontSize: '11px',
              fontWeight: 700,
              color: 'var(--color-text-disabled)',
              letterSpacing: '0.05em',
              textTransform: 'uppercase',
            }}
          >
            CORRIDORS ({filteredCorridors.length})
          </div>

          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {filteredCorridors.map((c) => {
              const isSelected = c.id === selectedId;
              let dotColor = 'var(--color-success)';
              if (c.status === 'CAUTION') dotColor = 'var(--color-warning)';
              if (c.status === 'HIGH RISK') dotColor = 'var(--color-danger)';
              if (c.status === 'BLOCKED') dotColor = 'var(--color-emergency)';

              return (
                <div
                  key={c.id}
                  onClick={() => setSelectedId(c.id)}
                  style={{
                    height: '72px',
                    padding: '0 16px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    borderBottom: '1px solid var(--color-border)',
                    backgroundColor: isSelected ? 'var(--color-primary-bg)' : '#FFFFFF',
                    borderLeft: isSelected ? '3px solid var(--color-primary)' : '3px solid transparent',
                    cursor: 'pointer',
                    transition: 'background-color var(--transition-fast)',
                  }}
                  onMouseEnter={(e) => {
                    if (!isSelected) e.currentTarget.style.backgroundColor = 'var(--color-canvas)';
                  }}
                  onMouseLeave={(e) => {
                    if (!isSelected) e.currentTarget.style.backgroundColor = '#FFFFFF';
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <span
                      style={{
                        width: '8px',
                        height: '8px',
                        borderRadius: '50%',
                        backgroundColor: dotColor,
                        flexShrink: 0,
                      }}
                    />
                    <div>
                      <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        {c.name}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{c.routeId}</div>
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    {renderStatusBadge(c.status)}
                    <div
                      style={{
                        width: '26px',
                        height: '26px',
                        borderRadius: '50%',
                        backgroundColor: dotColor,
                        color: '#FFFFFF',
                        fontSize: '11px',
                        fontWeight: 700,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      {c.riskScore}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* RIGHT PANEL — Stacked Detail Cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* CARD 1 — Header & Stat Tiles */}
          <div className="tiyra-card" style={{ padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
                  {selectedCorridor.name}
                </h2>
                {renderStatusBadge(selectedCorridor.status)}
              </div>
              <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                Updated {selectedCorridor.updatedAt}
              </span>
            </div>

            {/* 3 Stat Tiles */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '12px' }}>
              <div
                style={{
                  backgroundColor: 'var(--color-canvas)',
                  borderRadius: 'var(--radius-md)',
                  padding: '14px',
                  border: '1px solid var(--color-border)',
                }}
              >
                <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                  Risk Score
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px', marginTop: '4px' }}>
                  <span
                    style={{
                      fontSize: '24px',
                      fontWeight: 800,
                      color:
                        selectedCorridor.riskScore > 75
                          ? 'var(--color-danger)'
                          : selectedCorridor.riskScore > 50
                          ? 'var(--color-warning)'
                          : 'var(--color-success)',
                    }}
                  >
                    {selectedCorridor.riskScore}
                  </span>
                  <span style={{ fontSize: '11px', color: 'var(--color-success)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '2px' }}>
                    <TrendingDown size={12} />
                    <span>improving</span>
                  </span>
                </div>
              </div>

              <div
                style={{
                  backgroundColor: 'var(--color-canvas)',
                  borderRadius: 'var(--radius-md)',
                  padding: '14px',
                  border: '1px solid var(--color-border)',
                }}
              >
                <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                  Disruption Probability
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px', marginTop: '4px' }}>
                  <span className="mono" style={{ fontSize: '24px', fontWeight: 800, color: 'var(--color-primary)' }}>
                    {selectedCorridor.disruptionProb}%
                  </span>
                  <span style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>48h forecast</span>
                </div>
              </div>

              <div
                style={{
                  backgroundColor: 'var(--color-canvas)',
                  borderRadius: 'var(--radius-md)',
                  padding: '14px',
                  border: '1px solid var(--color-border)',
                }}
              >
                <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                  Field Ground Truth
                </div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px', marginTop: '4px' }}>
                  <span style={{ fontSize: '24px', fontWeight: 800, color: 'var(--color-primary)' }}>
                    {selectedCorridor.verifiedReports}
                  </span>
                  <span style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>verified today</span>
                </div>
              </div>
            </div>
          </div>

          {/* CARD 2 — Interactive Tactical Journey Planner & Spatial Route View */}
          <div className="tiyra-card" style={{ padding: '20px' }}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                borderBottom: '1px solid var(--color-border)',
                paddingBottom: '14px',
                marginBottom: '16px',
                flexWrap: 'wrap',
                gap: '10px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <button
                  type="button"
                  onClick={() => setActiveConsoleTab('planner')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '6px 14px',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    border: '1px solid',
                    borderColor: activeConsoleTab === 'planner' ? 'var(--color-primary)' : 'var(--color-border)',
                    backgroundColor: activeConsoleTab === 'planner' ? 'var(--color-primary-bg)' : '#FFFFFF',
                    color: activeConsoleTab === 'planner' ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                    transition: 'all var(--transition-fast)',
                  }}
                >
                  <Navigation size={14} />
                  <span>Tactical Journey Planner</span>
                </button>

                <button
                  type="button"
                  onClick={() => setActiveConsoleTab('map')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '6px 14px',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    border: '1px solid',
                    borderColor: activeConsoleTab === 'map' ? 'var(--color-primary)' : 'var(--color-border)',
                    backgroundColor: activeConsoleTab === 'map' ? 'var(--color-primary-bg)' : '#FFFFFF',
                    color: activeConsoleTab === 'map' ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                    transition: 'all var(--transition-fast)',
                  }}
                >
                  <MapIcon size={14} />
                  <span>Spatial Topology Map</span>
                </button>
              </div>

              <span
                style={{
                  fontSize: '11px',
                  fontWeight: 600,
                  color: 'var(--color-text-muted)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                <ShieldCheck size={14} color="var(--color-success)" />
                <span>Deterministic Risk-Weighted Routing</span>
              </span>
            </div>

            {activeConsoleTab === 'planner' ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {/* Origin / Destination Row with Swap */}
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr auto 1fr',
                    gap: '10px',
                    alignItems: 'center',
                    backgroundColor: 'var(--color-canvas)',
                    padding: '14px',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  {/* Origin */}
                  <div style={{ position: 'relative' }}>
                    <label style={{ display: 'block', fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', marginBottom: '4px' }}>
                      Origin Hub
                    </label>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        height: '38px',
                        padding: '0 10px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                      }}
                    >
                      <MapPin size={15} color="var(--color-success)" />
                      <input
                        type="text"
                        value={origin}
                        onChange={(e) => setOrigin(e.target.value)}
                        onFocus={() => setOriginPickerOpen(true)}
                        placeholder="Search origin hub..."
                        style={{
                          border: 'none',
                          outline: 'none',
                          width: '100%',
                          fontSize: '12px',
                          fontWeight: 600,
                          color: 'var(--color-text-primary)',
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => setOriginPickerOpen(!originPickerOpen)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)', padding: 0 }}
                      >
                        <ChevronDown size={14} />
                      </button>
                    </div>

                    {originPickerOpen && (
                      <div
                        style={{
                          position: 'absolute',
                          top: '100%',
                          left: 0,
                          right: 0,
                          backgroundColor: '#FFFFFF',
                          border: '1px solid var(--color-border)',
                          borderRadius: 'var(--radius-sm)',
                          boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)',
                          zIndex: 50,
                          marginTop: '4px',
                          maxHeight: '180px',
                          overflowY: 'auto',
                          padding: '4px',
                        }}
                      >
                        {REGIONAL_HUBS.map((hub) => (
                          <div
                            key={hub}
                            onClick={() => {
                              setOrigin(hub.split(' (')[0]);
                              setOriginPickerOpen(false);
                            }}
                            style={{
                              padding: '6px 10px',
                              fontSize: '12px',
                              cursor: 'pointer',
                              borderRadius: '4px',
                            }}
                            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = 'var(--color-canvas)')}
                            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                          >
                            {hub}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Swap Button */}
                  <button
                    type="button"
                    onClick={handleSwap}
                    title="Swap Origin & Destination"
                    style={{
                      width: '34px',
                      height: '34px',
                      borderRadius: '50%',
                      border: '1px solid var(--color-border)',
                      backgroundColor: '#FFFFFF',
                      color: 'var(--color-primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      boxShadow: '0 2px 4px rgba(0,0,0,0.05)',
                      marginTop: '16px',
                    }}
                  >
                    <ArrowUpDown size={15} />
                  </button>

                  {/* Destination */}
                  <div style={{ position: 'relative' }}>
                    <label style={{ display: 'block', fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', marginBottom: '4px' }}>
                      Destination Hub
                    </label>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        height: '38px',
                        padding: '0 10px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                      }}
                    >
                      <MapPin size={15} color="var(--color-primary)" />
                      <input
                        type="text"
                        value={destination}
                        onChange={(e) => setDestination(e.target.value)}
                        onFocus={() => setDestPickerOpen(true)}
                        placeholder="Search destination..."
                        style={{
                          border: 'none',
                          outline: 'none',
                          width: '100%',
                          fontSize: '12px',
                          fontWeight: 600,
                          color: 'var(--color-text-primary)',
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => setDestPickerOpen(!destPickerOpen)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)', padding: 0 }}
                      >
                        <ChevronDown size={14} />
                      </button>
                    </div>

                    {destPickerOpen && (
                      <div
                        style={{
                          position: 'absolute',
                          top: '100%',
                          left: 0,
                          right: 0,
                          backgroundColor: '#FFFFFF',
                          border: '1px solid var(--color-border)',
                          borderRadius: 'var(--radius-sm)',
                          boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)',
                          zIndex: 50,
                          marginTop: '4px',
                          maxHeight: '180px',
                          overflowY: 'auto',
                          padding: '4px',
                        }}
                      >
                        {REGIONAL_HUBS.map((hub) => (
                          <div
                            key={hub}
                            onClick={() => {
                              setDestination(hub.split(' (')[0]);
                              setDestPickerOpen(false);
                            }}
                            style={{
                              padding: '6px 10px',
                              fontSize: '12px',
                              cursor: 'pointer',
                              borderRadius: '4px',
                            }}
                            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = 'var(--color-canvas)')}
                            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                          >
                            {hub}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

                {/* Vehicle & Cargo Row */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', marginBottom: '4px' }}>
                      <Truck size={13} color="var(--color-primary)" />
                      <span>Vehicle Profile</span>
                    </label>
                    <select
                      value={vehicle}
                      onChange={(e) => setVehicle(e.target.value)}
                      style={{
                        width: '100%',
                        height: '38px',
                        padding: '0 10px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        backgroundColor: '#FFFFFF',
                        fontSize: '12px',
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
                  </div>

                  <div>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', marginBottom: '4px' }}>
                      <Package size={13} color="var(--color-primary)" />
                      <span>Cargo Priority</span>
                    </label>
                    <select
                      value={cargo}
                      onChange={(e) => setCargo(e.target.value)}
                      style={{
                        width: '100%',
                        height: '38px',
                        padding: '0 10px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        backgroundColor: '#FFFFFF',
                        fontSize: '12px',
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
                  </div>
                </div>

                {/* Candidate Route Cards */}
                {(() => {
                  const origCoords = lookupCoords(origin, { lat: 26.1445, lng: 91.7362 });
                  const dstCoords = lookupCoords(destination, { lat: 25.5788, lng: 91.8933 });

                  const safestBreakdown = computeDetailedBreakdown({
                    lat1: origCoords.lat,
                    lon1: origCoords.lng,
                    lat2: dstCoords.lat,
                    lon2: dstCoords.lng,
                    vehicleTitle: vehicle,
                    cargoTitle: cargo,
                    isSafestRoute: true,
                  });

                  const fasterBreakdown = computeDetailedBreakdown({
                    lat1: origCoords.lat,
                    lon1: origCoords.lng,
                    lat2: dstCoords.lat,
                    lon2: dstCoords.lng,
                    vehicleTitle: vehicle,
                    cargoTitle: cargo,
                    isSafestRoute: false,
                  });

                  return (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '10px' }}>
                      {/* Route A */}
                      <div
                        onClick={() => setSelectedRoute('safest')}
                        style={{
                          padding: '12px 14px',
                          borderRadius: 'var(--radius-sm)',
                          border: selectedRoute === 'safest' ? '2px solid var(--color-primary)' : '1px solid var(--color-border)',
                          backgroundColor: selectedRoute === 'safest' ? 'var(--color-primary-bg)' : '#FFFFFF',
                          cursor: 'pointer',
                          transition: 'all var(--transition-fast)',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                          <span style={{ fontSize: '13px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                            Route A · NH-06 via Nongpoh
                          </span>
                          <span
                            style={{
                              fontSize: '9px',
                              fontWeight: 700,
                              padding: '2px 6px',
                              borderRadius: 'var(--radius-pill)',
                              backgroundColor: 'var(--color-success-bg)',
                              color: 'var(--color-success)',
                            }}
                          >
                            SAFEST
                          </span>
                        </div>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', display: 'flex', gap: '8px', flexWrap: 'wrap', alignItems: 'center' }}>
                          <strong style={{ color: 'var(--color-primary)' }}>{safestBreakdown.estimatedEtaText}</strong>
                          <span>·</span>
                          <span>{safestBreakdown.totalRoadKm} km</span>
                          <span>·</span>
                          <span style={{ color: 'var(--color-success)', fontWeight: 700 }}>14% Disruption</span>
                        </div>
                        <div style={{ marginTop: '6px' }}>
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setActiveAuditBreakdown(safestBreakdown);
                              setActiveAuditRouteName('Route A · NH-06 via Nongpoh (Safest)');
                              setAuditModalOpen(true);
                            }}
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '4px',
                              padding: '2px 7px',
                              borderRadius: 'var(--radius-pill)',
                              backgroundColor: '#E0F2FE',
                              border: '1px solid #0284C7',
                              color: '#0284C7',
                              fontSize: '10px',
                              fontWeight: 700,
                              cursor: 'pointer',
                            }}
                          >
                            <Scale size={10} />
                            <span>Clauses (+{(safestBreakdown.totalRoadKm - safestBreakdown.baseAerialKm).toFixed(1)} km)</span>
                          </button>
                        </div>
                      </div>

                      {/* Route B */}
                      <div
                        onClick={() => setSelectedRoute('faster')}
                        style={{
                          padding: '12px 14px',
                          borderRadius: 'var(--radius-sm)',
                          border: selectedRoute === 'faster' ? '2px solid #F59E0B' : '1px solid var(--color-border)',
                          backgroundColor: selectedRoute === 'faster' ? '#FFFBEB' : '#FFFFFF',
                          cursor: 'pointer',
                          transition: 'all var(--transition-fast)',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                          <span style={{ fontSize: '13px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                            Route B · Direct Hill Bypass
                          </span>
                          <span
                            style={{
                              fontSize: '9px',
                              fontWeight: 700,
                              padding: '2px 6px',
                              borderRadius: 'var(--radius-pill)',
                              backgroundColor: '#FEF3C7',
                              color: '#B45309',
                            }}
                          >
                            FASTER (-45m)
                          </span>
                        </div>
                        <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', display: 'flex', gap: '8px', flexWrap: 'wrap', alignItems: 'center' }}>
                          <strong style={{ color: '#B45309' }}>{fasterBreakdown.estimatedEtaText}</strong>
                          <span>·</span>
                          <span>{fasterBreakdown.totalRoadKm} km</span>
                          <span>·</span>
                          <span style={{ color: 'var(--color-danger)', fontWeight: 700 }}>78% Disruption</span>
                        </div>
                        <div style={{ marginTop: '6px' }}>
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setActiveAuditBreakdown(fasterBreakdown);
                              setActiveAuditRouteName('Route B · Direct Hill Bypass (Faster)');
                              setAuditModalOpen(true);
                            }}
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '4px',
                              padding: '2px 7px',
                              borderRadius: 'var(--radius-pill)',
                              backgroundColor: '#FEF3C7',
                              border: '1px solid #D97706',
                              color: '#B45309',
                              fontSize: '10px',
                              fontWeight: 700,
                              cursor: 'pointer',
                            }}
                          >
                            <Scale size={10} />
                            <span>Clauses (+{(fasterBreakdown.totalRoadKm - fasterBreakdown.baseAerialKm).toFixed(1)} km)</span>
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })()}

                {/* Confirm Action Button */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    Evaluating: {origin} ⇄ {destination}
                  </div>
                  <button
                    type="button"
                    onClick={handleConfirmRoute}
                    style={{
                      height: '38px',
                      padding: '0 16px',
                      borderRadius: 'var(--radius-sm)',
                      border: 'none',
                      backgroundColor: selectedRoute === 'safest' ? 'var(--color-primary)' : '#D97706',
                      color: '#FFFFFF',
                      fontSize: '12px',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                      boxShadow: 'var(--card-shadow)',
                    }}
                  >
                    <ShieldCheck size={15} />
                    <span>Confirm {selectedRoute === 'safest' ? 'Safest' : 'Alternative'} Route</span>
                  </button>
                </div>

                {dispatchToast && (
                  <div
                    style={{
                      padding: '10px 14px',
                      borderRadius: 'var(--radius-sm)',
                      backgroundColor: 'var(--color-success-bg)',
                      border: '1px solid var(--color-success)',
                      color: 'var(--color-success)',
                      fontSize: '12px',
                      fontWeight: 600,
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                    }}
                  >
                    <CheckCircle2 size={16} />
                    <span>{dispatchToast}</span>
                  </div>
                )}
              </div>
            ) : (
              <VectorGisMap
                originName={origin}
                destName={destination}
                originCoords={lookupCoords(origin, { lat: 26.1445, lng: 91.7362 })}
                destCoords={lookupCoords(destination, { lat: 25.5788, lng: 91.8933 })}
                routeName={selectedRoute === 'safest' ? 'Route A · NH-06 via Nongpoh (Safest)' : 'Route B · Direct Hill Bypass'}
                vehicleName={vehicle}
                cargoName={cargo}
                roleMode="official"
                height={350}
                onOpenClauses={() => {
                  const o = lookupCoords(origin, { lat: 26.1445, lng: 91.7362 });
                  const d = lookupCoords(destination, { lat: 25.5788, lng: 91.8933 });
                  const b = computeDetailedBreakdown({
                    lat1: o.lat,
                    lon1: o.lng,
                    lat2: d.lat,
                    lon2: d.lng,
                    vehicleTitle: vehicle,
                    cargoTitle: cargo,
                    isSafestRoute: selectedRoute === 'safest',
                  });
                  setActiveAuditBreakdown(b);
                  setActiveAuditRouteName(selectedRoute === 'safest' ? 'Route A · NH-06 via Nongpoh (Safest)' : 'Route B · Direct Hill Bypass');
                  setAuditModalOpen(true);
                }}
              />
            )}

          </div>

          {/* CARD 3 — Risk Factor Breakdown */}
          <div className="tiyra-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '16px' }}>
              Risk Factor Breakdown
            </h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {selectedCorridor.factors.map((f) => {
                let barColor = 'var(--color-success)';
                if (f.severity === 'AMBER') barColor = 'var(--color-warning)';
                if (f.severity === 'RED') barColor = 'var(--color-danger)';

                return (
                  <div key={f.name}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                      <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        {f.name}
                      </span>
                      <span className="mono" style={{ fontSize: '12px', fontWeight: 700, color: barColor }}>
                        {f.percentage}%
                      </span>
                    </div>

                    <div
                      style={{
                        height: '8px',
                        borderRadius: '4px',
                        backgroundColor: 'var(--color-container)',
                        overflow: 'hidden',
                        marginBottom: '4px',
                      }}
                    >
                      <div
                        style={{
                          width: `${f.percentage}%`,
                          height: '100%',
                          backgroundColor: barColor,
                        }}
                      />
                    </div>

                    <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      {f.detail}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* CARD 4 — Incident Timeline */}
          <div className="tiyra-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '16px' }}>
              Incident Timeline — Last 30 Days
            </h3>

            {selectedCorridor.incidents.length === 0 ? (
              <div style={{ padding: '24px', textAlign: 'center', color: 'var(--color-text-muted)', fontSize: '13px' }}>
                No recorded disruptions or hazard alerts in the last 30 days.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {selectedCorridor.incidents.map((inc, i) => (
                  <div
                    key={i}
                    style={{
                      display: 'flex',
                      alignItems: 'flex-start',
                      gap: '12px',
                      paddingBottom: '12px',
                      borderBottom: i < selectedCorridor.incidents.length - 1 ? '1px solid var(--color-border)' : 'none',
                    }}
                  >
                    <span className="mono" style={{ width: '80px', fontSize: '11px', color: 'var(--color-text-muted)', flexShrink: 0 }}>
                      {inc.date}
                    </span>

                    <span
                      style={{
                        width: '8px',
                        height: '8px',
                        borderRadius: '50%',
                        backgroundColor: inc.dotColor,
                        marginTop: '4px',
                        flexShrink: 0,
                      }}
                    />

                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                          {inc.title}
                        </span>
                        <span
                          style={{
                            fontSize: '10px',
                            fontWeight: 700,
                            padding: '2px 6px',
                            borderRadius: '4px',
                            backgroundColor: 'var(--color-container)',
                            color: 'var(--color-text-secondary)',
                          }}
                        >
                          {inc.status}
                        </span>
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                        Reported by: {inc.worker}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Journey Planning Modal */}
      <JourneyPlanningModal
        isOpen={isJourneyModalOpen}
        onClose={() => setIsJourneyModalOpen(false)}
        initialOrigin={origin}
        initialDestination={destination}
      />

      {/* Distance Clauses Audit Modal */}
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
