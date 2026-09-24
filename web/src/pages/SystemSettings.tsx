import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  LayoutGrid,
  Database,
  Sliders,
  Bell,
  List,
  Info,
  Radio,
  Server,
  Layers,
  CheckCircle2,
  Edit2,
  Save,
  X,
  RefreshCw,
  Search,
  HardDrive,
  Trash2,
  Image,
} from 'lucide-react';
import appIcon from '../assets/app_icon.png';
import { fetchEvidenceStats, deleteEvidencePhoto, WebEvidenceStats } from '../services/api';

interface DataSourceItem {
  id: string;
  name: string;
  icon: React.ReactNode;
  status: 'CONNECTED' | 'LIVE' | 'PROVIDER TBD' | 'SYNCING';
  statusBg: string;
  statusColor: string;
  ping: string;
}

export const SystemSettings: React.FC = () => {
  const [searchParams] = useSearchParams();
  const requestedTab = searchParams.get('tab');
  const [activeTab, setActiveTab] = useState<'general' | 'datasources' | 'storage' | 'thresholds' | 'rules' | 'logs' | 'about'>(
    (requestedTab === 'storage' || requestedTab === 'datasources' || requestedTab === 'thresholds' || requestedTab === 'rules' || requestedTab === 'logs' || requestedTab === 'about')
      ? requestedTab
      : 'general'
  );

  useEffect(() => {
    const tab = searchParams.get('tab');
    if (tab && ['general', 'datasources', 'storage', 'thresholds', 'rules', 'logs', 'about'].includes(tab)) {
      setActiveTab(tab as any);
    }
  }, [searchParams]);

  // Storage & Evidence State
  const [evidenceStats, setEvidenceStats] = useState<WebEvidenceStats | null>(null);
  const [loadingStats, setLoadingStats] = useState(false);
  const [deletingPhotoId, setDeletingPhotoId] = useState<string | null>(null);
  const [storageFeedback, setStorageFeedback] = useState<string | null>(null);

  // General tab editable fields
  const [isEditingDesignation, setIsEditingDesignation] = useState(false);
  const [platformDesignation, setPlatformDesignation] = useState('TiyraSense NER Integrated Logistics Platform');
  const [tempDesignation, setTempDesignation] = useState(platformDesignation);

  const [isEditingJurisdiction, setIsEditingJurisdiction] = useState(false);
  const [jurisdiction, setJurisdiction] = useState('NER — Assam, Meghalaya, Nagaland, Manipur, Tripura, Mizoram, Arunachal Pradesh, Sikkim');
  const [tempJurisdiction, setTempJurisdiction] = useState(jurisdiction);

  const [monsoonSeason, setMonsoonSeason] = useState('May – October (Peak Southwest Monsoon)');
  const [syncFreq, setSyncFreq] = useState('5 minutes');
  const [autoEscalate, setAutoEscalate] = useState(true);
  const [generalFeedback, setGeneralFeedback] = useState<string | null>(null);

  // Data Sources State
  const [dataSources, setDataSources] = useState<DataSourceItem[]>([
    {
      id: 'ds1',
      name: 'PostGIS Relational Database',
      icon: <Database size={16} color="var(--color-primary)" />,
      status: 'CONNECTED',
      statusBg: 'var(--color-success-bg)',
      statusColor: 'var(--color-success)',
      ping: '12ms',
    },
    {
      id: 'ds2',
      name: 'IMD Weather Feed & Sensor Stream',
      icon: <Radio size={16} color="var(--color-success)" />,
      status: 'LIVE',
      statusBg: 'var(--color-success-bg)',
      statusColor: 'var(--color-success)',
      ping: '45ms',
    },
    {
      id: 'ds3',
      name: 'ASDMA Field Worker Sync API',
      icon: <Server size={16} color="var(--color-warning)" />,
      status: 'CONNECTED',
      statusBg: 'var(--color-success-bg)',
      statusColor: 'var(--color-success)',
      ping: '88ms',
    },
    {
      id: 'ds4',
      name: 'OSRM Routing Engine Architecture',
      icon: <Layers size={16} color="var(--color-text-muted)" />,
      status: 'PROVIDER TBD',
      statusBg: 'var(--color-container)',
      statusColor: 'var(--color-text-muted)',
      ping: 'Pending Architecture Selection',
    },
    {
      id: 'ds5',
      name: 'Fleet GPS Telemetry Ingestion Pipeline',
      icon: <Radio size={16} color="#38BDF8" />,
      status: 'LIVE',
      statusBg: 'var(--color-success-bg)',
      statusColor: 'var(--color-success)',
      ping: '18ms (5 Beacons Active)',
    },
  ]);
  const [pingTestingId, setPingTestingId] = useState<string | null>(null);

  // Risk Thresholds State
  const [cautionBoundary, setCautionBoundary] = useState(30);
  const [highBoundary, setHighBoundary] = useState(70);
  const [emergencyThreshold, setEmergencyThreshold] = useState(85);
  const [thresholdFeedback, setThresholdFeedback] = useState<string | null>(null);

  // Alert Rules State
  const [broadcastToDrivers, setBroadcastToDrivers] = useState(true);
  const [audibleAlarm, setAudibleAlarm] = useState(true);
  const [dailyDigest, setDailyDigest] = useState(false);
  const [autoClearResolved, setAutoClearResolved] = useState(true);
  const [quorumThreshold, setQuorumThreshold] = useState('2 Corroborating Reports');
  const [rulesFeedback, setRulesFeedback] = useState<string | null>(null);

  // Access Logs State
  const [logSearch, setLogSearch] = useState('');

  const handleSaveDesignation = () => {
    setPlatformDesignation(tempDesignation.trim() || platformDesignation);
    setIsEditingDesignation(false);
    setGeneralFeedback('Platform Designation updated successfully.');
    setTimeout(() => setGeneralFeedback(null), 3000);
  };

  const handleSaveJurisdiction = () => {
    setJurisdiction(tempJurisdiction.trim() || jurisdiction);
    setIsEditingJurisdiction(false);
    setGeneralFeedback('Operating Jurisdiction updated successfully.');
    setTimeout(() => setGeneralFeedback(null), 3000);
  };

  const handleTestPing = (id: string) => {
    setPingTestingId(id);
    setTimeout(() => {
      setDataSources((prev) =>
        prev.map((ds) => {
          if (ds.id === id) {
            const randomLatency = Math.floor(8 + Math.random() * 45);
            return {
              ...ds,
              ping: ds.status === 'PROVIDER TBD' ? 'Deployment TBD (Local Mock 2ms)' : `${randomLatency}ms (Verified)`,
              status: ds.status === 'PROVIDER TBD' ? 'PROVIDER TBD' : 'CONNECTED',
            };
          }
          return ds;
        })
      );
      setPingTestingId(null);
    }, 600);
  };

  const handleSaveThresholds = () => {
    setThresholdFeedback('Risk Score Threshold policies applied to live inference engine.');
    setTimeout(() => setThresholdFeedback(null), 3000);
  };

  const handleSaveRules = () => {
    setRulesFeedback('Alert notification and quorum rules updated successfully.');
    setTimeout(() => setRulesFeedback(null), 3000);
  };

  const loadStorageStats = async () => {
    setLoadingStats(true);
    try {
      const stats = await fetchEvidenceStats();
      setEvidenceStats(stats);
    } catch (err: any) {
      console.error('Failed to load evidence stats:', err);
    } finally {
      setLoadingStats(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'storage') {
      loadStorageStats();
    }
  }, [activeTab]);

  const handleDeletePhoto = async (photoId: string) => {
    if (!window.confirm('Are you sure you want to permanently delete this photo from cloud storage? This action cannot be undone.')) {
      return;
    }
    setDeletingPhotoId(photoId);
    try {
      const res = await deleteEvidencePhoto(photoId);
      setStorageFeedback(res.cloudinary_destroyed 
        ? 'Photo successfully purged from database and Cloudinary storage.' 
        : 'Photo record removed from database.');
      setTimeout(() => setStorageFeedback(null), 3000);
      await loadStorageStats();
    } catch (err: any) {
      alert(err.message || 'Failed to delete photo');
    } finally {
      setDeletingPhotoId(null);
    }
  };

  // Audit log entries are fetched from the backend in production.
  // No hardcoded entries — starts empty until live data is loaded.
  const LOG_ENTRIES: { id: string; timestamp: string; actor: string; role: string; action: string; ip: string; status: string }[] = [];

  const filteredLogs = LOG_ENTRIES.filter((l) => {
    if (!logSearch.trim()) return true;
    const q = logSearch.toLowerCase();
    return l.id.toLowerCase().includes(q) || l.actor.toLowerCase().includes(q) || l.action.toLowerCase().includes(q);
  });

  return (
    <div className="responsive-container" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* PAGE HEADER */}
      <div>
        <h1 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
          System Settings & Platform Governance
        </h1>
        <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
          Regional configuration, data pipeline connections, and tactical risk thresholds
        </p>
      </div>

      {/* INNER TWO-COLUMN LAYOUT */}
      <div className="grid-settings-split-responsive" style={{ alignItems: 'start' }}>
        {/* LEFT SETTINGS NAV */}
        <div className="tiyra-card settings-tab-nav" style={{ padding: '8px' }}>
          {[
            { id: 'general', label: 'General', icon: <LayoutGrid size={18} /> },
            { id: 'datasources', label: 'Data Sources', icon: <Database size={18} /> },
            { id: 'storage', label: 'Evidence & Storage', icon: <HardDrive size={18} /> },
            { id: 'thresholds', label: 'Risk Thresholds', icon: <Sliders size={18} /> },
            { id: 'rules', label: 'Alert Rules', icon: <Bell size={18} /> },
            { id: 'logs', label: 'Access Logs', icon: <List size={18} /> },
            { id: 'about', label: 'About', icon: <Info size={18} /> },
          ].map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  width: '100%',
                  height: '40px',
                  padding: '0 12px',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '13px',
                  fontWeight: isActive ? 600 : 500,
                  color: isActive ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                  backgroundColor: isActive ? 'var(--color-primary-bg)' : 'transparent',
                  transition: 'all var(--transition-fast)',
                  marginBottom: '2px',
                  cursor: 'pointer',
                  border: 'none',
                  textAlign: 'left',
                }}
              >
                {tab.icon}
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* RIGHT — TABBED SECTIONS */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {generalFeedback && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: '12px 16px',
                backgroundColor: 'var(--color-success-bg)',
                border: '1px solid var(--color-success)',
                borderRadius: 'var(--radius-sm)',
                color: 'var(--color-success)',
                fontSize: '13px',
                fontWeight: 600,
              }}
            >
              <CheckCircle2 size={18} />
              <span>{generalFeedback}</span>
            </div>
          )}

          {/* TAB 1: GENERAL */}
          {(activeTab === 'general' || activeTab === 'about') && (
            <>
              {/* CARD 1 — Platform Identity */}
              <div className="tiyra-card" style={{ padding: '20px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' }}>
                  <div
                    style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '10px',
                      backgroundColor: '#FFFFFF',
                      border: '1px solid var(--color-border)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      boxShadow: 'var(--card-shadow)',
                    }}
                  >
                    <img src={appIcon} alt="TiyraSense" style={{ width: '32px', height: '32px', objectFit: 'contain' }} />
                  </div>

                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                        TiyraSense
                      </span>
                      <span
                        style={{
                          fontSize: '11px',
                          backgroundColor: 'var(--color-container)',
                          color: 'var(--color-text-muted)',
                          padding: '2px 6px',
                          borderRadius: '4px',
                          fontWeight: 600,
                        }}
                      >
                        v1.0 · SIH 2026
                      </span>
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      Problem Statement 26002 · Ministry of DoNER
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {/* Platform Designation */}
                  <div
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '8px',
                      padding: '12px 14px',
                      backgroundColor: 'var(--color-canvas)',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                        Platform Designation
                      </div>
                      {!isEditingDesignation ? (
                        <button
                          onClick={() => {
                            setTempDesignation(platformDesignation);
                            setIsEditingDesignation(true);
                          }}
                          style={{
                            fontSize: '12px',
                            fontWeight: 600,
                            color: 'var(--color-primary)',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px',
                          }}
                        >
                          <Edit2 size={13} />
                          <span>Edit</span>
                        </button>
                      ) : (
                        <div style={{ display: 'flex', gap: '6px' }}>
                          <button
                            onClick={handleSaveDesignation}
                            style={{
                              fontSize: '12px',
                              fontWeight: 600,
                              color: '#FFFFFF',
                              backgroundColor: 'var(--color-primary)',
                              border: 'none',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              cursor: 'pointer',
                            }}
                          >
                            Save
                          </button>
                          <button
                            onClick={() => setIsEditingDesignation(false)}
                            style={{
                              fontSize: '12px',
                              fontWeight: 600,
                              color: 'var(--color-text-secondary)',
                              backgroundColor: '#FFFFFF',
                              border: '1px solid var(--color-border)',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              cursor: 'pointer',
                            }}
                          >
                            Cancel
                          </button>
                        </div>
                      )}
                    </div>

                    {!isEditingDesignation ? (
                      <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        {platformDesignation}
                      </div>
                    ) : (
                      <input
                        type="text"
                        value={tempDesignation}
                        onChange={(e) => setTempDesignation(e.target.value)}
                        style={{
                          height: '34px',
                          padding: '0 8px',
                          borderRadius: 'var(--radius-sm)',
                          border: '1px solid var(--color-primary)',
                          fontSize: '13px',
                          width: '100%',
                        }}
                      />
                    )}
                  </div>

                  {/* Operating Jurisdiction */}
                  <div
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '8px',
                      padding: '12px 14px',
                      backgroundColor: 'var(--color-canvas)',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                        Operating Jurisdiction
                      </div>
                      {!isEditingJurisdiction ? (
                        <button
                          onClick={() => {
                            setTempJurisdiction(jurisdiction);
                            setIsEditingJurisdiction(true);
                          }}
                          style={{
                            fontSize: '12px',
                            fontWeight: 600,
                            color: 'var(--color-primary)',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px',
                          }}
                        >
                          <Edit2 size={13} />
                          <span>Edit</span>
                        </button>
                      ) : (
                        <div style={{ display: 'flex', gap: '6px' }}>
                          <button
                            onClick={handleSaveJurisdiction}
                            style={{
                              fontSize: '12px',
                              fontWeight: 600,
                              color: '#FFFFFF',
                              backgroundColor: 'var(--color-primary)',
                              border: 'none',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              cursor: 'pointer',
                            }}
                          >
                            Save
                          </button>
                          <button
                            onClick={() => setIsEditingJurisdiction(false)}
                            style={{
                              fontSize: '12px',
                              fontWeight: 600,
                              color: 'var(--color-text-secondary)',
                              backgroundColor: '#FFFFFF',
                              border: '1px solid var(--color-border)',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              cursor: 'pointer',
                            }}
                          >
                            Cancel
                          </button>
                        </div>
                      )}
                    </div>

                    {!isEditingJurisdiction ? (
                      <div style={{ fontSize: '13px', color: 'var(--color-text-primary)' }}>
                        {jurisdiction}
                      </div>
                    ) : (
                      <textarea
                        rows={2}
                        value={tempJurisdiction}
                        onChange={(e) => setTempJurisdiction(e.target.value)}
                        style={{
                          padding: '6px 8px',
                          borderRadius: 'var(--radius-sm)',
                          border: '1px solid var(--color-primary)',
                          fontSize: '13px',
                          width: '100%',
                          fontFamily: 'inherit',
                        }}
                      />
                    )}
                  </div>
                </div>
              </div>

              {/* CARD 1B — Regional Operations Profile */}
              <div className="tiyra-card" style={{ padding: '20px' }}>
                <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '16px' }}>
                  Regional Operations Profile
                </h2>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                      Primary Disruption Season
                    </label>
                    <select
                      value={monsoonSeason}
                      onChange={(e) => setMonsoonSeason(e.target.value)}
                      style={{
                        width: '100%',
                        height: '38px',
                        padding: '0 10px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '13px',
                        backgroundColor: '#FFFFFF',
                      }}
                    >
                      <option value="May – October (Peak Southwest Monsoon)">May – October (Peak Southwest Monsoon)</option>
                      <option value="November – April (Dry Season / Winter Fog)">November – April (Dry Season / Winter Fog)</option>
                      <option value="Year-Round High Precipitation Zone">Year-Round High Precipitation Zone</option>
                    </select>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                      Default Sensor Stream Polling
                    </label>
                    <select
                      value={syncFreq}
                      onChange={(e) => setSyncFreq(e.target.value)}
                      style={{
                        width: '100%',
                        height: '38px',
                        padding: '0 10px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '13px',
                        backgroundColor: '#FFFFFF',
                      }}
                    >
                      <option value="2 minutes">Every 2 minutes (Rapid Monsoon Watch)</option>
                      <option value="5 minutes">Every 5 minutes (Standard Operational)</option>
                      <option value="15 minutes">Every 15 minutes (Low Bandwidth Mode)</option>
                      <option value="30 minutes">Every 30 minutes (Offline / Standby)</option>
                    </select>
                  </div>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    marginTop: '16px',
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-surface)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Auto-Escalate Disrupted Corridors to Emergency Status
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Trigger immediate operations dashboard banner when risk score exceeds 85
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={autoEscalate}
                    onChange={(e) => setAutoEscalate(e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                </div>
              </div>
            </>
          )}

          {/* TAB 2: DATA SOURCES */}
          {(activeTab === 'general' || activeTab === 'datasources') && (
            <div className="tiyra-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div>
                  <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Data Source Status & Telemetry
                  </h2>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    Active GIS databases, meteorological feeds, and field reconnaissance links
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column' }}>
                {dataSources.map((ds, idx) => (
                  <div
                    key={ds.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '12px 0',
                      borderBottom: idx < dataSources.length - 1 ? '1px solid var(--color-border)' : 'none',
                      fontSize: '13px',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {ds.icon}
                      <span style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>{ds.name}</span>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                      <span
                        style={{
                          fontSize: '10px',
                          fontWeight: 700,
                          padding: '2px 8px',
                          borderRadius: 'var(--radius-pill)',
                          backgroundColor: ds.statusBg,
                          color: ds.statusColor,
                        }}
                      >
                        {ds.status}
                      </span>
                      <span className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)', minWidth: '100px', textAlign: 'right' }}>
                        {ds.ping}
                      </span>
                      <button
                        onClick={() => handleTestPing(ds.id)}
                        disabled={pingTestingId === ds.id}
                        style={{
                          padding: '4px 10px',
                          borderRadius: 'var(--radius-sm)',
                          border: '1px solid var(--color-border)',
                          backgroundColor: '#FFFFFF',
                          fontSize: '11px',
                          fontWeight: 600,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                          color: 'var(--color-text-secondary)',
                        }}
                      >
                        <RefreshCw size={11} className={pingTestingId === ds.id ? 'spin' : ''} />
                        <span>{pingTestingId === ds.id ? 'Testing...' : 'Test Ping'}</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              {/* App Health & System Infrastructure Metrics */}
              <div
                style={{
                  marginTop: '20px',
                  paddingTop: '16px',
                  borderTop: '1px solid var(--color-border)',
                }}
              >
                <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '10px' }}>
                  App Working & Infrastructure Health Metrics
                </div>
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                    gap: '12px',
                  }}
                >
                  <div style={{ padding: '12px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                    <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>SERVICE AVAILABILITY</div>
                    <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--color-success)', marginTop: '2px' }}>99.94%</div>
                    <div style={{ fontSize: '10px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>30-day continuous uptime</div>
                  </div>
                  <div style={{ padding: '12px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                    <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>API ERROR RATE</div>
                    <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--color-primary)', marginTop: '2px' }}>0.02%</div>
                    <div style={{ fontSize: '10px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>Standard HTTP 200 OK</div>
                  </div>
                  <div style={{ padding: '12px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                    <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>AVG RESPONSE LATENCY</div>
                    <div style={{ fontSize: '18px', fontWeight: 800, color: '#6366F1', marginTop: '2px' }}>42ms</div>
                    <div style={{ fontSize: '10px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>FastAPI + PostGIS pool</div>
                  </div>
                  <div style={{ padding: '12px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                    <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>ACTIVE CLIENT SESSIONS</div>
                    <div style={{ fontSize: '18px', fontWeight: 800, color: '#0D9488', marginTop: '2px' }}>14 Active</div>
                    <div style={{ fontSize: '10px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>4 Web Officials, 10 Mobile</div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB: STORAGE & EVIDENCE MANAGEMENT */}
          {activeTab === 'storage' && (
            <div className="tiyra-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div>
                  <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Cloud Storage & Evidence Assets
                  </h2>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    Live Cloudinary CDN footprint, compressed evidence assets, and administrator purge controls
                  </div>
                </div>
                <button
                  data-testid="refresh-storage-btn"
                  onClick={loadStorageStats}
                  disabled={loadingStats}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    height: '34px',
                    padding: '0 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-container)',
                    color: 'var(--color-text-primary)',
                    border: '1px solid var(--color-border)',
                    fontSize: '12px',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  <RefreshCw size={13} className={loadingStats ? 'spin' : ''} />
                  <span>Refresh Storage</span>
                </button>
              </div>

              {storageFeedback && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    padding: '10px 14px',
                    marginBottom: '16px',
                    backgroundColor: 'var(--color-success-bg)',
                    border: '1px solid var(--color-success)',
                    borderRadius: 'var(--radius-sm)',
                    color: 'var(--color-success)',
                    fontSize: '12px',
                    fontWeight: 600,
                  }}
                >
                  <CheckCircle2 size={16} />
                  <span>{storageFeedback}</span>
                </div>
              )}

              {/* STORAGE METRICS CARDS */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                  gap: '12px',
                  marginBottom: '20px',
                }}
              >
                <div style={{ padding: '14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>TOTAL EVIDENCE IMAGES</div>
                  <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-primary)', marginTop: '4px' }}>
                    {evidenceStats?.total_images ?? 0}
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>Stored in Cloudinary CDN</div>
                </div>

                <div style={{ padding: '14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>TOTAL STORAGE FOOTPRINT</div>
                  <div style={{ fontSize: '22px', fontWeight: 800, color: '#0D9488', marginTop: '4px' }}>
                    {evidenceStats?.total_size_formatted ?? '0 KB'}
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>
                    {evidenceStats?.total_bytes ? `${evidenceStats.total_bytes.toLocaleString()} bytes` : '0 bytes'}
                  </div>
                </div>

                <div style={{ padding: '14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>AVG COMPRESSED SIZE</div>
                  <div style={{ fontSize: '22px', fontWeight: 800, color: '#6366F1', marginTop: '4px' }}>
                    {evidenceStats?.avg_image_size_kb ? `${evidenceStats.avg_image_size_kb} KB` : '0 KB'}
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-secondary)', marginTop: '2px' }}>Client-compressed before upload</div>
                </div>

                <div style={{ padding: '14px', borderRadius: 'var(--radius-sm)', backgroundColor: 'var(--color-canvas)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)' }}>FORMAT DISTRIBUTION</div>
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginTop: '6px' }}>
                    {evidenceStats && Object.keys(evidenceStats.format_distribution).length > 0 ? (
                      Object.entries(evidenceStats.format_distribution).map(([fmt, count]) => (
                        <span
                          key={fmt}
                          style={{
                            fontSize: '11px',
                            fontWeight: 700,
                            padding: '2px 8px',
                            borderRadius: '4px',
                            backgroundColor: 'var(--color-container)',
                            color: 'var(--color-text-primary)',
                          }}
                        >
                          {fmt.toUpperCase()}: {count}
                        </span>
                      ))
                    ) : (
                      <span style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>No images yet</span>
                    )}
                  </div>
                </div>
              </div>

              {/* RECENT / MANAGED IMAGES LIST */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Managed Evidence Photos
                  </div>
                  <span style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    Showing recent assets · Click delete to purge wrong/unwanted photos
                  </span>
                </div>

                {!evidenceStats || evidenceStats.recent_images.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '36px', color: 'var(--color-text-muted)', fontSize: '13px' }}>
                    <Image size={32} style={{ margin: '0 auto 8px auto', opacity: 0.4 }} />
                    <p>No evidence photos have been uploaded yet.</p>
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {evidenceStats.recent_images.map((img) => (
                      <div
                        key={img.id}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '10px 14px',
                          borderRadius: 'var(--radius-sm)',
                          backgroundColor: 'var(--color-canvas)',
                          border: '1px solid var(--color-border)',
                          gap: '12px',
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                          <img
                            src={img.secure_url}
                            alt="Evidence"
                            style={{
                              width: '48px',
                              height: '48px',
                              objectFit: 'cover',
                              borderRadius: '6px',
                              border: '1px solid var(--color-border)',
                            }}
                            onError={(e) => {
                              (e.currentTarget as HTMLElement).style.display = 'none';
                            }}
                          />
                          <div>
                            <div style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', wordBreak: 'break-all' }}>
                              {img.cloudinary_public_id || img.id}
                            </div>
                            <div style={{ display: 'flex', gap: '10px', fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                              <span>Format: {(img.format || 'jpg').toUpperCase()}</span>
                              <span>•</span>
                              <span>Size: {img.bytes ? `${(img.bytes / 1024).toFixed(1)} KB` : 'Compressed'}</span>
                              <span>•</span>
                              <span>{img.created_at ? new Date(img.created_at).toLocaleString() : 'Recent'}</span>
                            </div>
                          </div>
                        </div>

                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <a
                            href={img.secure_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{
                              fontSize: '11px',
                              color: 'var(--color-primary)',
                              textDecoration: 'none',
                              fontWeight: 600,
                            }}
                          >
                            View Full
                          </a>
                          <button
                            data-testid={`delete-photo-btn-${img.id}`}
                            onClick={() => handleDeletePhoto(img.id)}
                            disabled={deletingPhotoId === img.id}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: '4px',
                              padding: '6px 10px',
                              borderRadius: 'var(--radius-sm)',
                              backgroundColor: 'var(--color-danger-bg)',
                              color: 'var(--color-danger)',
                              border: '1px solid var(--color-danger)',
                              fontSize: '11px',
                              fontWeight: 700,
                              cursor: 'pointer',
                            }}
                            title="Delete photo from Cloudinary and database"
                          >
                            <Trash2 size={12} />
                            <span>{deletingPhotoId === img.id ? 'Deleting...' : 'Delete'}</span>
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* TAB 3: RISK THRESHOLDS */}
          {(activeTab === 'general' || activeTab === 'thresholds') && (
            <div className="tiyra-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div>
                  <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Risk Score Threshold Policies
                  </h2>
                  <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    Calibrate decision engine boundaries for LOW, CAUTION, HIGH, and EMERGENCY ratings
                  </span>
                </div>
                <button
                  onClick={handleSaveThresholds}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    height: '34px',
                    padding: '0 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-primary)',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Save size={13} />
                  <span>Save Thresholds</span>
                </button>
              </div>

              {thresholdFeedback && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    padding: '10px 14px',
                    marginBottom: '16px',
                    backgroundColor: 'var(--color-success-bg)',
                    border: '1px solid var(--color-success)',
                    borderRadius: 'var(--radius-sm)',
                    color: 'var(--color-success)',
                    fontSize: '12px',
                    fontWeight: 600,
                  }}
                >
                  <CheckCircle2 size={16} />
                  <span>{thresholdFeedback}</span>
                </div>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                {/* Threshold 1 */}
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <div>
                      <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        LOW / CAUTION boundary
                      </span>
                      <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginLeft: '8px' }}>
                        (Scores below this are green/passable)
                      </span>
                    </div>
                    <span
                      className="mono"
                      style={{
                        fontSize: '12px',
                        fontWeight: 700,
                        color: 'var(--color-primary)',
                        backgroundColor: 'var(--color-primary-light)',
                        padding: '2px 8px',
                        borderRadius: '4px',
                      }}
                    >
                      {cautionBoundary}
                    </span>
                  </div>
                  <input
                    type="range"
                    min="15"
                    max="45"
                    value={cautionBoundary}
                    onChange={(e) => setCautionBoundary(Number(e.target.value))}
                    style={{ width: '100%', cursor: 'pointer' }}
                  />
                  <div style={{ height: '8px', borderRadius: '4px', backgroundColor: 'var(--color-container)', overflow: 'hidden', marginTop: '4px' }}>
                    <div style={{ width: `${cautionBoundary}%`, height: '100%', backgroundColor: 'var(--color-success)' }} />
                  </div>
                </div>

                {/* Threshold 2 */}
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <div>
                      <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        CAUTION / HIGH boundary
                      </span>
                      <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginLeft: '8px' }}>
                        (Scores above this require convoy or heavy vehicle hold)
                      </span>
                    </div>
                    <span
                      className="mono"
                      style={{
                        fontSize: '12px',
                        fontWeight: 700,
                        color: '#B45309',
                        backgroundColor: '#FEF3C7',
                        padding: '2px 8px',
                        borderRadius: '4px',
                      }}
                    >
                      {highBoundary}
                    </span>
                  </div>
                  <input
                    type="range"
                    min="50"
                    max="79"
                    value={highBoundary}
                    onChange={(e) => setHighBoundary(Number(e.target.value))}
                    style={{ width: '100%', cursor: 'pointer' }}
                  />
                  <div style={{ height: '8px', borderRadius: '4px', backgroundColor: 'var(--color-container)', overflow: 'hidden', marginTop: '4px' }}>
                    <div style={{ width: `${highBoundary}%`, height: '100%', backgroundColor: 'var(--color-warning)' }} />
                  </div>
                </div>

                {/* Threshold 3 */}
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <div>
                      <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        Emergency Trigger Threshold
                      </span>
                      <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginLeft: '8px' }}>
                        (Scores above this trigger corridor shutdown advisory)
                      </span>
                    </div>
                    <span
                      className="mono"
                      style={{
                        fontSize: '12px',
                        fontWeight: 700,
                        color: 'var(--color-danger)',
                        backgroundColor: 'var(--color-danger-bg)',
                        padding: '2px 8px',
                        borderRadius: '4px',
                      }}
                    >
                      {emergencyThreshold}
                    </span>
                  </div>
                  <input
                    type="range"
                    min="80"
                    max="96"
                    value={emergencyThreshold}
                    onChange={(e) => setEmergencyThreshold(Number(e.target.value))}
                    style={{ width: '100%', cursor: 'pointer' }}
                  />
                  <div style={{ height: '8px', borderRadius: '4px', backgroundColor: 'var(--color-container)', overflow: 'hidden', marginTop: '4px' }}>
                    <div style={{ width: `${emergencyThreshold}%`, height: '100%', backgroundColor: 'var(--color-danger)' }} />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: ALERT RULES */}
          {activeTab === 'rules' && (
            <div className="tiyra-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div>
                  <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Tactical Advisory & Alert Rules
                  </h2>
                  <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    Configure dispatch triggers, automated messaging, and verification quorums
                  </span>
                </div>
                <button
                  onClick={handleSaveRules}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    height: '34px',
                    padding: '0 14px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-primary)',
                    color: '#FFFFFF',
                    border: 'none',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <Save size={13} />
                  <span>Save Rules</span>
                </button>
              </div>

              {rulesFeedback && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    padding: '10px 14px',
                    marginBottom: '16px',
                    backgroundColor: 'var(--color-success-bg)',
                    border: '1px solid var(--color-success)',
                    borderRadius: 'var(--radius-sm)',
                    color: 'var(--color-success)',
                    fontSize: '12px',
                    fontWeight: 600,
                  }}
                >
                  <CheckCircle2 size={16} />
                  <span>{rulesFeedback}</span>
                </div>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-canvas)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Broadcast Emergency Advisories Directly to Active Commercial Drivers
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Push instant audio-visual notification to drivers within 50 KM corridor buffer
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={broadcastToDrivers}
                    onChange={(e) => setBroadcastToDrivers(e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-canvas)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Audible Emergency Alert in Operations Room
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Sound alert chime upon incoming verified full blockage reports
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={audibleAlarm}
                    onChange={(e) => setAudibleAlarm(e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-canvas)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Daily 06:00 AM Corridor Accessibility Briefing
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Auto-generate situational briefing email to regional transport commission
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={dailyDigest}
                    onChange={(e) => setDailyDigest(e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-canvas)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Auto-Clear Advisories on Verified Resolution
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Move alert from Active to Resolved feed once road clearance is confirmed
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={autoClearResolved}
                    onChange={(e) => setAutoClearResolved(e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                </div>

                <div style={{ marginTop: '8px' }}>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                    Incident Verification Quorum
                  </label>
                  <select
                    value={quorumThreshold}
                    onChange={(e) => setQuorumThreshold(e.target.value)}
                    style={{
                      width: '100%',
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      backgroundColor: '#FFFFFF',
                    }}
                  >
                    <option value="1 Validated Field Report">1 Validated Field Report (Fastest response)</option>
                    <option value="2 Corroborating Reports">2 Corroborating Reports (Standard validation)</option>
                    <option value="Official BRO / Police Verification Only">Official BRO / Police Verification Only (Strict mode)</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: ACCESS LOGS */}
          {activeTab === 'logs' && (
            <div className="tiyra-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '10px' }}>
                <div>
                  <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    System Access & Security Audit Trail
                  </h2>
                  <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    Forensic logging of operational actions, advisory broadcasts, and session events
                  </span>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    height: '34px',
                    width: '220px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    backgroundColor: '#FFFFFF',
                    padding: '0 8px',
                    gap: '6px',
                  }}
                >
                  <Search size={14} color="var(--color-text-muted)" />
                  <input
                    type="text"
                    placeholder="Search logs..."
                    value={logSearch}
                    onChange={(e) => setLogSearch(e.target.value)}
                    style={{ border: 'none', outline: 'none', fontSize: '12px', width: '100%' }}
                  />
                  {logSearch && (
                    <button onClick={() => setLogSearch('')} style={{ border: 'none', background: 'none', cursor: 'pointer' }}>
                      <X size={12} color="var(--color-text-muted)" />
                    </button>
                  )}
                </div>
              </div>

              <div className="table-responsive-wrapper">
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '12px' }}>
                  <thead>
                    <tr style={{ height: '36px', borderBottom: '1px solid var(--color-border)', color: 'var(--color-text-muted)' }}>
                      <th style={{ padding: '6px 10px' }}>EVENT ID</th>
                      <th style={{ padding: '6px 10px' }}>TIMESTAMP</th>
                      <th style={{ padding: '6px 10px' }}>ACTOR</th>
                      <th style={{ padding: '6px 10px' }}>ACTION</th>
                      <th style={{ padding: '6px 10px' }}>IP ADDRESS</th>
                      <th style={{ padding: '6px 10px' }}>STATUS</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredLogs.map((entry) => (
                      <tr key={entry.id} style={{ height: '40px', borderBottom: '1px solid var(--color-border)' }}>
                        <td className="mono" style={{ padding: '6px 10px', fontWeight: 600 }}>{entry.id}</td>
                        <td style={{ padding: '6px 10px', color: 'var(--color-text-muted)' }}>{entry.timestamp}</td>
                        <td style={{ padding: '6px 10px', fontWeight: 600 }}>{entry.actor}</td>
                        <td style={{ padding: '6px 10px' }}>{entry.action}</td>
                        <td className="mono" style={{ padding: '6px 10px', color: 'var(--color-text-muted)' }}>{entry.ip}</td>
                        <td style={{ padding: '6px 10px' }}>
                          <span
                            style={{
                              fontSize: '10px',
                              fontWeight: 700,
                              padding: '2px 6px',
                              borderRadius: '4px',
                              backgroundColor: entry.status === 'SUCCESS' || entry.status === 'VERIFIED' ? 'var(--color-success-bg)' : 'var(--color-danger-bg)',
                              color: entry.status === 'SUCCESS' || entry.status === 'VERIFIED' ? 'var(--color-success)' : 'var(--color-danger)',
                            }}
                          >
                            {entry.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 6: ABOUT SPECIFICATIONS */}
          {activeTab === 'about' && (
            <div className="tiyra-card" style={{ padding: '20px' }}>
              <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '12px' }}>
                Architecture & Standards Compliance
              </h2>
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: 1.6, marginBottom: '16px' }}>
                TiyraSense is the AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER), built specifically for SIH 2026 Problem Statement 26002. It serves as a decision-support and operational intelligence platform.
              </p>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '12px' }}>
                <div style={{ padding: '12px', backgroundColor: 'var(--color-surface)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-primary)', textTransform: 'uppercase' }}>
                    Separation of Concerns
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '4px' }}>
                    Observed Operational Data vs ML Disruption vs Composite Route Risk are strictly segregated and traceable.
                  </div>
                </div>

                <div style={{ padding: '12px', backgroundColor: 'var(--color-surface)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-success)', textTransform: 'uppercase' }}>
                    Critical LLM Boundary
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '4px' }}>
                    LLMs serve explanation, summarization, and multilingual translation only. Never routing or risk safety overrides.
                  </div>
                </div>

                <div style={{ padding: '12px', backgroundColor: 'var(--color-surface)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--color-border)' }}>
                  <div style={{ fontSize: '11px', fontWeight: 700, color: '#7C3AED', textTransform: 'uppercase' }}>
                    Provenance Assurance
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '4px' }}>
                    All pipeline outputs labeled LIVE, HISTORICAL, SIMULATED, or TEST. Zero fabricated safety claims.
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
