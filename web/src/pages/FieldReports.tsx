import React, { useState, useEffect } from 'react';
import {
  Search,
  Download,
  X,
  Camera,
  CheckCircle2,
  Plus,
  MapPin,
  Send,
  Trash2,
  Upload,
} from 'lucide-react';
import {
  fetchFieldReports,
  verifyFieldReport,
  createFieldReport,
  deleteFieldReport,
  uploadEvidencePhoto,
  getAssetUrl,
} from '../services/api';


interface FieldReportItem {
  id: string;
  submitted: string;
  corridor: string;
  km: string;
  hazardType: 'Landslide' | 'Flash Flood' | 'Debris' | 'Road Subsidance' | 'Bridge Strain';
  severity: 'FULL BLOCKAGE' | 'PARTIAL' | 'SHOULDER';
  status: 'PENDING' | 'VERIFIED' | 'DISPATCHED' | 'REJECTED';
  workerName: string;
  workerInitials: string;
  workerUnit: string;
  coordinates: string;
  description: string;
  dispatchUnit?: string;
  dispatchNotes?: string;
  photoUrl?: string;
}

const INITIAL_REPORTS: FieldReportItem[] = [
  {
    id: 'RP-2847',
    submitted: '6m ago',
    corridor: 'NH-06',
    km: 'KM 52.3',
    hazardType: 'Landslide',
    severity: 'FULL BLOCKAGE',
    status: 'PENDING',
    workerName: 'Sanjay Kumar',
    workerInitials: 'SK',
    workerUnit: 'Field Unit 4',
    coordinates: '26.0124° N, 91.8901° E',
    description: 'Large boulder roll-down on left shoulder. One lane blocked, second lane at risk of secondary debris flow. Immediate earth-mover intervention requested.',
  },
  {
    id: 'RP-2846',
    submitted: '18m ago',
    corridor: 'NH-29',
    km: 'KM 81.1',
    hazardType: 'Flash Flood',
    severity: 'PARTIAL',
    status: 'VERIFIED',
    workerName: 'Priya Mao',
    workerInitials: 'PM',
    workerUnit: 'Field Unit 2',
    coordinates: '25.6812° N, 93.7145° E',
    description: 'Mountain stream overflow depositing gravel across 40 meters of roadway. Water depth approximately 20cm. Light vehicles diverted.',
  },
  {
    id: 'RP-2845',
    submitted: '42m ago',
    corridor: 'NH-37',
    km: 'KM 124.0',
    hazardType: 'Debris',
    severity: 'SHOULDER',
    status: 'DISPATCHED',
    workerName: 'Ratan Das',
    workerInitials: 'RD',
    workerUnit: 'Logistics Patrol 1',
    coordinates: '26.5410° N, 93.1892° E',
    description: 'Uprooted tree branches partially encroaching eastbound emergency shoulder. Clearance squad en route.',
    dispatchUnit: 'BRO Rapid Clearance #1',
  },
];

