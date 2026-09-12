import React, { useState, useEffect } from 'react';
import { useAuth } from '../state/AuthContext';
import {
  X,
  User as UserIcon,
  ShieldCheck,
  Bell,
  CheckCircle2,
  Key,
} from 'lucide-react';

interface AccountDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AccountDetailsModal: React.FC<AccountDetailsModalProps> = ({ isOpen, onClose }) => {
  const { user, updateUserProfile } = useAuth();

  const [activeTab, setActiveTab] = useState<'profile' | 'security' | 'alerts'>('profile');
  const [fullName, setFullName] = useState(user?.full_name || '');
  const [organization, setOrganization] = useState(user?.organization || 'Assam State Disaster Management Authority (ASDMA)');
  const [phone, setPhone] = useState(user?.phone_number || '+91 98640 54321');
  const [designation, setDesignation] = useState('Senior Operations Officer — Logistics Dispatch');
  
  // Security
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // Notification Preferences
  const [smsAlerts, setSmsAlerts] = useState(true);
  const [emailDigest, setEmailDigest] = useState(true);
  const [audioBeacon, setAudioBeacon] = useState(true);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    if (user) {
      if (user.full_name) setFullName(user.full_name);
      if (user.organization) setOrganization(user.organization);
      if (user.phone_number) setPhone(user.phone_number);
    }
  }, [user]);

  if (!isOpen || !user) return null;

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');

    if (activeTab === 'security') {
      if (newPassword) {
        if (!currentPassword) {
          setErrorMsg('Current password is required to change password.');
          return;
        }
        if (newPassword.length < 8) {
          setErrorMsg('New password must be at least 8 characters.');
          return;
        }
        if (newPassword !== confirmPassword) {
          setErrorMsg('New passwords do not match.');
          return;
        }
      }
    }

    setIsSubmitting(true);
    try {
      await updateUserProfile({
        full_name: fullName.trim(),
        organization: organization.trim(),
        phone_number: phone.trim(),
        ...(activeTab === 'security' && newPassword ? {
          current_password: currentPassword,
          new_password: newPassword,
        } : {}),
      });

      setSaveSuccess(true);
      if (activeTab === 'security') {
        setCurrentPassword('');
        setNewPassword('');
        setConfirmPassword('');
      }
      setTimeout(() => {
        setSaveSuccess(false);
        onClose();
      }, 1200);
    } catch (err: any) {
      setErrorMsg(err.message || 'Failed to save changes to database.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getInitials = (name?: string) => {
    if (!name) return 'TS';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
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
          maxWidth: '560px',
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
        {/* MODAL HEADER */}
        <div
          style={{
            padding: '20px 24px',
            borderBottom: '1px solid var(--color-border)',
            backgroundColor: 'var(--color-canvas)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
            <div
              style={{
                width: '46px',
                height: '46px',
                borderRadius: '50%',
                backgroundColor: 'var(--color-primary)',
                color: '#FFFFFF',
                fontSize: '16px',
                fontWeight: 800,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: 'var(--card-shadow)',
              }}
            >
              {getInitials(user.full_name)}
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <h2 style={{ fontSize: '17px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
                  {user.full_name}
                </h2>
                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 'var(--radius-pill)',
                    backgroundColor: user.role === 'ADMIN' ? 'var(--color-container)' : '#F5F3FF',
                    color: user.role === 'ADMIN' ? 'var(--color-text-primary)' : '#7C3AED',
                    border: '1px solid var(--color-border)',
                  }}
                >
                  {user.role}
                </span>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                {user.email}
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            aria-label="Close"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              backgroundColor: '#FFFFFF',
              border: '1px solid var(--color-border)',
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

        {/* TAB STRIP */}
        <div
          style={{
            display: 'flex',
            borderBottom: '1px solid var(--color-border)',
            padding: '0 24px',
            backgroundColor: '#FFFFFF',
            gap: '8px',
          }}
        >
          {[
            { id: 'profile', label: 'Profile Details', icon: <UserIcon size={14} /> },
            { id: 'security', label: 'Security & Auth', icon: <Key size={14} /> },
            { id: 'alerts', label: 'Disaster Alerts', icon: <Bell size={14} /> },
          ].map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => {
                  setActiveTab(tab.id as any);
                  setErrorMsg('');
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  height: '42px',
                  borderBottom: isActive ? '2px solid var(--color-primary)' : '2px solid transparent',
                  color: isActive ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                  fontWeight: isActive ? 700 : 500,
                  fontSize: '13px',
                  padding: '0 8px',
                  cursor: 'pointer',
                  transition: 'color var(--transition-fast)',
                }}
              >
                {tab.icon}
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* TAB BODY */}
        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', flex: 1, overflowY: 'auto' }}>
          <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {saveSuccess && (
              <div
                style={{
                  padding: '10px 14px',
                  backgroundColor: 'var(--color-success-bg)',
                  border: '1px solid var(--color-success)',
                  borderRadius: 'var(--radius-sm)',
                  color: 'var(--color-success)',
                  fontSize: '13px',
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                }}
              >
                <CheckCircle2 size={16} />
                <span>Account profile updated successfully.</span>
              </div>
            )}

            {errorMsg && (
              <div
                style={{
                  padding: '10px 14px',
                  backgroundColor: 'var(--color-danger-bg)',
                  border: '1px solid var(--color-danger)',
                  borderRadius: 'var(--radius-sm)',
                  color: 'var(--color-danger)',
                  fontSize: '13px',
                  fontWeight: 600,
                }}
              >
                {errorMsg}
              </div>
            )}

            {activeTab === 'profile' && (
              <>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                    Full Name
                  </label>
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    required
                    style={{
                      width: '100%',
                      height: '40px',
                      padding: '0 12px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      outline: 'none',
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                    Official Email (Government Authority Domain)
                  </label>
                  <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                    <input
                      type="email"
                      value={user.email}
                      disabled
                      style={{
                        width: '100%',
                        height: '40px',
                        padding: '0 12px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        backgroundColor: 'var(--color-canvas)',
                        color: 'var(--color-text-secondary)',
                        fontSize: '13px',
                        cursor: 'not-allowed',
                      }}
                    />
                    <span
                      style={{
                        position: 'absolute',
                        right: '12px',
                        fontSize: '11px',
                        color: 'var(--color-success)',
                        fontWeight: 600,
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px',
                      }}
                    >
                      <ShieldCheck size={14} /> Verified
                    </span>
                  </div>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                    Department / Authority Organization
                  </label>
                  <input
                    type="text"
                    value={organization}
                    onChange={(e) => setOrganization(e.target.value)}
                    style={{
                      width: '100%',
                      height: '40px',
                      padding: '0 12px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      outline: 'none',
                    }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                      Official Mobile / Dispatch Contact
                    </label>
                    <input
                      type="text"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      style={{
                        width: '100%',
                        height: '40px',
                        padding: '0 12px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '13px',
                        outline: 'none',
                      }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                      Operational Designation
                    </label>
                    <input
                      type="text"
                      value={designation}
                      onChange={(e) => setDesignation(e.target.value)}
                      style={{
                        width: '100%',
                        height: '40px',
                        padding: '0 12px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '13px',
                        outline: 'none',
                      }}
                    />
                  </div>
                </div>
              </>
            )}

            {activeTab === 'security' && (
              <>
                <div
                  style={{
                    padding: '12px 14px',
                    backgroundColor: 'var(--color-canvas)',
                    borderRadius: 'var(--radius-sm)',
                    border: '1px solid var(--color-border)',
                    fontSize: '12px',
                    color: 'var(--color-text-secondary)',
                  }}
                >
                  <div style={{ fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '2px' }}>
                    Role Clearance Level: {user.role === 'ADMIN' ? 'Tier 1 - Full Governance' : 'Tier 2 - Command & Dispatch'}
                  </div>
                  <div>Two-factor authentication enforced for all disaster management dispatchers.</div>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                    Current Password
                  </label>
                  <input
                    type="password"
                    placeholder="Enter current password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    style={{
                      width: '100%',
                      height: '40px',
                      padding: '0 12px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      outline: 'none',
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                    New Password
                  </label>
                  <input
                    type="password"
                    placeholder="At least 8 characters"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    style={{
                      width: '100%',
                      height: '40px',
                      padding: '0 12px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      outline: 'none',
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                    Confirm New Password
                  </label>
                  <input
                    type="password"
                    placeholder="Repeat new password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    style={{
                      width: '100%',
                      height: '40px',
                      padding: '0 12px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      outline: 'none',
                    }}
                  />
                </div>
              </>
            )}

            {activeTab === 'alerts' && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '12px 14px',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Critical Road Disruption SMS
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Immediate text alerts for landslide and bridge blockages
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={smsAlerts}
                    onChange={(e) => setSmsAlerts(e.target.checked)}
                    style={{ width: '18px', height: '18px', accentColor: 'var(--color-primary)' }}
                  />
                </div>

                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '12px 14px',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Daily 06:00 Regional Weather Digest
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Automated IMD monsoon rainfall forecast via email
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={emailDigest}
                    onChange={(e) => setEmailDigest(e.target.checked)}
                    style={{ width: '18px', height: '18px', accentColor: 'var(--color-primary)' }}
                  />
                </div>

                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '12px 14px',
                    border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                      Emergency Audio Beacon on New Incident
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                      Audible chime in web browser upon critical verified hazard
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={audioBeacon}
                    onChange={(e) => setAudioBeacon(e.target.checked)}
                    style={{ width: '18px', height: '18px', accentColor: 'var(--color-primary)' }}
                  />
                </div>
              </div>
            )}
          </div>

          {/* MODAL FOOTER */}
          <div
            style={{
              padding: '16px 24px',
              borderTop: '1px solid var(--color-border)',
              backgroundColor: 'var(--color-canvas)',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '10px',
            }}
          >
            <button
              type="button"
              onClick={onClose}
              style={{
                height: '38px',
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
              type="submit"
              disabled={isSubmitting}
              style={{
                height: '38px',
                padding: '0 20px',
                borderRadius: 'var(--radius-sm)',
                backgroundColor: isSubmitting ? 'var(--color-border)' : 'var(--color-primary)',
                color: '#FFFFFF',
                fontSize: '13px',
                fontWeight: 700,
                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                transition: 'background-color var(--transition-fast)',
              }}
              onMouseEnter={(e) => {
                if (!isSubmitting) e.currentTarget.style.backgroundColor = 'var(--color-primary-hover)';
              }}
              onMouseLeave={(e) => {
                if (!isSubmitting) e.currentTarget.style.backgroundColor = 'var(--color-primary)';
              }}
            >
              {isSubmitting ? 'Saving to Database...' : 'Save Profile Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
