import { render, screen, fireEvent, within } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { BrowserRouter } from 'react-router-dom';
import {
  haversineKm,
  calculateRoadDistanceKm,
  computeDetailedBreakdown,
} from '../utils/distanceUtils';
import { DistanceClausesModal } from '../components/DistanceClausesModal';
import { VectorGisMap } from '../components/VectorGisMap';
import { Dashboard } from '../pages/Dashboard';
import { AuthProvider } from '../state/AuthContext';

describe('TiyraSense Web Distance & Regulatory Clauses Engine', () => {
  it('calculates geodesic WGS-84 Haversine distance and mountain road distance correctly', () => {
    // Guwahati (26.1445, 91.7362) to Shillong (25.5788, 91.8933) is ~64.8 km aerial
    const aerial = haversineKm(26.1445, 91.7362, 25.5788, 91.8933);
    expect(aerial).toBeGreaterThan(60);
    expect(aerial).toBeLessThan(70);

    const road = calculateRoadDistanceKm(26.1445, 91.7362, 25.5788, 91.8933);
    expect(road).toBeGreaterThan(aerial);
    expect(road).toBe(Math.round(aerial * 1.38 * 10) / 10);
  });

  it('computes all 5 regulatory & engineering clauses according to Indian Road Congress and MoRTH rules', () => {
    const breakdown = computeDetailedBreakdown({
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Tata Prima 31T Heavy Multi-Axle',
      cargoTitle: 'Petroleum & POL Fuel',
      isSafestRoute: true,
    });

    // 1. Aerial Base
    expect(breakdown.baseAerialKm).toBeGreaterThan(60);

    // 2. IRC:SP:48 Topographic Curvature (+38%)
    expect(breakdown.topographicCurvatureKm).toBe(
      Math.round(breakdown.baseAerialKm * 0.38 * 10) / 10
    );

    // 3. MoRTH Heavy Multi-Axle (>25T GVW) Clearance (+12%)
    expect(breakdown.vehicleAxleClearanceKm).toBe(
      Math.round(breakdown.baseAerialKm * 0.12 * 10) / 10
    );

    // 4. Safety Hazard Detour (TiyraSense D-006: +14% / min 8km)
    expect(breakdown.hazardDetourKm).toBe(
      Math.round(Math.max(8.0, breakdown.baseAerialKm * 0.14) * 10) / 10
    );

    // 5. CMVR Rule 131 Cargo Protocol Buffer (+3% for HAZMAT/POL)
    expect(breakdown.cargoBufferKm).toBe(
      Math.round(breakdown.baseAerialKm * 0.03 * 10) / 10
    );

    // Sum validation
    const expectedTotal = Math.round(
      (breakdown.baseAerialKm +
        breakdown.topographicCurvatureKm +
        breakdown.vehicleAxleClearanceKm +
        breakdown.hazardDetourKm +
        breakdown.cargoBufferKm) *
        10
    ) / 10;
    expect(breakdown.totalRoadKm).toBe(expectedTotal);
    expect(breakdown.items.length).toBe(5);
  });

  it('adjusts vehicle axle clause for Light 4x4 vs Medium vs Heavy', () => {
    const heavy = computeDetailedBreakdown({
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Tata Prima 31T',
      isSafestRoute: true,
    });

    const medium = computeDetailedBreakdown({
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Ashok Leyland 1618 Medium 16 Ton',
      isSafestRoute: true,
    });

    const light = computeDetailedBreakdown({
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Mahindra Bolero Maxi 4x4',
      isSafestRoute: true,
    });

    expect(heavy.vehicleAxleClearanceKm).toBeGreaterThan(medium.vehicleAxleClearanceKm);
    expect(medium.vehicleAxleClearanceKm).toBeGreaterThan(light.vehicleAxleClearanceKm);
  });
});

