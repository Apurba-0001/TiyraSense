import React, { useState } from 'react';
import {
  UserPlus,
  Search,
  X,
} from 'lucide-react';

interface ManagedUser {
  id: string;
  name: string;
  email: string;
  initials: string;
  role: 'DRIVER' | 'FIELD_WORKER' | 'OFFICIAL' | 'ADMIN';
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED';
  lastActive: string;
  registered: string;
}



export const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<ManagedUser[]>([]);
  const [roleFilter, setRoleFilter] = useState<'ALL' | 'DRIVER' | 'FIELD_WORKER' | 'OFFICIAL' | 'ADMIN'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Invite Form State
  const [inviteName, setInviteName] = useState('');
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState<'DRIVER' | 'FIELD_WORKER' | 'OFFICIAL' | 'ADMIN'>('OFFICIAL');
  const [inviteOrg, setInviteOrg] = useState('');

  // Edit User State
  const [editingUser, setEditingUser] = useState<ManagedUser | null>(null);
  const [editName, setEditName] = useState('');
  const [editEmail, setEditEmail] = useState('');
  const [editRole, setEditRole] = useState<ManagedUser['role']>('OFFICIAL');
  const [editStatus, setEditStatus] = useState<ManagedUser['status']>('ACTIVE');

  const startEdit = (u: ManagedUser) => {
    setEditingUser(u);
    setEditName(u.name);
    setEditEmail(u.email);
    setEditRole(u.role);
    setEditStatus(u.status);
  };

  const handleSaveEdit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser || !editName.trim() || !editEmail.trim()) return;

    const parts = editName.trim().split(' ');
    const initials = parts.length > 1 ? (parts[0][0] + parts[1][0]).toUpperCase() : editName.slice(0, 2).toUpperCase();

    setUsers((prev) =>
      prev.map((u) =>
        u.id === editingUser.id
          ? {
              ...u,
              name: editName.trim(),
              email: editEmail.trim(),
              role: editRole,
              status: editStatus,
              initials,
            }
          : u
      )
    );
    setEditingUser(null);
  };

  const filteredUsers = users.filter((u) => {
    if (roleFilter !== 'ALL' && u.role !== roleFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q);
    }
    return true;
  });

  const handleSendInvite = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inviteName || !inviteEmail) return;

    const parts = inviteName.trim().split(' ');
    const initials = parts.length > 1 ? parts[0][0] + parts[1][0] : inviteName.slice(0, 2).toUpperCase();

    const newUser: ManagedUser = {
      id: String(Date.now()),
      name: inviteName,
      email: inviteEmail,
      initials,
      role: inviteRole,
      status: 'PENDING',
      lastActive: 'Invited',
      registered: 'Today',
    };

    setUsers([newUser, ...users]);
    setIsModalOpen(false);
    setInviteName('');
    setInviteEmail('');
    setInviteOrg('');
  };

  const handleToggleSuspend = (id: string) => {
    setUsers((prev) =>
      prev.map((u) => {
        if (u.id === id) {
          const newStatus = u.status === 'SUSPENDED' ? 'ACTIVE' : 'SUSPENDED';
          return { ...u, status: newStatus };
        }
        return u;
      })
    );
  };

  const renderRoleChip = (role: ManagedUser['role']) => {
    let bg = 'var(--color-container)';
    let color = 'var(--color-text-secondary)';
    let label = String(role);

    if (role === 'DRIVER') {
      bg = '#F0F9FF';
      color = '#0284C7';
      label = 'Driver';
    } else if (role === 'FIELD_WORKER') {
      bg = '#FFFBEB';
      color = '#D97706';
      label = 'Field Worker';
    } else if (role === 'OFFICIAL') {
      bg = '#F5F3FF';
      color = '#7C3AED';
      label = 'Official';
    } else if (role === 'ADMIN') {
      bg = '#F1F5F9';
      color = '#475569';
      label = 'Admin';
    }

    return (
      <span
        style={{
          fontSize: '11px',
          fontWeight: 600,
          padding: '3px 8px',
          borderRadius: 'var(--radius-pill)',
          backgroundColor: bg,
          color: color,
        }}
      >
        {label}
      </span>
    );
  };

  const renderStatusBadge = (status: ManagedUser['status']) => {
    let dot = 'var(--color-success)';
    let bg = 'var(--color-success-bg)';
    let color = 'var(--color-success)';

    if (status === 'PENDING') {
      dot = 'var(--color-warning)';
      bg = 'var(--color-warning-bg)';
      color = '#D97706';
    } else if (status === 'SUSPENDED') {
      dot = 'var(--color-danger)';
      bg = 'var(--color-danger-bg)';
      color = 'var(--color-danger)';
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
          color: color,
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
    <div className="responsive-container" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* PAGE HEADER */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
        <h1 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)' }}>
          User Management
        </h1>

        <button
          onClick={() => setIsModalOpen(true)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            height: '44px',
            padding: '0 18px',
            borderRadius: 'var(--radius-sm)',
            backgroundColor: 'var(--color-primary)',
            color: '#FFFFFF',
            fontSize: '13px',
            fontWeight: 700,
            transition: 'background-color var(--transition-fast)',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.backgroundColor = 'var(--color-primary-hover)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = 'var(--color-primary)';
          }}
        >
          <UserPlus size={16} />
          <span>Invite User</span>
        </button>
      </div>

      {/* SUMMARY TILES (3 white cards, responsive auto-fit) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '16px' }}>
        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-text-primary)' }}>47</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            Active Users
          </div>
          <div style={{ fontSize: '12px', color: 'var(--color-text-disabled)', marginTop: '4px' }}>
            31 Drivers · 11 Field Workers · 3 Officials · 2 Admins
          </div>
        </div>

        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-warning)' }}>2</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            Pending Approval
          </div>
          <div style={{ fontSize: '12px', color: 'var(--color-text-disabled)', marginTop: '4px' }}>
            Awaiting role verification
          </div>
        </div>

        <div className="tiyra-card" style={{ padding: '16px' }}>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-danger)' }}>1</div>
          <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            Suspended
          </div>
          <div style={{ fontSize: '12px', color: 'var(--color-text-disabled)', marginTop: '4px' }}>
            Access temporarily revoked
          </div>
        </div>
      </div>

      {/* USERS TABLE */}
      <div className="tiyra-card" style={{ padding: '20px' }}>
        {/* Filter bar */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '12px' }}>
          <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
            {(['ALL', 'DRIVER', 'FIELD_WORKER', 'OFFICIAL', 'ADMIN'] as const).map((r) => {
              const isActive = roleFilter === r;
              let label: string = r;
              if (r === 'FIELD_WORKER') label = 'FIELD WORKER';

              return (
                <button
                  key={r}
                  onClick={() => setRoleFilter(r)}
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
                  {label}
                </button>
              );
            })}
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              height: '34px',
              width: '200px',
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
              placeholder="Search user or email..."
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
          </div>
        </div>

        <div className="table-responsive-wrapper">
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
                <th style={{ padding: '0 12px' }}>User</th>
                <th style={{ padding: '0 12px' }}>Role</th>
                <th style={{ padding: '0 12px' }}>Status</th>
                <th style={{ padding: '0 12px' }}>Last Active</th>
                <th style={{ padding: '0 12px' }}>Registered</th>
                <th style={{ padding: '0 12px', textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((u) => (
                <tr
                  key={u.id}
                  style={{
                    height: '56px',
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
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div
                        style={{
                          width: '32px',
                          height: '32px',
                          borderRadius: '50%',
                          backgroundColor: 'var(--color-container)',
                          color: 'var(--color-text-secondary)',
                          fontSize: '12px',
                          fontWeight: 700,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        {u.initials}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>{u.name}</div>
                        <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{u.email}</div>
                      </div>
                    </div>
                  </td>
                  <td style={{ padding: '0 12px' }}>{renderRoleChip(u.role)}</td>
                  <td style={{ padding: '0 12px' }}>{renderStatusBadge(u.status)}</td>
                  <td style={{ padding: '0 12px' }}>
                    <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      {u.lastActive}
                    </span>
                  </td>
                  <td style={{ padding: '0 12px' }}>
                    <span className="mono" style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      {u.registered}
                    </span>
                  </td>
                  <td style={{ padding: '0 12px', textAlign: 'right' }}>
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                      <button
                        onClick={() => startEdit(u)}
                        style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-primary)', background: 'none', border: 'none', cursor: 'pointer' }}
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleToggleSuspend(u.id)}
                        style={{
                          fontSize: '12px',
                          fontWeight: 600,
                          color: u.status === 'SUSPENDED' ? 'var(--color-success)' : 'var(--color-danger)',
                        }}
                      >
                        {u.status === 'SUSPENDED' ? 'Reactivate' : 'Suspend'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* INVITE USER MODAL (centered overlay, white 480px, 16px radius, shadow, dark 40% backdrop) */}
      {isModalOpen && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.4)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 50,
          }}
          onClick={() => setIsModalOpen(false)}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              width: '100%',
              maxWidth: '480px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-lg)',
              padding: '24px',
              boxShadow: 'var(--modal-shadow)',
              border: '1px solid var(--color-border)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 style={{ fontSize: '17px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                Invite New User
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
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

            <form onSubmit={handleSendInvite} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Ramesh Chandra"
                  value={inviteName}
                  onChange={(e) => setInviteName(e.target.value)}
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
                  Email Address
                </label>
                <input
                  type="email"
                  required
                  placeholder="name@disastermgmt.gov.in"
                  value={inviteEmail}
                  onChange={(e) => setInviteEmail(e.target.value)}
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
                  Role Assignment
                </label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '6px' }}>
                  {(['DRIVER', 'FIELD_WORKER', 'OFFICIAL', 'ADMIN'] as const).map((r) => {
                    const isSelected = inviteRole === r;
                    let shortName: string = r;
                    if (r === 'FIELD_WORKER') shortName = 'Field';

                    return (
                      <button
                        type="button"
                        key={r}
                        onClick={() => setInviteRole(r)}
                        style={{
                          height: '36px',
                          borderRadius: 'var(--radius-sm)',
                          fontSize: '11px',
                          fontWeight: 600,
                          border: '1px solid',
                          borderColor: isSelected ? 'var(--color-primary)' : 'var(--color-border)',
                          backgroundColor: isSelected ? 'var(--color-primary-bg)' : '#FFFFFF',
                          color: isSelected ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                        }}
                      >
                        {shortName}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-primary)', marginBottom: '6px' }}>
                  Organization / Department
                </label>
                <input
                  type="text"
                  placeholder="e.g. ASDMA Division 2"
                  value={inviteOrg}
                  onChange={(e) => setInviteOrg(e.target.value)}
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

              <button
                type="submit"
                style={{
                  height: '44px',
                  backgroundColor: 'var(--color-primary)',
                  color: '#FFFFFF',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '13px',
                  fontWeight: 700,
                  marginTop: '8px',
                  cursor: 'pointer',
                }}
              >
                Send Invitation
              </button>
            </form>
          </div>
        </div>
      )}

      {/* EDIT USER MODAL */}
      {editingUser && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.45)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '16px',
          }}
          onClick={() => setEditingUser(null)}
        >
          <div
            className="tiyra-card"
            style={{
              width: '100%',
              maxWidth: '480px',
              backgroundColor: '#FFFFFF',
              borderRadius: 'var(--radius-lg)',
              boxShadow: '0 20px 40px rgba(0, 0, 0, 0.2)',
              overflow: 'hidden',
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
              <div>
                <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                  Edit User Profile
                </div>
                <div style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                  Modify privileges, organization status, and credentials
                </div>
              </div>
              <button
                onClick={() => setEditingUser(null)}
                style={{
                  border: 'none',
                  background: 'none',
                  color: 'var(--color-text-muted)',
                  cursor: 'pointer',
                  padding: '4px',
                }}
              >
                <X size={18} />
              </button>
            </div>

            {/* Edit Form */}
            <form onSubmit={handleSaveEdit} style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
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
                  Official Email Address
                </label>
                <input
                  type="email"
                  required
                  value={editEmail}
                  onChange={(e) => setEditEmail(e.target.value)}
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

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    Assigned Role
                  </label>
                  <select
                    value={editRole}
                    onChange={(e) => setEditRole(e.target.value as any)}
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
                    <option value="DRIVER">DRIVER</option>
                    <option value="FIELD_WORKER">FIELD_WORKER</option>
                    <option value="OFFICIAL">OFFICIAL</option>
                    <option value="ADMIN">ADMIN</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--color-text-secondary)', marginBottom: '4px' }}>
                    Account Status
                  </label>
                  <select
                    value={editStatus}
                    onChange={(e) => setEditStatus(e.target.value as any)}
                    style={{
                      width: '100%',
                      height: '38px',
                      padding: '0 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '13px',
                      backgroundColor: '#FFFFFF',
                      fontWeight: 600,
                      color: editStatus === 'ACTIVE' ? 'var(--color-success)' : editStatus === 'SUSPENDED' ? 'var(--color-danger)' : '#D97706',
                    }}
                  >
                    <option value="ACTIVE">ACTIVE</option>
                    <option value="PENDING">PENDING</option>
                    <option value="SUSPENDED">SUSPENDED</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
                <button
                  type="button"
                  onClick={() => setEditingUser(null)}
                  style={{
                    height: '38px',
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
                    height: '38px',
                    padding: '0 20px',
                    borderRadius: 'var(--radius-sm)',
                    border: 'none',
                    backgroundColor: 'var(--color-primary)',
                    color: '#FFFFFF',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
