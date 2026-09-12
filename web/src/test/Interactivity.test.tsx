import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { BrowserRouter, MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '../state/AuthContext';
import { AuthenticatedLayout } from '../layouts/AuthenticatedLayout';
import { JourneyPlanningModal } from '../components/JourneyPlanningModal';
import { AlertFeed } from '../pages/AlertFeed';
import { FieldReports } from '../pages/FieldReports';
import { SystemSettings } from '../pages/SystemSettings';
import { Dashboard } from '../pages/Dashboard';

describe('Web Platform Interactive Inputs & Consoles', () => {
  describe('JourneyPlanningModal', () => {
    it('renders modal with interactive origin, destination, vehicle, and cargo fields', () => {
      const onClose = vi.fn();
      render(
        <JourneyPlanningModal
          isOpen={true}
          onClose={onClose}
          initialOrigin="Guwahati (Assam)"
          initialDestination="Shillong (Meghalaya)"
        />
      );

      // Verify header & initial inputs
      expect(screen.getByText('Plan Journey & Route Assessment')).toBeInTheDocument();
      const originInput = screen.getByPlaceholderText('Search or enter origin hub...');
      const destInput = screen.getByPlaceholderText('Search or enter destination...');
      expect(originInput).toHaveValue('Guwahati (Assam)');
      expect(destInput).toHaveValue('Shillong (Meghalaya)');

      // Test typing into origin
      fireEvent.change(originInput, { target: { value: 'Silchar Hub' } });
      expect(originInput).toHaveValue('Silchar Hub');

      // Test location swap
      const swapButton = screen.getByText('Swap Hubs');
      fireEvent.click(swapButton);
      expect(originInput).toHaveValue('Shillong (Meghalaya)');
      expect(destInput).toHaveValue('Silchar Hub');

      // Test Vehicle profile selection
      const vehicleSelect = screen.getByDisplayValue(/Tata Prima 31T/i);
      fireEvent.change(vehicleSelect, { target: { value: 'Mahindra Bolero Maxi' } });
      expect(screen.getByDisplayValue(/Mahindra Bolero Maxi/i)).toBeInTheDocument();

      // Test Route candidate selection
      const routeBCard = screen.getByText(/Route B · Direct Hill Bypass/i);
      fireEvent.click(routeBCard);

      // Test Confirm Route button
      const confirmButton = screen.getByRole('button', { name: /Confirm Route/i });
      fireEvent.click(confirmButton);

      expect(screen.getByText(/Dispatching navigation vectors/i)).toBeInTheDocument();
    });
  });

  describe('AlertFeed Interactivity', () => {
    it('filters alerts by search query and allows broadcasting a new alert', async () => {
      render(<AlertFeed />);

      // Search filtering
      const searchInput = screen.getByPlaceholderText('Search alert title, corridor, or district...');
      fireEvent.change(searchInput, { target: { value: 'NH-06' } });
      expect(screen.getByDisplayValue('NH-06')).toBeInTheDocument();

      // Open Broadcast Modal
      const broadcastBtn = screen.getByRole('button', { name: /Broadcast Alert/i });
      fireEvent.click(broadcastBtn);

      expect(screen.getByText('Broadcast Tactical Advisory')).toBeInTheDocument();

      // Enter headline & situation description
      const headlineInput = screen.getByPlaceholderText(/Active Rockfall Warning/i);
      const descInput = screen.getByPlaceholderText(/Describe observed trigger/i);
      fireEvent.change(headlineInput, { target: { value: 'Emergency Test Advisory NH-06' } });
      fireEvent.change(descInput, { target: { value: 'Single-lane debris clearance underway.' } });

      // Transmit broadcast
      const transmitBtn = screen.getByRole('button', { name: /Transmit Broadcast/i });
      fireEvent.click(transmitBtn);

      await waitFor(() => {
        expect(screen.getByText(/successfully broadcast across operations room/i)).toBeInTheDocument();
      });
    });
  });

  describe('FieldReports Interactivity', () => {
    it('allows filtering by status, search, and creating new reconnaissance report', async () => {
      render(<FieldReports />);

      // Status chip click
      const pendingChip = screen.getByRole('button', { name: 'PENDING' });
      fireEvent.click(pendingChip);

      // Open Submit Recon Report modal
      const submitButtons = screen.getAllByRole('button', { name: /Submit Recon Report/i });
      fireEvent.click(submitButtons[0]);

      expect(screen.getByText('Submit Field Reconnaissance Report')).toBeInTheDocument();

      // Fill in details
      const descTextarea = screen.getByPlaceholderText(/Describe slope condition/i);
      fireEvent.change(descTextarea, { target: { value: 'High precipitation slope failure observed near culvert.' } });

      // Submit form inside modal
      const modalSubmitBtn = screen.getAllByRole('button', { name: /Submit Recon Report/i })[1];
      fireEvent.click(modalSubmitBtn);

      await waitFor(() => {
        expect(screen.getByText(/logged and added to operations queue/i)).toBeInTheDocument();
      });
    });

    it('allows deleting reports from table row and review panel with confirmation', async () => {
      const confirmSpy = vi.spyOn(window, 'confirm').mockImplementation(() => true);
      render(<FieldReports />);

      // Verify report RP-2847 exists initially (in table and default selected panel)
      expect(screen.getAllByText('RP-2847').length).toBeGreaterThan(0);

      // Click delete button on report row
      const deleteRowBtn = screen.getByTestId('delete-report-btn-RP-2847');
      fireEvent.click(deleteRowBtn);

      // Verify confirmation dialog was invoked
      expect(confirmSpy).toHaveBeenCalledWith(
        expect.stringContaining('Are you sure you want to permanently delete report RP-2847?')
      );

      // Verify success feedback and row removed
      expect(screen.getByText(/Report RP-2847 permanently purged/i)).toBeInTheDocument();
      expect(screen.queryByText('RP-2847')).not.toBeInTheDocument();

      // Test panel deletion: select another report to view in panel
      const reviewButtons = screen.getAllByRole('button', { name: 'Review' });
      fireEvent.click(reviewButtons[0]);

      // Click panel delete button
      const panelDeleteBtn = screen.getByTestId('panel-delete-report-btn');
      fireEvent.click(panelDeleteBtn);

      expect(confirmSpy).toHaveBeenCalled();
      confirmSpy.mockRestore();
    });
  });

  describe('SystemSettings Interactivity', () => {
    it('supports tab switching and risk threshold calibration', () => {
      render(
        <BrowserRouter>
          <SystemSettings />
        </BrowserRouter>
      );

      // Switch to Data Sources tab
      const dataSourcesTab = screen.getByRole('button', { name: /Data Sources/i });
      fireEvent.click(dataSourcesTab);
      expect(screen.getByText('Data Source Status & Telemetry')).toBeInTheDocument();

      // Switch to Risk Thresholds tab
      const thresholdsTab = screen.getByRole('button', { name: /Risk Thresholds/i });
      fireEvent.click(thresholdsTab);
      expect(screen.getByText('Risk Score Threshold Policies')).toBeInTheDocument();

      // Save Thresholds button
      const saveThresholdsBtn = screen.getByRole('button', { name: /Save Thresholds/i });
      fireEvent.click(saveThresholdsBtn);
      expect(screen.getByText(/applied to live inference engine/i)).toBeInTheDocument();

      // Switch to Alert Rules tab
      const rulesTab = screen.getByRole('button', { name: /Alert Rules/i });
      fireEvent.click(rulesTab);
      expect(screen.getByText('Tactical Advisory & Alert Rules')).toBeInTheDocument();
    });

    it('loads Evidence & Storage tab directly via URL parameter with refresh controls', async () => {
      render(
        <MemoryRouter initialEntries={['/settings?tab=storage']}>
          <SystemSettings />
        </MemoryRouter>
      );

      // Verify Storage tab is active and visible
      expect(screen.getByText('Cloud Storage & Evidence Assets')).toBeInTheDocument();
      expect(screen.getByText(/TOTAL EVIDENCE IMAGES/i)).toBeInTheDocument();
      expect(screen.getByText(/TOTAL STORAGE FOOTPRINT/i)).toBeInTheDocument();

      // Verify Refresh Storage button works
      const refreshBtn = screen.getByTestId('refresh-storage-btn');
      expect(refreshBtn).toBeInTheDocument();
      fireEvent.click(refreshBtn);
    });
  });

  describe('Dashboard Interactivity & Role Actions', () => {
    it('renders Storage & Evidence quick action button for ADMIN role', () => {
      localStorage.setItem('tiyrasense_token', 'mock_token');
      localStorage.setItem(
        'tiyrasense_user',
        JSON.stringify({ id: 'u-admin', name: 'Nodal Director', email: 'admin@tiyrasense.gov.in', role: 'ADMIN' })
      );

      render(
        <AuthProvider>
          <BrowserRouter>
            <Dashboard />
          </BrowserRouter>
        </AuthProvider>
      );

      // Admin quick action button should be visible
      const adminStorageBtns = screen.getAllByTestId('admin-storage-btn');
      expect(adminStorageBtns.length).toBeGreaterThan(0);
      expect(adminStorageBtns[0]).toHaveTextContent('Storage & Evidence');

      // Click admin storage button
      fireEvent.click(adminStorageBtns[0]);

      localStorage.clear();
    });
  });

  describe('AuthenticatedLayout Side Panel Toggle', () => {
    it('keeps the side panel hidden by default and brings it into view when 3-lines button is clicked', () => {
      render(
        <AuthProvider>
          <BrowserRouter>
            <AuthenticatedLayout />
          </BrowserRouter>
        </AuthProvider>
      );

      // Verify side panel is initially hidden
      const sidePanel = screen.getByTestId('side-panel');
      expect(sidePanel).toHaveStyle({ visibility: 'hidden' });
      expect(sidePanel.style.transform).toBe('translateX(-100%)');
      expect(screen.queryByTestId('sidebar-backdrop')).not.toBeInTheDocument();

      // Find the 3-lines button (hamburger button)
      const toggleBtn = screen.getByTestId('sidebar-toggle-btn');
      expect(toggleBtn).toBeInTheDocument();

      // Click the 3-lines button to bring side panel into view
      fireEvent.click(toggleBtn);

      // Verify side panel is now in view
      expect(sidePanel).toHaveStyle({ visibility: 'visible' });
      expect(sidePanel.style.transform).toBe('translateX(0)');
      expect(screen.getByTestId('sidebar-backdrop')).toBeInTheDocument();
      expect(screen.getByText('Command Panel')).toBeInTheDocument();

      // Click the close button inside the side panel to hide it
      const closeBtn = screen.getByTestId('sidebar-close-btn');
      fireEvent.click(closeBtn);

      // Verify side panel is hidden again
      expect(sidePanel).toHaveStyle({ visibility: 'hidden' });
      expect(sidePanel.style.transform).toBe('translateX(-100%)');
      expect(screen.queryByTestId('sidebar-backdrop')).not.toBeInTheDocument();

      // Click 3-lines button again to open, then click backdrop to close
      fireEvent.click(toggleBtn);
      expect(sidePanel).toHaveStyle({ visibility: 'visible' });
      const backdrop = screen.getByTestId('sidebar-backdrop');
      fireEvent.click(backdrop);
      expect(sidePanel).toHaveStyle({ visibility: 'hidden' });
    });

    it('navigates to dashboard when navbar logo link is clicked', () => {
      render(
        <AuthProvider>
          <BrowserRouter>
            <AuthenticatedLayout />
          </BrowserRouter>
        </AuthProvider>
      );

      const logoLink = screen.getByTestId('navbar-logo-link');
      expect(logoLink).toBeInTheDocument();
      expect(logoLink).toHaveAttribute('href', '/dashboard');
      expect(screen.getByAltText('TiyraSense Icon')).toBeInTheDocument();
      expect(screen.getByText('NER INTELLIGENCE')).toBeInTheDocument();
    });
  });
});