describe('DistanceClausesModal Component', () => {
  it('renders all applied clauses, regulatory citations, and closes on request', () => {
    const breakdown = computeDetailedBreakdown({
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Tata Prima 31T',
      cargoTitle: 'FMCG Critical',
      isSafestRoute: true,
    });

    const handleClose = vi.fn();
    render(
      <DistanceClausesModal
        isOpen={true}
        onClose={handleClose}
        breakdown={breakdown}
        originName="Guwahati Port Hub"
        destName="Shillong Terminal Hub"
        vehicleName="Tata Prima 31T"
        cargoName="FMCG Critical"
        routeName="NH-06 via Nongpoh"
      />
    );

    expect(
      screen.getByText('Distance Clauses & Regulatory Terrain Audit')
    ).toBeInTheDocument();
    expect(screen.getByText('Topographic Curvature Clause')).toBeInTheDocument();
    expect(
      screen.getByText('IRC:SP:48 / D-015 Hill Road Guidelines')
    ).toBeInTheDocument();
    expect(
      screen.getByText('Vehicle Axle & Weight Clearance Clause')
    ).toBeInTheDocument();
    expect(
      screen.getByText('MoRTH Heavy Vehicle Axle Rules')
    ).toBeInTheDocument();

    const closeBtn = screen.getByText('Close Audit View');
    fireEvent.click(closeBtn);
    expect(handleClose).toHaveBeenCalledTimes(1);
  });
});

describe('VectorGisMap Component', () => {
  it('renders the interactive vector GIS map with telemetry HUD and scale bar', () => {
    const handleClauses = vi.fn();
    render(
      <VectorGisMap
        originName="Guwahati Port Hub"
        destName="Shillong Terminal Hub"
        routeName="NH-06 via Nongpoh"
        vehicleName="Tata Prima 31T"
        cargoName="Standard Dry Cargo"
        roleMode="driver"
        onOpenClauses={handleClauses}
      />
    );

    expect(screen.getByText('Guwahati → Shillong')).toBeInTheDocument();
    expect(screen.getByText(/NH-06 via Nongpoh/)).toBeInTheDocument();
    expect(screen.getByText(/38 KM\/H/)).toBeInTheDocument();
    expect(screen.getByText(/Open GIS/)).toBeInTheDocument();

    // Open clauses audit button
    const clausesBtn = screen.getByRole('button', { name: /Clauses Audit/i });
    expect(clausesBtn).toBeInTheDocument();
    fireEvent.click(clausesBtn);
    expect(handleClauses).toHaveBeenCalledTimes(1);
  });

  it('allows user to switch between Satellite, Road, and Terrain views and toggle alerts/incidents', () => {
    render(
      <VectorGisMap
        originName="Guwahati Port Hub"
        destName="Shillong Terminal Hub"
        routeName="NH-06 via Nongpoh"
      />
    );

    // Initial state: layer popup is closed
    expect(screen.queryByTestId('map-layers-popup')).not.toBeInTheDocument();

    // Click layers button
    const layersBtn = screen.getByTestId('map-layers-toggle-btn');
    expect(layersBtn).toBeInTheDocument();
    fireEvent.click(layersBtn);

    // Popup opens showing "Map type" and options
    expect(screen.getByTestId('map-layers-popup')).toBeInTheDocument();
    expect(screen.getByText('Map type')).toBeInTheDocument();
    expect(screen.getByText('Default')).toBeInTheDocument();
    expect(screen.getByText('Satellite')).toBeInTheDocument();
    expect(screen.getByText('Terrain')).toBeInTheDocument();
    expect(screen.getByText('Map details')).toBeInTheDocument();

    // Switch to Satellite
    fireEvent.click(screen.getByTestId('layer-type-satellite'));
    // Switch to Terrain
    fireEvent.click(screen.getByTestId('layer-type-terrain'));
    // Switch back to Default
    fireEvent.click(screen.getByTestId('layer-type-road'));

    // Toggle Alerts detail
    const alertsToggle = screen.getByTestId('layer-detail-alerts');
    fireEvent.click(alertsToggle);

    // Toggle Incidents detail
    const incidentsToggle = screen.getByTestId('layer-detail-incidents');
    fireEvent.click(incidentsToggle);

    // Close popup
    const closeBtn = screen.getByRole('button', { name: /Close/i });
    fireEvent.click(closeBtn);
    expect(screen.queryByTestId('map-layers-popup')).not.toBeInTheDocument();
  });
});

