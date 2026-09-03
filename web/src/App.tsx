import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './state/AuthContext';
import { AuthenticatedLayout } from './layouts/AuthenticatedLayout';
import { RoleGuard } from './routes/RoleGuard';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Admin } from './pages/Admin';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public Login Route */}
          <Route path="/login" element={<Login />} />

          {/* Authenticated Official Dashboard */}
          <Route
            path="/dashboard"
            element={
              <RoleGuard allowedRoles={['OFFICIAL', 'ADMIN']}>
                <AuthenticatedLayout />
              </RoleGuard>
            }
          >
            <Route index element={<Dashboard />} />
          </Route>

          {/* Authenticated Admin Governance Console */}
          <Route
            path="/admin"
            element={
              <RoleGuard allowedRoles={['ADMIN']}>
                <AuthenticatedLayout />
              </RoleGuard>
            }
          >
            <Route index element={<Admin />} />
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