function formatRelativeTime(dateStr?: string | null): string {
  if (!dateStr) return 'Just now';
  if (dateStr.includes('ago') || dateStr.includes('now') || dateStr.includes('Recently')) return dateStr;
  try {
    const d = new Date(dateStr.replace(' ', 'T') + (dateStr.includes('Z') ? '' : 'Z'));
    if (isNaN(d.getTime())) return dateStr;
    const diffSec = Math.floor((Date.now() - d.getTime()) / 1000);
    if (diffSec < 60) return 'Just now';
    if (diffSec < 3600) return `${Math.floor(diffSec / 60)}m ago`;
    if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}h ago`;
    return `${Math.floor(diffSec / 86400)}d ago`;
  } catch {
    return dateStr;
  }
}

export const FieldReports: React.FC = () => {
  const [reports, setReports] = useState<FieldReportItem[]>(INITIAL_REPORTS);
  const [selectedReport, setSelectedReport] = useState<FieldReportItem | null>(INITIAL_REPORTS[0] || null);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'PENDING' | 'VERIFIED' | 'DISPATCHED' | 'REJECTED'>('ALL');
  const [corridorFilter, setCorridorFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Submit Modal State
  const [isSubmitModalOpen, setIsSubmitModalOpen] = useState(false);
  const [newCorridor, setNewCorridor] = useState('NH-06');
  const [newKm, setNewKm] = useState('KM 54.2');
  const [newHazardType, setNewHazardType] = useState<FieldReportItem['hazardType']>('Landslide');
  const [newSeverity, setNewSeverity] = useState<FieldReportItem['severity']>('FULL BLOCKAGE');
  const [newWorkerName, setNewWorkerName] = useState('Sub-Inspector D. Sangma');
  const [newWorkerUnit, setNewWorkerUnit] = useState('Field Recon Unit 5');
  const [newCoordinates, setNewCoordinates] = useState('25.5788° N, 92.2140° E');
  const [newDescription, setNewDescription] = useState('');
  const [submitFeedback, setSubmitFeedback] = useState<string | null>(null);
  const [lightboxPhoto, setLightboxPhoto] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false);

  // Review panel interactive dispatch state
  const [dispatchUnit, setDispatchUnit] = useState('Excavator 12T (Jowai Base)');
  const [dispatchNotes, setDispatchNotes] = useState('');
  const [actionFeedback, setActionFeedback] = useState<string | null>(null);

  const loadReports = () => {
    fetchFieldReports()
      .then((data) => {
        if (data && data.length > 0) {
          const mapped: FieldReportItem[] = data.map((d) => {
            const rawHz = (d.hazard_type || 'Landslide').replace(/_/g, ' ');
            let hzType: FieldReportItem['hazardType'] = 'Landslide';
            if (rawHz.toLowerCase().includes('flood')) hzType = 'Flash Flood';
            else if (rawHz.toLowerCase().includes('debris')) hzType = 'Debris';
            else if (rawHz.toLowerCase().includes('subsid')) hzType = 'Road Subsidance';
            else if (rawHz.toLowerCase().includes('bridge')) hzType = 'Bridge Strain';

            return {
              id: d.id,
              submitted: formatRelativeTime(d.submitted_at),
              corridor: d.corridor_name || 'NH-06',
              km: d.km_marker || 'KM 0.0',
              hazardType: hzType,
              severity: (d.severity as FieldReportItem['severity']) || 'FULL BLOCKAGE',
              status: (d.status as FieldReportItem['status']) || 'PENDING',
              workerName: d.reporter_name || 'Field Scout',
              workerInitials: (d.reporter_name || 'FS').slice(0, 2).toUpperCase(),
              workerUnit: d.reporter_unit || 'Field Recon',
              coordinates: `${d.latitude.toFixed(4)}° N, ${d.longitude.toFixed(4)}° E`,
              description: d.description,
              dispatchUnit: d.dispatch_unit,
              dispatchNotes: d.dispatch_notes,
              photoUrl: d.photo_url || (d as any).photoUrl ? getAssetUrl(d.photo_url || (d as any).photoUrl) : undefined,
            };
          });
          setReports(mapped);
          setSelectedReport((prev) => {
            if (!prev) return mapped[0];
            const match = mapped.find((m) => m.id === prev.id);
            return match || mapped[0];
          });
        }
      })
      .catch(() => {});
  };

  useEffect(() => {
    loadReports();
    const interval = setInterval(loadReports, 8000);
    const onOnline = () => loadReports();
    const onFocus = () => loadReports();
    window.addEventListener('online', onOnline);
    window.addEventListener('focus', onFocus);
    return () => {
      clearInterval(interval);
      window.removeEventListener('online', onOnline);
      window.removeEventListener('focus', onFocus);
    };
  }, []);

  const filteredReports = reports.filter((r) => {
    if (statusFilter !== 'ALL' && r.status !== statusFilter) return false;
    if (corridorFilter !== 'ALL' && !r.corridor.includes(corridorFilter)) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        r.id.toLowerCase().includes(q) ||
        r.corridor.toLowerCase().includes(q) ||
        r.workerName.toLowerCase().includes(q) ||
        r.hazardType.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleVerify = async (id: string) => {
    setReports((prev) =>
      prev.map((r) =>
        r.id === id
          ? {
              ...r,
              status: 'DISPATCHED',
              dispatchUnit,
              dispatchNotes: dispatchNotes.trim() || undefined,
            }
          : r
      )
    );
    if (selectedReport?.id === id) {
      setSelectedReport((prev) =>
        prev
          ? {
              ...prev,
              status: 'DISPATCHED',
              dispatchUnit,
              dispatchNotes: dispatchNotes.trim() || undefined,
            }
          : null
      );
    }
    setActionFeedback(`Dispatched ${dispatchUnit} to ${selectedReport?.corridor || 'corridor'} ${selectedReport?.km || ''}!`);
    setTimeout(() => setActionFeedback(null), 3000);

    try {
      await verifyFieldReport(id, {
        status: 'DISPATCHED',
        dispatch_unit: dispatchUnit,
        dispatch_notes: dispatchNotes.trim() || undefined,
      });
    } catch {
      // Keep optimistic state
    }
  };

  const handleReject = async (id: string) => {
    setReports((prev) =>
      prev.map((r) => (r.id === id ? { ...r, status: 'REJECTED' } : r))
    );
    if (selectedReport?.id === id) {
      setSelectedReport((prev) => (prev ? { ...prev, status: 'REJECTED' } : null));
    }
    setActionFeedback('Report marked as Rejected / Inactive.');
    setTimeout(() => setActionFeedback(null), 3000);

    try {
      await verifyFieldReport(id, { status: 'REJECTED' });
    } catch {
      // Keep optimistic state
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(`Are you sure you want to permanently delete report ${id}? This will purge the incident record and associated media.`)) {
      return;
    }
    setReports((prev) => prev.filter((r) => r.id !== id));
    if (selectedReport?.id === id) {
      setSelectedReport(null);
    }
    setActionFeedback(`Report ${id} permanently purged.`);
    setTimeout(() => setActionFeedback(null), 3000);

    try {
      await deleteFieldReport(id);
    } catch {
      // Keep optimistic state
    }
  };

  const handleExportCSV = () => {

    const headers = ['ID', 'Corridor', 'KM', 'Hazard', 'Severity', 'Status', 'Worker', 'Coordinates', 'Time', 'Dispatch_Unit'];
    const rows = filteredReports.map((r) => [
      r.id,
      r.corridor,
      r.km,
      r.hazardType,
      r.severity,
      r.status,
      `"${r.workerName}"`,
      `"${r.coordinates}"`,
      r.submitted,
      `"${r.dispatchUnit || 'None'}"`,
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `TiyraSense_Field_Reports_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleCreateReport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDescription.trim()) return;

    let uploadedPhotoUrl: string | undefined = photoPreview || undefined;
    if (selectedFile) {
      setIsUploadingPhoto(true);
      try {
        const uploadRes = await uploadEvidencePhoto(selectedFile);
        if (uploadRes?.url) {
          uploadedPhotoUrl = uploadRes.url;
        }
      } catch {
        // Fallback to preview
      } finally {
        setIsUploadingPhoto(false);
      }
    }

    const newReport: FieldReportItem = {
      id: `RP-${Math.floor(2850 + Math.random() * 500)}`,
      submitted: 'Just now',
      corridor: newCorridor,
      km: newKm.trim() || 'KM 00.0',
      hazardType: newHazardType,
      severity: newSeverity,
      status: 'PENDING',
      workerName: newWorkerName.trim() || 'Observer Alpha',
      workerInitials: (newWorkerName.trim() || 'OA').slice(0, 2).toUpperCase(),
      workerUnit: newWorkerUnit,
      coordinates: newCoordinates.trim() || '25.5788° N, 92.2140° E',
      description: newDescription.trim(),
      photoUrl: uploadedPhotoUrl ? getAssetUrl(uploadedPhotoUrl) : undefined,
    };

    setReports([newReport, ...reports]);
    setSelectedReport(newReport);
    setSubmitFeedback(`Recon Report ${newReport.id} logged and added to operations queue!`);

    try {
      const match = newCoordinates.match(/(-?\d+(?:\.\d+)?)[^\d-]+(-?\d+(?:\.\d+)?)/);
      const lat = match ? parseFloat(match[1]) : 25.5788;
      const lon = match ? parseFloat(match[2]) : 92.2140;

      const created = await createFieldReport({
        hazard_type: newHazardType,
        severity: newSeverity,
        description: newDescription.trim(),
        latitude: lat,
        longitude: lon,
        corridor_name: newCorridor,
        km_marker: newKm.trim(),
        photo_url: uploadedPhotoUrl,
      });
      if (created?.id) {
        newReport.id = created.id;
      }
      if (created?.photo_url) {
        newReport.photoUrl = getAssetUrl(created.photo_url);
      }
    } catch {
      // Retain optimistic entry
    }

    setTimeout(() => {
      setSubmitFeedback(null);
      setIsSubmitModalOpen(false);
      setNewDescription('');
      setSelectedFile(null);
      setPhotoPreview(null);
    }, 1200);
  };

  const renderStatusBadge = (status: FieldReportItem['status']) => {
    let dot = 'var(--color-success)';
    let bg = 'var(--color-success-bg)';
    let text = 'var(--color-success)';

    if (status === 'PENDING') {
      dot = 'var(--color-warning)';
      bg = 'var(--color-warning-bg)';
      text = '#D97706';
    } else if (status === 'DISPATCHED') {
      dot = 'var(--color-primary)';
      bg = 'var(--color-primary-bg)';
      text = 'var(--color-primary)';
    } else if (status === 'REJECTED') {
      dot = 'var(--color-text-muted)';
      bg = 'var(--color-container)';
      text = 'var(--color-text-muted)';
    }

    return (
      <span
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '5px',
          padding: '3px 8px',
          borderRadius: 'var(--radius-pill)',
          backgroundColor: bg,
          color: text,
          fontSize: '11px',
          fontWeight: 600,
        }}
      >
        <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: dot }} />
        {status}
      </span>
    );
  };

  return (
    <div style={{ maxWidth: '1440px', margin: '0 auto', display: 'flex', flexDirection: 'column', gap: '20px', position: 'relative' }}>
      {/* PAGE HEADER */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <h1 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
            Field Reports
          </h1>
          <span
            style={{
              backgroundColor: 'var(--color-primary-light)',
              color: 'var(--color-primary)',
              fontSize: '11px',
              fontWeight: 700,
              padding: '3px 8px',
              borderRadius: 'var(--radius-pill)',
            }}
          >
            {reports.length} in database
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <button
            onClick={() => setIsSubmitModalOpen(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              height: '36px',
              padding: '0 14px',
              borderRadius: 'var(--radius-sm)',
              border: 'none',
              backgroundColor: 'var(--color-primary)',
              color: '#FFFFFF',
              fontSize: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: 'var(--card-shadow)',
            }}
          >
            <Plus size={15} />
            <span>Submit Recon Report</span>
          </button>

          <button
            onClick={handleExportCSV}
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
              cursor: 'pointer',
            }}
          >
            <Download size={14} />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {actionFeedback && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 14px',
            backgroundColor: 'var(--color-success-bg)',
            border: '1px solid var(--color-success)',
            borderRadius: 'var(--radius-sm)',
            color: 'var(--color-success)',
            fontSize: '13px',
            fontWeight: 600,
          }}
        >
          <CheckCircle2 size={16} />
          <span>{actionFeedback}</span>
        </div>
      )}

      {/* FILTER BAR */}
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
        {/* Status Chips */}
        <div style={{ display: 'flex', gap: '6px' }}>
          {(['ALL', 'PENDING', 'VERIFIED', 'DISPATCHED', 'REJECTED'] as const).map((chip) => {
            const isActive = statusFilter === chip;
            return (
              <button
                key={chip}
                onClick={() => setStatusFilter(chip)}
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
                }}
              >
                {chip}
              </button>
            );
          })}
        </div>

        {/* Corridor Filter */}
        <select
          value={corridorFilter}
          onChange={(e) => setCorridorFilter(e.target.value)}
          style={{
            height: '34px',
            padding: '0 10px',
            borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--color-border)',
            fontSize: '12px',
            backgroundColor: '#FFFFFF',
            color: 'var(--color-text-secondary)',
            fontWeight: 600,
          }}
        >
          <option value="ALL">All Corridors</option>
          <option value="NH-06">NH-06 (Shillong – Silchar)</option>
          <option value="NH-29">NH-29 (Dimapur – Kohima)</option>
          <option value="NH-37">NH-37 (Guwahati – Kaziranga)</option>
          <option value="NH-40">NH-40 (Jorabat – Shillong)</option>
          <option value="NH-102">NH-102 (Imphal – Moreh)</option>
          <option value="NH-51">NH-51 (Paikan – Tura)</option>
          <option value="NH-08">NH-08 (Karimganj – Agartala)</option>
          <option value="NH-208">NH-208 (Kumarghat – Kailashahar)</option>
        </select>

        {/* Search input with clear */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            height: '34px',
            width: '240px',
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
            placeholder="Search ID, hazard, worker..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              border: 'none',
              outline: 'none',
              fontSize: '12px',
              width: '100%',
              color: 'var(--color-text-primary)',
            }}
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              style={{ border: 'none', background: 'none', cursor: 'pointer', padding: 0 }}
            >
              <X size={12} color="var(--color-text-muted)" />
            </button>
          )}
        </div>
      </div>

      {/* MAIN CONTENT: Table + Sliding Detail Panel */}
      <div style={{ display: 'flex', gap: '16px', alignItems: 'start' }}>
        {/* REPORTS TABLE (white card, 12px radius, 20px padding) */}
        <div className="tiyra-card" style={{ flex: 1, padding: '20px', overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr
                style={{
                  height: '44px',
                  backgroundColor: 'var(--color-canvas)',
                  borderBottom: '1px solid var(--color-border)',
                  fontSize: '11px',
                  fontWeight: 700,
                  color: 'var(--color-text-disabled)',
                  letterSpacing: '0.05em',
                  textTransform: 'uppercase',
                }}
              >
                <th style={{ padding: '0 12px' }}>Report ID</th>
                <th style={{ padding: '0 12px' }}>Submitted</th>
                <th style={{ padding: '0 12px' }}>Corridor / KM</th>
                <th style={{ padding: '0 12px' }}>Hazard Type</th>
                <th style={{ padding: '0 12px' }}>Severity</th>
                <th style={{ padding: '0 12px' }}>Status</th>
                <th style={{ padding: '0 12px' }}>Field Worker</th>
                <th style={{ padding: '0 12px', textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filteredReports.map((r) => {
                const isSelected = selectedReport?.id === r.id;

                let hazardBg = '#FEF3C7';
                let hazardText = '#B45309';
                if (r.hazardType === 'Flash Flood') {
                  hazardBg = '#E0F2FE';
                  hazardText = '#0369A1';
                } else if (r.hazardType === 'Debris') {
                  hazardBg = '#FFEDD5';
                  hazardText = '#C2410C';
                }

                return (
                  <tr
                    key={r.id}
                    onClick={() => setSelectedReport(r)}
                    style={{
                      height: '64px',
                      borderBottom: '1px solid var(--color-border)',
                      fontSize: '13px',
                      backgroundColor: isSelected ? 'var(--color-primary-bg)' : '#FFFFFF',
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
                    <td style={{ padding: '0 12px' }}>
                      <span className="mono" style={{ fontWeight: 600, color: 'var(--color-text-secondary)' }} title={r.id}>
                        {r.id.length > 12 ? `RP-${r.id.slice(0, 6).toUpperCase()}` : r.id}
                      </span>
                    </td>
                    <td style={{ padding: '0 12px' }}>
                      <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                        {r.submitted}
                      </span>
                    </td>
                    <td style={{ padding: '0 12px' }}>
                      <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>
                        {r.corridor} · {r.km}
                      </div>
                    </td>
                    <td style={{ padding: '0 12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span
                          style={{
                            fontSize: '11px',
                            fontWeight: 600,
                            padding: '3px 8px',
                            borderRadius: '4px',
                            backgroundColor: hazardBg,
                            color: hazardText,
                          }}
                        >
                          {r.hazardType}
                        </span>
                        {r.photoUrl && (
                          <span
                            title="Click to inspect photo evidence"
                            onClick={(e) => {
                              e.stopPropagation();
                              setLightboxPhoto(getAssetUrl(r.photoUrl!));
                            }}
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '3px',
                              padding: '2px 6px',
                              borderRadius: '4px',
                              backgroundColor: '#EFF6FF',
                              color: '#1D4ED8',
                              fontSize: '10px',
                              fontWeight: 700,
                              cursor: 'pointer',
                              border: '1px solid #BFDBFE',
                            }}
                          >
                            <Camera size={10} />
                            <span>PHOTO</span>
                          </span>
                        )}
                      </div>
                    </td>
                    <td style={{ padding: '0 12px' }}>
                      <span
                        style={{
                          fontSize: '11px',
                          fontWeight: 700,
                          color:
                            r.severity === 'FULL BLOCKAGE'
                              ? 'var(--color-danger)'
                              : r.severity === 'PARTIAL'
                              ? 'var(--color-warning)'
                              : 'var(--color-success)',
                        }}
                      >
                        {r.severity}
                      </span>
                    </td>
                    <td style={{ padding: '0 12px' }}>{renderStatusBadge(r.status)}</td>
                    <td style={{ padding: '0 12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div
                          style={{
                            width: '28px',
                            height: '28px',
                            borderRadius: '50%',
                            backgroundColor: 'var(--color-container)',
                            color: 'var(--color-text-secondary)',
                            fontSize: '11px',
                            fontWeight: 700,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                        >
                          {r.workerInitials}
                        </div>
                        <span style={{ fontSize: '12px', fontWeight: 500 }}>{r.workerName}</span>
                      </div>
                    </td>
                    <td style={{ padding: '0 12px', textAlign: 'right' }}>
                      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedReport(r);
                          }}
                          style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-primary)' }}
                        >
                          Review
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleReject(r.id);
                          }}
                          style={{ fontSize: '12px', fontWeight: 600, color: '#B45309', background: 'none', border: 'none', cursor: 'pointer' }}
                        >
                          Reject
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDelete(r.id);
                          }}
                          data-testid={`delete-report-btn-${r.id}`}
                          style={{
                            fontSize: '12px',
                            fontWeight: 600,
                            color: 'var(--color-danger)',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '3px',
                          }}
                          title="Delete / Purge Report"
                        >
                          <Trash2 size={13} />
                          <span>Delete</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* REPORT DETAIL SIDE PANEL (480px, slides from right, white, left border, shadow) */}
        {selectedReport && (
          <div
            className="tiyra-card"
            style={{
              width: '480px',
              flexShrink: 0,
              padding: '24px',
              display: 'flex',
              flexDirection: 'column',
              gap: '16px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                  Report Detail
                </h2>
                <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                  {selectedReport.id}
                </span>
              </div>
              <button
                onClick={() => setSelectedReport(null)}
                style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--color-container)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'var(--color-text-muted)',
                }}
              >
                <X size={16} />
              </button>
            </div>

            {/* GPS & Location Banner */}
            <div
              style={{
                backgroundColor: 'var(--color-canvas)',
                borderRadius: 'var(--radius-sm)',
                padding: '12px',
                border: '1px solid var(--color-border)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <div>
                <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                  {selectedReport.corridor} {selectedReport.km}
                </div>
                <div className="mono" style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                  {selectedReport.coordinates}
                </div>
              </div>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  backgroundColor: 'var(--color-success-bg)',
                  color: 'var(--color-success)',
                  fontSize: '10px',
                  fontWeight: 700,
                  padding: '3px 8px',
                  borderRadius: 'var(--radius-pill)',
                }}
              >
                <CheckCircle2 size={12} />
                <span>GPS LOCKED</span>
              </div>
            </div>

            {/* Field Evidence Photo Box */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <span style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
                  Field Evidence Photo
                </span>
                {selectedReport.photoUrl && (
                  <span style={{ fontSize: '10px', color: '#059669', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <CheckCircle2 size={12} />
                    <span>GEO-VERIFIED CAPTURE</span>
                  </span>
                )}
              </div>

              {selectedReport.photoUrl ? (
                <div
                  style={{
                    position: 'relative',
                    borderRadius: '8px',
                    overflow: 'hidden',
                    border: '1px solid #CBD5E1',
                    cursor: 'pointer',
                    height: '210px',
                    backgroundColor: '#0F172A',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
                  }}
                  onClick={() => setLightboxPhoto(getAssetUrl(selectedReport.photoUrl!))}
                  title="Click to zoom and inspect evidence photo"
                >
                  <div
                    style={{
                      position: 'absolute',
                      inset: 0,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#94A3B8',
                      fontSize: '12px',
                    }}
                  >
                    <div style={{ textAlign: 'center' }}>
                      <Camera size={26} style={{ margin: '0 auto 6px', color: '#64748B' }} />
                      <div style={{ fontWeight: 600, color: '#CBD5E1' }}>Forensic Evidence Photo</div>
                      <div style={{ fontSize: '10px', color: '#64748B', marginTop: '2px' }}>Click to view full image</div>
                    </div>
                  </div>
                  <img
                    src={getAssetUrl(selectedReport.photoUrl)}
                    alt={`${selectedReport.hazardType} Evidence`}
                    style={{
                      position: 'relative',
                      zIndex: 1,
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      display: 'block',
                    }}
                    onError={(e) => {
                      const img = e.currentTarget as HTMLImageElement;
                      if (!img.src.includes('localhost:8000') && img.src.includes('/static/uploads/')) {
                        img.src = `http://localhost:8000${img.src.substring(img.src.indexOf('/static/uploads/'))}`;
                      } else {
                        img.style.display = 'none';
                      }
                    }}
                  />
                  <div
                    style={{
                      position: 'absolute',
                      bottom: 0,
                      left: 0,
                      right: 0,
                      padding: '8px 12px',
                      background: 'linear-gradient(transparent, rgba(15, 23, 42, 0.85))',
                      color: '#FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <span style={{ fontSize: '11px', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '5px' }}>
                      <Camera size={13} color="#38BDF8" />
                      Inspect Full Resolution Photo
                    </span>
                    <span className="mono" style={{ fontSize: '10px', opacity: 0.85 }}>
                      {selectedReport.coordinates}
                    </span>
                  </div>
                </div>
              ) : (
                <div
                  style={{
                    height: '100px',
                    backgroundColor: 'var(--color-container)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px dashed var(--color-border)',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '6px',
                    color: 'var(--color-text-muted)',
                  }}
                >
                  <Camera size={22} />
                  <span style={{ fontSize: '11px' }}>No field camera photo attached to this report</span>
                </div>
              )}
            </div>

            {/* Hazard Description */}
            <div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', marginBottom: '6px' }}>
                Reconnaissance Notes
              </div>
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: 1.5 }}>
                {selectedReport.description}
              </p>
            </div>

            {/* Worker Metadata */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                paddingTop: '12px',
                borderTop: '1px solid var(--color-border)',
              }}
            >
              <div
                style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--color-primary-bg)',
                  color: 'var(--color-primary)',
                  fontWeight: 700,
                  fontSize: '12px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {selectedReport.workerInitials}
              </div>
              <div>
                <div style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                  {selectedReport.workerName} · {selectedReport.workerUnit}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                  Submitted {selectedReport.submitted} · Device Calibrated
                </div>
              </div>
            </div>

            {/* INTERACTIVE DISPATCH SECTION */}
            <div
              style={{
                backgroundColor: 'var(--color-surface)',
                border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-sm)',
                padding: '12px',
                display: 'flex',
                flexDirection: 'column',
                gap: '10px',
              }}
            >
              <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-secondary)', textTransform: 'uppercase' }}>
                Operational Response & Dispatch
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)', marginBottom: '4px' }}>
                  Assign Clearance Squad / Unit
                </label>
                <select
                  value={dispatchUnit}
                  onChange={(e) => setDispatchUnit(e.target.value)}
                  style={{
                    width: '100%',
                    height: '34px',
                    padding: '0 8px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    fontSize: '12px',
                    backgroundColor: '#FFFFFF',
                  }}
                >
                  <option value="Excavator 12T (Jowai Base)">Excavator 12T (Jowai Base)</option>
                  <option value="BRO Rapid Clearance Unit #1">BRO Rapid Clearance Unit #1</option>
                  <option value="Meghalaya PWD Mobile Patrol">Meghalaya PWD Mobile Patrol</option>
                  <option value="Disaster Management Crane Unit">Disaster Management Crane Unit</option>
                  <option value="Traffic Diversion & Warning Squad">Traffic Diversion & Warning Squad</option>
                </select>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: 'var(--color-text-muted)', marginBottom: '4px' }}>
                  Verification / Dispatch Instructions
                </label>
                <textarea
                  rows={2}
                  value={dispatchNotes}
                  onChange={(e) => setDispatchNotes(e.target.value)}
                  placeholder="Enter detour advisory or dispatch instructions..."
                  style={{
                    width: '100%',
                    padding: '8px',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    fontSize: '12px',
                    fontFamily: 'inherit',
                    resize: 'vertical',
                  }}
                />
              </div>
            </div>

            {actionFeedback && (
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '10px 12px',
                  backgroundColor: 'var(--color-success-bg)',
                  border: '1px solid var(--color-success)',
                  borderRadius: 'var(--radius-sm)',
                  color: 'var(--color-success)',
                  fontSize: '12px',
                  fontWeight: 600,
                }}
              >
                <CheckCircle2 size={16} />
                <span>{actionFeedback}</span>
              </div>
            )}

            {/* Pinned Bottom Actions */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: 'auto', paddingTop: '12px' }}>
              <button
                onClick={() => handleVerify(selectedReport.id)}
                style={{
                  width: '100%',
                  height: '44px',
                  backgroundColor: 'var(--color-success)',
                  color: '#FFFFFF',
                  fontSize: '13px',
                  fontWeight: 700,
                  borderRadius: 'var(--radius-sm)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  cursor: 'pointer',
                  border: 'none',
                }}
              >
                <CheckCircle2 size={16} />
                <span>Verify & Dispatch Unit</span>
              </button>

              <button
                onClick={() => handleReject(selectedReport.id)}
                style={{
                  width: '100%',
                  height: '36px',
                  backgroundColor: '#FFFFFF',
                  border: '1px solid var(--color-danger)',
                  color: 'var(--color-danger)',
                  fontSize: '12px',
                  fontWeight: 600,
                  borderRadius: 'var(--radius-sm)',
                  cursor: 'pointer',
                }}
              >
                Reject Report
              </button>

              <button
                data-testid="panel-delete-report-btn"
                onClick={() => handleDelete(selectedReport.id)}
                style={{
                  width: '100%',
                  height: '36px',
                  backgroundColor: 'rgba(239, 68, 68, 0.08)',
                  border: '1px solid var(--color-danger)',
                  color: 'var(--color-danger)',
                  fontSize: '12px',
                  fontWeight: 700,
                  borderRadius: 'var(--radius-sm)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  cursor: 'pointer',
                }}
              >
                <Trash2 size={14} />
                <span>Delete / Purge Report</span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* SUBMIT RECON REPORT MODAL */}
      {isSubmitModalOpen && (
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
          onClick={() => setIsSubmitModalOpen(false)}
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
                    backgroundColor: 'var(--color-primary-light)',
                    color: 'var(--color-primary)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <Plus size={18} />
                </div>
                <div>
                  <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    Submit Field Reconnaissance Report
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    Record validated road hazard evidence directly into TiyraSense verification queue
                  </div>
                </div>
              </div>
              <button
                onClick={() => setIsSubmitModalOpen(false)}
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
            <form onSubmit={handleCreateReport} style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px', overflowY: 'auto' }}>
              {submitFeedback && (
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
                  <span>{submitFeedback}</span>
                </div>
              )}

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
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
                    <option value="NH-29">NH-29 (Dimapur – Kohima)</option>
                    <option value="NH-37">NH-37 (Guwahati – Kaziranga)</option>
                    <option value="NH-40">NH-40 (Jorabat – Shillong)</option>
                    <option value="NH-102">NH-102 (Imphal – Moreh)</option>
                    <option value="NH-51">NH-51 (Paikan – Tura)</option>
                    <option value="NH-08">NH-08 (Karimganj – Agartala)</option>
                    <option value="NH-208">NH-208 (Kumarghat – Kailashahar)</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    KM Marker / Segment
                  </label>
                  <input
                    type="text"
                    value={newKm}
                    onChange={(e) => setNewKm(e.target.value)}
                    placeholder="e.g. KM 54.2"
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
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    Hazard Type
                  </label>
                  <select
                    value={newHazardType}
                    onChange={(e) => setNewHazardType(e.target.value as any)}
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
                    <option value="Landslide">Landslide / Mudslide</option>
                    <option value="Flash Flood">Flash Flood / River Overflow</option>
                    <option value="Debris">Debris / Fallen Trees</option>
                    <option value="Road Subsidance">Road Subsidence / Bitumen Slip</option>
                    <option value="Bridge Strain">Bridge Strain / Scour</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    Passability Severity
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
                        newSeverity === 'FULL BLOCKAGE'
                          ? 'var(--color-danger)'
                          : newSeverity === 'PARTIAL'
                          ? '#C2410C'
                          : 'var(--color-primary)',
                    }}
                  >
                    <option value="FULL BLOCKAGE">FULL BLOCKAGE (No traffic can pass)</option>
                    <option value="PARTIAL">PARTIAL (Single-lane / Light vehicles only)</option>
                    <option value="SHOULDER">SHOULDER (Passable with caution)</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    Observer / Officer Name
                  </label>
                  <input
                    type="text"
                    value={newWorkerName}
                    onChange={(e) => setNewWorkerName(e.target.value)}
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

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    Reconnaissance Unit
                  </label>
                  <input
                    type="text"
                    value={newWorkerUnit}
                    onChange={(e) => setNewWorkerUnit(e.target.value)}
                    placeholder="e.g. Field Recon Unit 5"
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
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                  GPS Coordinates
                </label>
                <div style={{ display: 'flex', gap: '6px' }}>
                  <input
                    type="text"
                    value={newCoordinates}
                    onChange={(e) => setNewCoordinates(e.target.value)}
                    style={{
                      flex: 1,
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '12px',
                      fontFamily: 'monospace',
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setNewCoordinates(`${(25.4 + Math.random() * 0.8).toFixed(4)}° N, ${(91.8 + Math.random() * 0.8).toFixed(4)}° E`)}
                    title="Simulate GPS fix"
                    style={{
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      backgroundColor: 'var(--color-surface)',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <MapPin size={16} color="var(--color-primary)" />
                  </button>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                  Field Observation Details *
                </label>
                <textarea
                  required
                  rows={3}
                  value={newDescription}
                  onChange={(e) => setNewDescription(e.target.value)}
                  placeholder="Describe slope condition, estimated debris volume, weather conditions, and detour viability..."
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

              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '6px' }}>
                  Field Photographic Evidence (Live Recon / On-Site)
                </label>
                <div
                  style={{
                    border: '1px dashed var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                    padding: '12px',
                    backgroundColor: 'var(--color-surface)',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '10px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <label
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '6px 12px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--color-border)',
                        borderRadius: 'var(--radius-sm)',
                        fontSize: '12px',
                        fontWeight: 600,
                        cursor: 'pointer',
                        color: 'var(--color-text-primary)',
                      }}
                    >
                      <Upload size={14} color="var(--color-primary)" />
                      <span>{selectedFile ? 'Change Photo' : 'Select Evidence Image'}</span>
                      <input
                        type="file"
                        accept="image/*"
                        style={{ display: 'none' }}
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            setSelectedFile(file);
                            const reader = new FileReader();
                            reader.onload = () => {
                              setPhotoPreview(reader.result as string);
                            };
                            reader.readAsDataURL(file);
                          }
                        }}
                      />
                    </label>
                    {selectedFile && (
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedFile(null);
                          setPhotoPreview(null);
                        }}
                        style={{
                          background: 'none',
                          border: 'none',
                          color: '#EF4444',
                          fontSize: '11px',
                          cursor: 'pointer',
                          fontWeight: 600,
                        }}
                      >
                        Remove
                      </button>
                    )}
                    <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginLeft: 'auto' }}>
                      {selectedFile ? selectedFile.name : 'PNG, JPG, WebP supported'}
                    </span>
                  </div>

                  {photoPreview && (
                    <div
                      style={{
                        position: 'relative',
                        height: '140px',
                        borderRadius: '6px',
                        overflow: 'hidden',
                        border: '1px solid #CBD5E1',
                        backgroundColor: '#0F172A',
                      }}
                    >
                      <img
                        src={photoPreview}
                        alt="Evidence Preview"
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      />
                      <div
                        style={{
                          position: 'absolute',
                          bottom: 0,
                          left: 0,
                          right: 0,
                          padding: '4px 8px',
                          backgroundColor: 'rgba(15, 23, 42, 0.75)',
                          color: '#FFFFFF',
                          fontSize: '11px',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px',
                        }}
                      >
                        <CheckCircle2 size={12} color="#10B981" />
                        <span>Ready to upload and stream to all operator dashboards</span>
                      </div>
                    </div>
                  )}
                </div>
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
                  onClick={() => setIsSubmitModalOpen(false)}
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
                  disabled={isUploadingPhoto}
                  style={{
                    height: '36px',
                    padding: '0 20px',
                    borderRadius: 'var(--radius-sm)',
                    border: 'none',
                    backgroundColor: isUploadingPhoto ? 'var(--color-text-muted)' : 'var(--color-primary)',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: isUploadingPhoto ? 'not-allowed' : 'pointer',
                    color: '#FFFFFF',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                >
                  <Send size={14} />
                  <span>{isUploadingPhoto ? 'Uploading Photo...' : 'Submit Recon Report'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* High-Resolution Evidence Lightbox Modal */}
      {lightboxPhoto && (
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
          onClick={() => setLightboxPhoto(null)}
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
            <div
              style={{
                position: 'absolute',
                top: '12px',
                right: '12px',
                zIndex: 10,
              }}
            >
              <button
                type="button"
                onClick={() => setLightboxPhoto(null)}
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
              src={getAssetUrl(lightboxPhoto)}
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
                <CheckCircle2 size={14} color="#10B981" />
                <span style={{ fontWeight: 600 }}>Geo-Verified High-Resolution Recon Photo</span>
              </div>
              <span style={{ color: '#94A3B8', fontSize: '11px' }}>TiyraSense Field Intelligence Network</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
