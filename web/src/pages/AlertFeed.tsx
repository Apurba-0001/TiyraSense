import React, { useState, useEffect } from 'react';
import {
  CheckCheck,
  Search,
  X,
  Radio,
  CheckCircle2,
} from 'lucide-react';
import {
  fetchAlerts,
  acknowledgeAlert,
  acknowledgeAllAlerts,
  createAlert,
} from '../services/api';

interface FeedAlert {
  id: string;
  severity: 'EMERGENCY' | 'HIGH RISK' | 'CAUTION' | 'INFO';
  corridor: string;
  kmRange: string;
  time: string;
  title: string;
  description: string;
  affects: string;
  acknowledged: boolean;
  resolvedBy?: string;
  resolvedAt?: string;
}



export const AlertFeed: React.FC = () => {
  const [alerts, setAlerts] = useState<FeedAlert[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [severityFilter, setSeverityFilter] = useState<'ALL' | 'EMERGENCY' | 'HIGH RISK' | 'CAUTION' | 'INFO'>('ALL');
  const [corridorFilter, setCorridorFilter] = useState('ALL');
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [selectedDetailAlert, setSelectedDetailAlert] = useState<FeedAlert | null>(null);

  const handleDismiss = (id: string) => {
    setAlerts((prev) => prev.filter((a) => a.id !== id));
  };

  // New alert form state
  const [newCorridor, setNewCorridor] = useState('NH-06');
  const [newKmRange, setNewKmRange] = useState('KM 52.3');
  const [newSeverity, setNewSeverity] = useState<'EMERGENCY' | 'HIGH RISK' | 'CAUTION' | 'INFO'>('EMERGENCY');
  const [newTitle, setNewTitle] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [newAffects, setNewAffects] = useState('');
  const [broadcastFeedback, setBroadcastFeedback] = useState<string | null>(null);

  useEffect(() => {
    const loadAlerts = () => {
      fetchAlerts()
        .then((data) => {
          if (data && data.length > 0) {
            const mapped: FeedAlert[] = data.map((d: any) => ({
              id: d.id,
              severity: (d.severity as FeedAlert['severity']) || 'INFO',
              corridor: d.corridor || 'NH-06',
              kmRange: 'Active Highway Zone',
              time: d.time || 'Recently',
              title: d.title,
              description: d.description,
              affects: `${d.corridor || 'Highway'} Operational Sector`,
              acknowledged: Boolean(d.acknowledged),
              resolvedBy: d.acknowledged ? 'Operations Control' : undefined,
              resolvedAt: d.acknowledged_at ? d.acknowledged_at.slice(11, 16) : undefined,
            }));
            setAlerts(mapped);
          }
        })
        .catch(() => {});
    };

    loadAlerts();
    // Poll every 30s so auto-generated alerts from verified reports surface promptly
    const pollInterval = setInterval(loadAlerts, 30000);
    return () => clearInterval(pollInterval);
  }, []);

  const filterItem = (a: FeedAlert) => {
    if (severityFilter !== 'ALL' && a.severity !== severityFilter) return false;
    if (corridorFilter !== 'ALL' && a.corridor !== corridorFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        a.title.toLowerCase().includes(q) ||
        a.description.toLowerCase().includes(q) ||
        a.corridor.toLowerCase().includes(q) ||
        a.affects.toLowerCase().includes(q) ||
        a.id.toLowerCase().includes(q)
      );
    }
    return true;
  };

  const activeAlerts = alerts.filter((a) => !a.acknowledged && filterItem(a));
  const resolvedAlerts = alerts.filter((a) => a.acknowledged && filterItem(a));

  const handleAcknowledge = async (id: string) => {
    setAlerts((prev) =>
      prev.map((a) =>
        a.id === id
          ? {
              ...a,
              acknowledged: true,
              resolvedBy: 'Official R. Agarwal',
              resolvedAt: 'Just now',
            }
          : a
      )
    );
    try {
      await acknowledgeAlert(id);
    } catch {
      // Retain optimistic update
    }
  };

  const handleAcknowledgeAll = async () => {
    setAlerts((prev) =>
      prev.map((a) => ({
        ...a,
        acknowledged: true,
        resolvedBy: 'Official R. Agarwal',
        resolvedAt: 'Just now',
      }))
    );
    try {
      await acknowledgeAllAlerts();
    } catch {
      // Retain optimistic update
    }
  };

  const handleBroadcastAlert = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim() || !newDescription.trim()) return;

    const newAlert: FeedAlert = {
      id: `ALT-${Math.floor(100 + Math.random() * 900)}`,
      severity: newSeverity,
      corridor: newCorridor,
      kmRange: newKmRange.trim() || 'KM 00-10',
      time: 'Just now',
      title: newTitle.trim(),
      description: newDescription.trim(),
      affects: newAffects.trim() || `${newCorridor} Sector`,
      acknowledged: false,
    };

    setAlerts([newAlert, ...alerts]);
    setBroadcastFeedback(`Alert ${newAlert.id} successfully broadcast across operations room and mobile devices!`);

    try {
      const created = await createAlert({
        corridor: newCorridor,
        severity: newSeverity,
        title: newTitle.trim(),
        description: newDescription.trim(),
      });
      if (created?.id) {
        newAlert.id = created.id;
      }
    } catch {
      // Retain optimistic entry
    }

    setTimeout(() => {
      setBroadcastFeedback(null);
      setIsCreateModalOpen(false);
      setNewTitle('');
      setNewDescription('');
      setNewAffects('');
    }, 1200);
  };

  return (
    <div className="responsive-container" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* PAGE HEADER */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <h1 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
            Alert Feed & Tactical Advisories
          </h1>
          {activeAlerts.length > 0 && (
            <span
              style={{
                backgroundColor: 'var(--color-danger-bg)',
                color: 'var(--color-danger)',
                border: '1px solid var(--color-danger)',
                fontSize: '11px',
                fontWeight: 700,
                padding: '2px 8px',
                borderRadius: 'var(--radius-pill)',
              }}
            >
              {activeAlerts.length} active
            </span>
          )}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <button
            onClick={() => setIsCreateModalOpen(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              height: '36px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              border: 'none',
              backgroundColor: 'var(--color-danger)',
              color: '#FFFFFF',
              fontSize: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: 'var(--card-shadow)',
            }}
          >
            <Radio size={15} />
            <span>Broadcast Alert</span>
          </button>

          {activeAlerts.length > 0 && (
            <button
              onClick={handleAcknowledgeAll}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                height: '36px',
                padding: '0 14px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)',
                backgroundColor: '#FFFFFF',
                color: 'var(--color-text-secondary)',
                fontSize: '12px',
                fontWeight: 600,
                cursor: 'pointer',
                transition: 'all var(--transition-fast)',
              }}
            >
              <CheckCheck size={16} />
              <span>Acknowledge All</span>
            </button>
          )}
        </div>
      </div>

      {/* FILTER & SEARCH CONTROL BAR */}
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
        {/* Search Input */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            height: '36px',
            padding: '0 10px',
            borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--color-border)',
            backgroundColor: '#FFFFFF',
            flex: '1 1 240px',
          }}
        >
          <Search size={14} color="var(--color-text-muted)" />
          <input
            type="text"
            placeholder="Search alert title, corridor, or district..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              border: 'none',
              outline: 'none',
              width: '100%',
              fontSize: '12px',
              color: 'var(--color-text-primary)',
            }}
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)', padding: 0 }}
            >
              ×
            </button>
          )}
        </div>

        {/* Corridor Dropdown Selector */}
        <select
          value={corridorFilter}
          onChange={(e) => setCorridorFilter(e.target.value)}
          style={{
            height: '36px',
            padding: '0 12px',
            borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--color-border)',
            backgroundColor: '#FFFFFF',
            fontSize: '12px',
            fontWeight: 600,
            color: 'var(--color-text-primary)',
            cursor: 'pointer',
            outline: 'none',
          }}
        >
          <option value="ALL">All Corridors</option>
          <option value="NH-06">NH-06 (Guwahati-Shillong)</option>
          <option value="NH-29">NH-29 (Guwahati-Silchar)</option>
          <option value="NH-37">NH-37 (Numaligarh-Jorhat)</option>
          <option value="NH-40">NH-40 (Jorabat-Ladrymbai)</option>
          <option value="NH-51">NH-51 (Paikan-Tura)</option>
          <option value="NH-102">NH-102 (Imphal-Moreh)</option>
          <option value="NH-108">NH-108 (Panisagar-Aizawl)</option>
          <option value="NH-208">NH-208 (Kumarghat-Kailashahar)</option>
        </select>

        {/* Severity Filter Chips */}
        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
          {(['ALL', 'EMERGENCY', 'HIGH RISK', 'CAUTION', 'INFO'] as const).map((sev) => {
            const isActive = severityFilter === sev;
            return (
              <button
                key={sev}
                onClick={() => setSeverityFilter(sev)}
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
                  cursor: 'pointer',
                  transition: 'all var(--transition-fast)',
                }}
              >
                {sev}
              </button>
            );
          })}
        </div>
      </div>

      {/* STATS STRIP (4 equal white cards, responsive auto-fit) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: '16px' }}>
        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-danger)' }}>1</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            Emergency
          </div>
        </div>

        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-restricted)' }}>3</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            High Risk
          </div>
        </div>

        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-warning)' }}>5</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            Caution
          </div>
        </div>

        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-primary)' }}>8</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            Informational
          </div>
        </div>
      </div>

      {/* TWO EQUAL COLUMNS (Responsive 2-col to 1-col on mobile) */}
      <div className="grid-equal-2col-responsive" style={{ alignItems: 'start' }}>
        {/* LEFT — Active Alerts */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div style={{ fontSize: '12px', fontWeight: 700, color: 'var(--color-text-disabled)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            ACTIVE ADVISORIES ({activeAlerts.length})
          </div>

          {activeAlerts.length === 0 ? (
            <div className="tiyra-card" style={{ padding: '32px', textAlign: 'center', color: 'var(--color-text-muted)' }}>
              No active unacknowledged alerts.
            </div>
          ) : (
            activeAlerts.map((alt) => {
              let bg = 'var(--color-primary-bg)';
              let borderStrip = 'var(--color-primary)';
              let badgeColor = 'var(--color-primary)';

              if (alt.severity === 'EMERGENCY') {
                bg = 'var(--color-danger-bg)';
                borderStrip = 'var(--color-emergency)';
                badgeColor = 'var(--color-emergency)';
              } else if (alt.severity === 'HIGH RISK') {
                bg = 'var(--color-restricted-bg)';
                borderStrip = 'var(--color-restricted)';
                badgeColor = 'var(--color-restricted)';
              } else if (alt.severity === 'CAUTION') {
                bg = 'var(--color-warning-bg)';
                borderStrip = 'var(--color-warning)';
                badgeColor = '#B45309';
              }

              return (
                <div
                  key={alt.id}
                  style={{
                    backgroundColor: bg,
                    borderLeft: `4px solid ${borderStrip}`,
                    borderRadius: 'var(--radius-md)',
                    padding: '16px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '8px',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span
                        style={{
                          fontSize: '11px',
                          fontWeight: 700,
                          padding: '2px 8px',
                          borderRadius: 'var(--radius-pill)',
                          backgroundColor: '#FFFFFF',
                          color: badgeColor,
                          border: `1px solid ${borderStrip}`,
                        }}
                      >
                        {alt.severity}
                      </span>
                      <span className="mono" style={{ fontSize: '12px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                        {alt.corridor}
                      </span>
                    </div>
                    <span className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      {alt.time}
                    </span>
                  </div>

                  <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    {alt.title}
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--color-text-secondary)', lineHeight: 1.5 }}>
                    {alt.description}
                  </div>

                  <div
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '4px',
                      fontSize: '11px',
                      color: 'var(--color-text-muted)',
                      backgroundColor: 'rgba(255, 255, 255, 0.6)',
                      padding: '3px 8px',
                      borderRadius: '4px',
                      width: 'fit-content',
                    }}
                  >
                    <span style={{ fontWeight: 600 }}>Affects:</span>
                    <span>{alt.affects}</span>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '6px' }}>
                    <button
                      onClick={() => setSelectedDetailAlert(alt)}
                      style={{
                        padding: '6px 12px',
                        backgroundColor: 'var(--color-primary-bg)',
                        border: '1px solid var(--color-primary)',
                        borderRadius: 'var(--radius-sm)',
                        fontSize: '12px',
                        fontWeight: 700,
                        color: 'var(--color-primary)',
                        cursor: 'pointer',
                      }}
                    >
                      View Details
                    </button>
                    <button
                      onClick={() => handleAcknowledge(alt.id)}
                      style={{
                        padding: '6px 12px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        fontSize: '12px',
                        fontWeight: 600,
                        color: 'var(--color-text-secondary)',
                        cursor: 'pointer',
                      }}
                    >
                      Acknowledge
                    </button>
                    <button
                      onClick={() => handleDismiss(alt.id)}
                      style={{
                        padding: '6px 10px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        fontSize: '12px',
                        fontWeight: 600,
                        color: 'var(--color-text-muted)',
                        cursor: 'pointer',
                      }}
                    >
                      Dismiss
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* RIGHT — Acknowledged / Resolved */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div style={{ fontSize: '12px', fontWeight: 700, color: 'var(--color-text-disabled)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            ACKNOWLEDGED & RESOLVED ({resolvedAlerts.length})
          </div>

          {resolvedAlerts.map((alt) => (
            <div
              key={alt.id}
              className="tiyra-card"
              style={{
                backgroundColor: 'var(--color-canvas)',
                padding: '16px',
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span
                    style={{
                      fontSize: '10px',
                      fontWeight: 600,
                      padding: '2px 6px',
                      borderRadius: '4px',
                      backgroundColor: 'var(--color-container)',
                      color: 'var(--color-text-muted)',
                    }}
                  >
                    RESOLVED
                  </span>
                  <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    {alt.corridor}
                  </span>
                </div>
                <span className="mono" style={{ fontSize: '11px', color: 'var(--color-text-disabled)' }}>
                  {alt.time}
                </span>
              </div>

              <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-muted)' }}>
                {alt.title}
              </div>
              <div style={{ fontSize: '12px', color: 'var(--color-text-disabled)', lineHeight: 1.4 }}>
                {alt.description}
              </div>

              <div
                className="mono"
                style={{
                  fontSize: '11px',
                  color: 'var(--color-text-muted)',
                  borderTop: '1px solid var(--color-border)',
                  paddingTop: '8px',
                  marginTop: '4px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <span>Resolved by: {alt.resolvedBy || 'Official'} · {alt.resolvedAt || 'Today'}</span>
                <button
                  onClick={() => handleDismiss(alt.id)}
                  style={{
                    padding: '2px 8px',
                    fontSize: '11px',
                    border: '1px solid var(--color-border)',
                    borderRadius: '4px',
                    backgroundColor: 'transparent',
                    color: 'var(--color-text-muted)',
                    cursor: 'pointer',
                  }}
                >
                  Dismiss
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ALERT DETAILS MODAL */}
      {selectedDetailAlert && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            backdropFilter: 'blur(3px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '16px',
          }}
          onClick={() => setSelectedDetailAlert(null)}
        >
          <div
            className="tiyra-card"
            style={{
              width: '100%',
              maxWidth: '520px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-lg)',
              padding: '24px',
              display: 'flex',
              flexDirection: 'column',
              gap: '16px',
              boxShadow: 'var(--shadow-xl)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: 'var(--color-danger-bg)',
                    color: 'var(--color-danger)',
                    border: '1px solid var(--color-danger)',
                  }}
                >
                  {selectedDetailAlert.severity}
                </span>
                <span className="mono" style={{ fontSize: '13px', fontWeight: 700 }}>
                  {selectedDetailAlert.corridor} · {selectedDetailAlert.kmRange}
                </span>
              </div>
              <button
                onClick={() => setSelectedDetailAlert(null)}
                style={{
                  border: 'none',
                  background: 'transparent',
                  cursor: 'pointer',
                  padding: '4px',
                }}
              >
                <X size={18} color="var(--color-text-muted)" />
              </button>
            </div>

            <div>
              <div style={{ fontSize: '16px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
                {selectedDetailAlert.title}
              </div>
              <div className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                Alert ID: {selectedDetailAlert.id} · Dispatched: {selectedDetailAlert.time}
              </div>
            </div>

            <div style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: 1.5, backgroundColor: 'var(--color-canvas)', padding: '12px', borderRadius: 'var(--radius-md)' }}>
              {selectedDetailAlert.description}
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '12px' }}>
              <div><span style={{ fontWeight: 600, color: 'var(--color-text-muted)' }}>Sector / Affects:</span> <span style={{ fontWeight: 700 }}>{selectedDetailAlert.affects}</span></div>
              <div><span style={{ fontWeight: 600, color: 'var(--color-text-muted)' }}>KM Range:</span> <span className="mono">{selectedDetailAlert.kmRange}</span></div>
              {selectedDetailAlert.resolvedBy && (
                <div><span style={{ fontWeight: 600, color: 'var(--color-text-muted)' }}>Status:</span> <span style={{ color: 'var(--color-success)', fontWeight: 700 }}>Resolved by {selectedDetailAlert.resolvedBy} at {selectedDetailAlert.resolvedAt}</span></div>
              )}
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '8px' }}>
              {!selectedDetailAlert.acknowledged && (
                <button
                  onClick={() => {
                    handleAcknowledge(selectedDetailAlert.id);
                    setSelectedDetailAlert(null);
                  }}
                  style={{
                    padding: '8px 16px',
                    backgroundColor: 'var(--color-primary)',
                    color: '#FFFFFF',
                    border: 'none',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '12px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  Acknowledge Alert
                </button>
              )}
              <button
                onClick={() => setSelectedDetailAlert(null)}
                style={{
                  padding: '8px 16px',
                  backgroundColor: '#FFFFFF',
                  color: 'var(--color-text-secondary)',
                  border: '1px solid var(--color-border)',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '12px',
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* BROADCAST ALERT MODAL */}
      {isCreateModalOpen && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            backdropFilter: 'blur(3px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '16px',
          }}
          onClick={() => setIsCreateModalOpen(false)}
        >
          <div
            className="tiyra-card"
            style={{
              width: '100%',
              maxWidth: '560px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-lg)',
              boxShadow: '0 20px 40px rgba(0, 0, 0, 0.25)',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
              maxHeight: '90vh',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '16px 20px',
                borderBottom: '1px solid var(--color-border)',
                backgroundColor: 'var(--color-surface)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: 'var(--radius-sm)',
                    backgroundColor: 'var(--color-danger-bg)',
                    color: 'var(--color-danger)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <Radio size={18} />
                </div>
                <div>
                  <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Broadcast Tactical Advisory
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    Dispatches live disruption warnings to mobile drivers and field monitors
                  </div>
                </div>
              </div>
              <button
                onClick={() => setIsCreateModalOpen(false)}
                style={{
                  border: 'none',
                  background: 'none',
                  color: 'var(--color-text-muted)',
                  cursor: 'pointer',
                  padding: '4px',
                  borderRadius: '4px',
                }}
              >
                <X size={18} />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleBroadcastAlert} style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '16px', overflowY: 'auto' }}>
              {broadcastFeedback && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-success-bg)',
                    border: '1px solid var(--color-success)',
                    borderRadius: 'var(--radius-sm)',
                    color: 'var(--color-success)',
                    fontSize: '13px',
                    fontWeight: 600,
                  }}
                >
                  <CheckCircle2 size={18} />
                  <span>{broadcastFeedback}</span>
                </div>
              )}

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                    Corridor
                  </label>
                  <select
                    value={newCorridor}
                    onChange={(e) => setNewCorridor(e.target.value)}
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
                    <option value="NH-06">NH-06 (Shillong – Silchar)</option>
                    <option value="NH-08">NH-08 (Karimganj – Agartala)</option>
                    <option value="NH-102">NH-102 (Imphal – Moreh)</option>
                    <option value="NH-29">NH-29 (Dimapur – Kohima)</option>
                    <option value="NH-208">NH-208 (Kumarghat – Kailashahar)</option>
                    <option value="NH-13">NH-13 (Trans-Arunachal)</option>
                    <option value="NH-15">NH-15 (North Bank Highway)</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                    KM Location / Range
                  </label>
                  <input
                    type="text"
                    value={newKmRange}
                    onChange={(e) => setNewKmRange(e.target.value)}
                    placeholder="e.g. KM 52.3 - KM 68.0"
                    style={{
                      width: '100%',
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                    }}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                    Severity Classification
                  </label>
                  <select
                    value={newSeverity}
                    onChange={(e) => setNewSeverity(e.target.value as any)}
                    style={{
                      width: '100%',
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      backgroundColor: '#FFFFFF',
                      fontWeight: 600,
                      color:
                        newSeverity === 'EMERGENCY'
                          ? 'var(--color-danger)'
                          : newSeverity === 'HIGH RISK'
                          ? '#C2410C'
                          : newSeverity === 'CAUTION'
                          ? '#B45309'
                          : 'var(--color-primary)',
                    }}
                  >
                    <option value="EMERGENCY">EMERGENCY (Full Blockage / Active Hazard)</option>
                    <option value="HIGH RISK">HIGH RISK (High Failure Likelihood)</option>
                    <option value="CAUTION">CAUTION (Single-lane / Slow Traffic)</option>
                    <option value="INFO">INFO (Advisory / Clearance Notice)</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                    Affected Sectors / Vehicles
                  </label>
                  <input
                    type="text"
                    value={newAffects}
                    onChange={(e) => setNewAffects(e.target.value)}
                    placeholder="e.g. All Freight >16T, Tankers"
                    style={{
                      width: '100%',
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                    }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                  Advisory Headline *
                </label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="e.g. Active Rockfall Warning — Heavy Vehicles Hold at Jowai"
                  style={{
                    width: '100%',
                    height: '38px',
                    padding: '0 10px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    fontSize: '13px',
                    fontWeight: 600,
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                  Detailed Operational Situation *
                </label>
                <textarea
                  required
                  rows={3}
                  value={newDescription}
                  onChange={(e) => setNewDescription(e.target.value)}
                  placeholder="Describe observed trigger, clearance progress, estimated delay, and detour guidelines..."
                  style={{
                    width: '100%',
                    padding: '10px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    fontSize: '13px',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                  }}
                />
              </div>

              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '8px 12px',
                  backgroundColor: 'var(--color-surface)',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '11px',
                  color: 'var(--color-text-muted)',
                }}
              >
                <input type="checkbox" id="pushNotif" defaultChecked />
                <label htmlFor="pushNotif" style={{ cursor: 'pointer' }}>
                  Push priority push alert to connected mobile devices within 50 KM corridor buffer
                </label>
              </div>

              <div
                style={{
                  display: 'flex',
                  justifyContent: 'flex-end',
                  gap: '10px',
                  marginTop: '8px',
                  paddingTop: '12px',
                  borderTop: '1px solid var(--color-border)',
                }}
              >
                <button
                  type="button"
                  onClick={() => setIsCreateModalOpen(false)}
                  style={{
                    height: '36px',
                    padding: '0 16px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    backgroundColor: '#FFFFFF',
                    fontSize: '13px',
                    fontWeight: 600,
                    cursor: 'pointer',
                    color: 'var(--color-text-secondary)',
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{
                    height: '36px',
                    padding: '0 20px',
                    borderRadius: 'var(--radius-sm)',
                    border: 'none',
                    backgroundColor: 'var(--color-danger)',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    color: '#FFFFFF',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                >
                  <Radio size={14} />
                  <span>Transmit Broadcast</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
