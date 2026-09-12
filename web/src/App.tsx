import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './state/AuthContext';
import { AuthenticatedLayout } from './layouts/AuthenticatedLayout';
import { RoleGuard } from './routes/RoleGuard';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { CorridorMonitor } from './pages/CorridorMonitor';
import { FieldReports } from './pages/FieldReports';
import { AlertFeed } from './pages/AlertFeed';
import { UserManagement } from './pages/UserManagement';
import { SystemSettings } from './pages/SystemSettings';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public Login Route (W1) */}
          <Route path="/login" element={<Login />} />

          {/* Authenticated Official + Admin Operations Routes */}
          <Route
            element={
              <RoleGuard allowedRoles={['OFFICIAL', 'ADMIN']}>
                <AuthenticatedLayout />
              </RoleGuard>
            }
          >
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/corridors" element={<CorridorMonitor />} />
            <Route path="/reports" element={<FieldReports />} />
            <Route path="/alerts" element={<AlertFeed />} />
            {/* Direct navigation alias */}
            <Route path="/field-reports" element={<Navigate to="/reports" replace />} />
          </Route>

          {/* Authenticated Admin Administration Routes */}
          <Route
            element={
              <RoleGuard allowedRoles={['ADMIN']}>
                <AuthenticatedLayout />
              </RoleGuard>
            }
          >
            <Route path="/users" element={<UserManagement />} />
            <Route path="/settings" element={<SystemSettings />} />
            <Route path="/admin" element={<Navigate to="/users" replace />} />
            <Route path="/admin/users" element={<Navigate to="/users" replace />} />
            <Route path="/admin/settings" element={<Navigate to="/settings" replace />} />
          </Route>

          {/* Fallback Redirections */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
};

export default App;