describe('Role-Based Dashboard Telemetry & Fleet Tracking', () => {
  it('adapts operational banner and tools according to the active user role', () => {
    // Test that Dashboard renders with role console
    render(
      <BrowserRouter>
        <AuthProvider>
          <Dashboard />
        </AuthProvider>
      </BrowserRouter>
    );

    expect(screen.getByText('Operations Overview')).toBeInTheDocument();
    expect(screen.getByText(/ROLE:/i)).toBeInTheDocument();
    expect(screen.getByText('Plan Journey')).toBeInTheDocument();
  });

  it('allows OFFICIAL and ADMIN roles to view and track each vehicle live location on Dashboard', () => {
    render(
      <BrowserRouter>
        <AuthProvider>
          <Dashboard />
        </AuthProvider>
      </BrowserRouter>
    );

    // Default role in AuthContext is OFFICIAL
    expect(screen.getByTestId('fleet-tracking-console')).toBeInTheDocument();
    expect(
      screen.getByText('NER Fleet Live Location Tracking & Telemetry Console')
    ).toBeInTheDocument();

    // Verify fleet selector buttons are present for all active vehicles
    expect(screen.getByTestId('select-vehicle-TRK-01')).toBeInTheDocument();
    expect(screen.getByTestId('select-vehicle-TRK-02')).toBeInTheDocument();
    expect(screen.getByTestId('select-vehicle-TRK-03')).toBeInTheDocument();
    expect(screen.getByTestId('select-vehicle-MED-04')).toBeInTheDocument();
    expect(screen.getByTestId('select-vehicle-RECON-05')).toBeInTheDocument();

    // Default selected vehicle is TRK-01 (Tata Prima)
    const inspector = screen.getByTestId('vehicle-telemetry-inspector');
    expect(inspector).toBeInTheDocument();
    expect(within(inspector).getByText(/Tata Prima 31T/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/Rajeshwar Sharma/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/25.8617°N, 91.8148°E/i)).toBeInTheDocument();

    // Switch to TRK-02 (BharatBenz)
    fireEvent.click(screen.getByTestId('select-vehicle-TRK-02'));

    // Verify inspector updates to TRK-02 live location and telemetry
    expect(within(inspector).getByText(/BharatBenz 2823R/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/Bikramjit Gogoi/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/25.4200°N, 92.7100°E/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/KM 81-86 Flash Flood/i)).toBeInTheDocument();

    // Switch to MED-04 (Emergency Mobile Clinic)
    fireEvent.click(screen.getByTestId('select-vehicle-MED-04'));
    expect(within(inspector).getByText(/Mahindra Bolero Camper/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/Sanborlang Lyngdoh/i)).toBeInTheDocument();
    expect(within(inspector).getByText(/25.7200°N, 90.3900°E/i)).toBeInTheDocument();
  });

  it('displays Official role operational triggers and verification queue on Dashboard', () => {
    render(
      <BrowserRouter>
        <AuthProvider>
          <Dashboard />
        </AuthProvider>
      </BrowserRouter>
    );

    // Official trigger and review buttons
    expect(screen.getByTestId('official-trigger-alert-btn')).toBeInTheDocument();
    expect(screen.getByTestId('official-verify-reports-btn')).toBeInTheDocument();
    expect(screen.getByTestId('official-plan-journey-btn')).toBeInTheDocument();

    // Field incident reports verification queue
    expect(screen.getByTestId('official-reports-verification-queue')).toBeInTheDocument();
    expect(screen.getByText('Field Incident Verification Queue')).toBeInTheDocument();
    expect(screen.getByText('RP-2847')).toBeInTheDocument();
  });

  it('renders interactive fleet markers in VectorGisMap and handles selection', () => {
    const handleSelect = vi.fn();
    const mockVehicles: any = [
      {
        id: 'TRK-01',
        vehicleNumber: 'AS-01-GC-4921',
        model: 'Tata Prima 31T',
        driverName: 'Rajeshwar Sharma',
        role: 'DRIVER',
        cargo: 'FMCG Critical',
        originName: 'Guwahati Port Hub',
        destName: 'Shillong Terminal Hub',
        originCoords: { lat: 26.1445, lng: 91.7362 },
        destCoords: { lat: 25.5788, lng: 91.8933 },
        routeName: 'NH-06 via Nongpoh',
        currentCoords: { lat: 25.8617, lng: 91.8148 },
        speedKmh: 42,
        progress: 0.52,
        status: 'IN_TRANSIT',
        lastPing: '12s ago',
      },
      {
        id: 'TRK-02',
        vehicleNumber: 'AS-09-C-8812',
        model: 'BharatBenz 2823R',
        driverName: 'Bikramjit Gogoi',
        role: 'DRIVER',
        cargo: 'Pharmaceuticals',
        originName: 'Nagaon Logistics Depot',
        destName: 'Silchar Supply Terminal',
        originCoords: { lat: 26.3465, lng: 92.6840 },
        destCoords: { lat: 24.8333, lng: 92.7789 },
        routeName: 'NH-29 via Dabaka',
        currentCoords: { lat: 25.4200, lng: 92.7100 },
        speedKmh: 31,
        progress: 0.61,
        status: 'HAZARD_SLOWED',
        lastPing: '28s ago',
      },
    ];

    render(
      <VectorGisMap
        vehicles={mockVehicles}
        selectedVehicleId="TRK-01"
        onSelectVehicle={handleSelect}
      />
    );

    const marker01 = screen.getByTestId('fleet-marker-TRK-01');
    const marker02 = screen.getByTestId('fleet-marker-TRK-02');
    expect(marker01).toBeInTheDocument();
    expect(marker02).toBeInTheDocument();

    fireEvent.click(marker02);
    expect(handleSelect).toHaveBeenCalledWith(mockVehicles[1]);
  });

  it('supports toggling between Selected Route Focused mode and All Locations Only mode in VectorGisMap', () => {
    const handleModeChange = vi.fn();
    const mockVehicles: any = [
      {
        id: 'TRK-01',
        vehicleNumber: 'AS-01-GC-4921',
        model: 'Tata Prima 31T',
        driverName: 'Rajeshwar Sharma',
        role: 'DRIVER',
        cargo: 'FMCG Critical',
        originName: 'Guwahati Port Hub',
        destName: 'Shillong Terminal Hub',
        originCoords: { lat: 26.1445, lng: 91.7362 },
        destCoords: { lat: 25.5788, lng: 91.8933 },
        routeName: 'NH-06 via Nongpoh',
        currentCoords: { lat: 25.8617, lng: 91.8148 },
        speedKmh: 42,
        progress: 0.52,
        status: 'IN_TRANSIT',
        lastPing: '12s ago',
      },
      {
        id: 'TRK-02',
        vehicleNumber: 'AS-09-C-8812',
        model: 'BharatBenz 2823R',
        driverName: 'Bikramjit Gogoi',
        role: 'DRIVER',
        cargo: 'Pharmaceuticals',
        originName: 'Nagaon Logistics Depot',
        destName: 'Silchar Supply Terminal',
        originCoords: { lat: 26.3465, lng: 92.6840 },
        destCoords: { lat: 24.8333, lng: 92.7789 },
        routeName: 'NH-29 via Dabaka',
        currentCoords: { lat: 25.4200, lng: 92.7100 },
        speedKmh: 31,
        progress: 0.61,
        status: 'HAZARD_SLOWED',
        lastPing: '28s ago',
      },
    ];

    const { rerender } = render(
      <VectorGisMap
        vehicles={mockVehicles}
        selectedVehicleId="TRK-01"
        fleetViewMode="selected"
        onFleetViewModeChange={handleModeChange}
      />
    );

    // In 'selected' mode: only selected vehicle (TRK-01) marker is rendered; TRK-02 is hidden
    expect(screen.getByTestId('fleet-marker-TRK-01')).toBeInTheDocument();
    expect(screen.queryByTestId('fleet-marker-TRK-02')).not.toBeInTheDocument();

    // Toggle button exists
    const allModeBtn = screen.getByTestId('view-mode-all');
    fireEvent.click(allModeBtn);
    expect(handleModeChange).toHaveBeenCalledWith('all');

    // In 'all' mode: both vehicles' current location markers are rendered
    rerender(
      <VectorGisMap
        vehicles={mockVehicles}
        selectedVehicleId="TRK-01"
        fleetViewMode="all"
        onFleetViewModeChange={handleModeChange}
      />
    );
    expect(screen.getByTestId('fleet-marker-TRK-01')).toBeInTheDocument();
    expect(screen.getByTestId('fleet-marker-TRK-02')).toBeInTheDocument();
    expect(screen.getByTestId('fleet-all-locations-hud')).toBeInTheDocument();
  });

  it('allows filtering fleet vehicles by vehicle type, cargo, operational hazard mode, and search text on Dashboard', () => {
    render(
      <BrowserRouter>
        <AuthProvider>
          <Dashboard />
        </AuthProvider>
      </BrowserRouter>
    );

    // Filter toolbar elements
    expect(screen.getByTestId('fleet-search-input')).toBeInTheDocument();
    expect(screen.getByTestId('filter-vehicle-type')).toBeInTheDocument();
    expect(screen.getByTestId('filter-cargo-type')).toBeInTheDocument();
    expect(screen.getByTestId('filter-op-mode')).toBeInTheDocument();

    // Filter by Operational Mode: Stopped / Hazard Delayed
    fireEvent.change(screen.getByTestId('filter-op-mode'), {
      target: { value: 'HAZARD_SLOWED' },
    });

    // Only TRK-02 (BharatBenz) is hazard slowed
    expect(screen.getByTestId('select-vehicle-TRK-02')).toBeInTheDocument();
    expect(screen.queryByTestId('select-vehicle-TRK-01')).not.toBeInTheDocument();
    expect(screen.queryByTestId('select-vehicle-MED-04')).not.toBeInTheDocument();

    // Click Reset
    fireEvent.click(screen.getByTestId('clear-fleet-filters'));

    // All vehicles are back
    expect(screen.getByTestId('select-vehicle-TRK-01')).toBeInTheDocument();
    expect(screen.getByTestId('select-vehicle-TRK-02')).toBeInTheDocument();
    expect(screen.getByTestId('select-vehicle-MED-04')).toBeInTheDocument();

    // Filter by Vehicle Type: EMERGENCY (Mobile Clinic)
    fireEvent.change(screen.getByTestId('filter-vehicle-type'), {
      target: { value: 'EMERGENCY' },
    });
    expect(screen.getByTestId('select-vehicle-MED-04')).toBeInTheDocument();
    expect(screen.queryByTestId('select-vehicle-TRK-01')).not.toBeInTheDocument();

    // Reset again
    fireEvent.click(screen.getByTestId('clear-fleet-filters'));

    // View mode switch on Console
    expect(screen.getByTestId('console-view-mode-selected')).toBeInTheDocument();
    expect(screen.getByTestId('console-view-mode-all')).toBeInTheDocument();
    fireEvent.click(screen.getByTestId('console-view-mode-all'));
    fireEvent.click(screen.getByTestId('console-view-mode-selected'));
  });
});


