import React from 'react';
import { X, Scale, FileText } from 'lucide-react';
import { DistanceBreakdown } from '../utils/distanceUtils';

export interface DistanceClausesModalProps {
  isOpen: boolean;
  onClose: () => void;
  breakdown: DistanceBreakdown | null;
  originName: string;
  destName: string;
  vehicleName: string;
  cargoName: string;
  routeName: string;
}

export const DistanceClausesModal: React.FC<DistanceClausesModalProps> = ({
  isOpen,
  onClose,
  breakdown,
  originName,
  destName,
  vehicleName,
  cargoName,
  routeName,
}) => {
  if (!isOpen || !breakdown) return null;

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.55)',
        backdropFilter: 'blur(6px)',
        WebkitBackdropFilter: 'blur(6px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 200,
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
        {/* Header */}
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
              <Scale size={20} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <h2 style={{ fontSize: '17px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
                  Distance Clauses & Regulatory Terrain Audit
                </h2>
                <span
                  style={{
                    fontSize: '10px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: 'var(--color-primary-bg)',
                    color: 'var(--color-primary)',
                  }}
                >
                  ENGINEERING AUDIT
                </span>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                {originName} ⇄ {destName} · {routeName}
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
              cursor: 'pointer',
              color: 'var(--color-text-secondary)',
            }}
          >
            <X size={16} />
          </button>
        </div>

        {/* Summary Stat Cards */}
        <div
          style={{
            padding: '16px 24px',
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: '12px',
            backgroundColor: '#F8FAFC',
            borderBottom: '1px solid var(--color-border)',
          }}
        >
          <div
            style={{
              padding: '12px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
              Total Road Distance
            </div>
            <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-primary)', marginTop: '4px' }}>
              {breakdown.totalRoadKm} km
            </div>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
              {breakdown.estimatedEtaText}
            </div>
          </div>

          <div
            style={{
              padding: '12px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
              Geodesic Aerial Base
            </div>
            <div style={{ fontSize: '22px', fontWeight: 800, color: '#0284C7', marginTop: '4px' }}>
              {breakdown.baseAerialKm} km
            </div>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
              WGS-84 Haversine
            </div>
          </div>

          <div
            style={{
              padding: '12px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)',
            }}
          >
            <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase' }}>
              Total Added Clauses
            </div>
            <div style={{ fontSize: '22px', fontWeight: 800, color: '#D97706', marginTop: '4px' }}>
              +{(breakdown.totalRoadKm - breakdown.baseAerialKm).toFixed(1)} km
            </div>
            <div style={{ fontSize: '11px', color: '#D97706', fontWeight: 600, marginTop: '2px' }}>
              +{Math.round(((breakdown.totalRoadKm - breakdown.baseAerialKm) / breakdown.baseAerialKm) * 100)}% Curvature & Clearance
            </div>
          </div>
        </div>

        {/* Profile Context Banner */}
        <div
          style={{
            padding: '10px 24px',
            backgroundColor: '#EFF6FF',
            borderBottom: '1px solid #BFDBFE',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            fontSize: '12px',
            color: '#1E40AF',
          }}
        >
          <div>
            <strong>Vehicle:</strong> {vehicleName}
          </div>
          <div>
            <strong>Cargo:</strong> {cargoName}
          </div>
          <div>
            <strong>Route Engine:</strong> TiyraSense Risk-First
          </div>
        </div>

        {/* Clauses List */}
        <div
          style={{
            padding: '18px 24px',
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
          }}
        >
          {breakdown.items.map((c) => (
            <div
              key={c.clauseCode}
              style={{
                padding: '14px 16px',
                borderRadius: 'var(--radius-md)',
                backgroundColor: '#FFFFFF',
                border: '1px solid var(--color-border)',
                display: 'flex',
                flexDirection: 'column',
                gap: '6px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                    {c.clauseName}
                  </div>
                  <div style={{ fontSize: '11px', fontWeight: 600, color: c.badgeColor, marginTop: '2px' }}>
                    {c.regulatoryRef}
                  </div>
                </div>

                <div
                  style={{
                    padding: '4px 10px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: `${c.badgeColor}15`,
                    color: c.badgeColor,
                    fontSize: '12px',
                    fontWeight: 800,
                  }}
                >
                  {c.clauseCode === 'BASE_AERIAL' ? `${c.deltaKm} km` : `+${c.deltaKm} km (${c.percentageText})`}
                </div>
              </div>

              <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', lineHeight: 1.4, margin: 0 }}>
                {c.explanation}
              </p>
            </div>
          ))}

          {/* Mathematical Formula Box */}
          <div
            style={{
              padding: '12px 16px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: '#F8FAFC',
              border: '1px dashed var(--color-border-strong)',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              fontSize: '11px',
              color: 'var(--color-text-muted)',
            }}
          >
            <FileText size={16} color="var(--color-primary)" />
            <div>
              <strong>Governing Formula:</strong> Total Road Distance = Base Aerial + Topographic Curvature (IRC:SP:48) + Vehicle Axle Clearance (MoRTH) + Safety Detour (D-006) + Cargo Buffer (CMVR 131)
            </div>
          </div>
        </div>

        {/* Footer */}
        <div
          style={{
            padding: '14px 24px',
            borderTop: '1px solid var(--color-border)',
            backgroundColor: 'var(--color-canvas)',
            display: 'flex',
            justifyContent: 'flex-end',
          }}
        >
          <button
            onClick={onClose}
            style={{
              height: '36px',
              padding: '0 20px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--color-primary)',
              color: '#FFFFFF',
              border: 'none',
              fontSize: '13px',
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            Close Audit View
          </button>
        </div>
      </div>
    </div>
  );
};
