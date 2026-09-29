# TiyraSense Web Operations Console & Admin Portal

The web frontend of **TiyraSense** provides an interactive, real-time command dashboard for disaster management officials, regional transport authorities, and fleet dispatchers across the North Eastern Region (NER).

It features dynamic Leaflet GIS map visualization, live corridor risk heatmaps, vehicle radar telemetry tracking, field incident verification workbenches with photo evidence review, emergency alert broadcasting, system settings governance, and user management.

---

## 1. Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|:---:|---|
| **Core Framework** | React | 18.2+ | Component-driven declarative UI |
| **Language** | TypeScript | 5.4+ | Strict type safety and compilation verification |
| **Build & Dev Tooling** | Vite | 8.2+ | Lightning-fast HMR and optimized production bundling |
| **Routing** | React Router | 7.18+ | Client-side declarative routing and history management |
| **GIS Mapping** | Leaflet + OpenStreetMap | 1.9+ | Interactive spatial rendering, route overlays, hazard markers |
| **Styling & Design** | Vanilla CSS + CSS Variables | Modern CSS | 4-tier responsive breakpoint system, high-contrast dark theme, fluid status cards |
| **Iconography** | Lucide React | 0.363+ | Clean, accessible vector UI icons |
| **State & Auth** | React Context (`AuthContext`) | Native | Session token management, inactivity auto-logout, user roles |
| **Security / RBAC** | `RoleGuard` Route Component | Custom | Client-side authorization gate enforcing `OFFICIAL` & `ADMIN` access |
| **Testing** | Vitest + React Testing Library + jsdom | 5.0+ / 14.2+ | Component mounting, interaction, and integration test coverage |

---

## 2. Directory Structure

```text
web/
├── public/
│   └── _redirects                    # Cloudflare Pages SPA routing rule (/* /index.html 200)
├── src/
│   ├── assets/                       # SVG logos and branded graphics
│   ├── components/                   # Reusable modular UI components
│   │   ├── AccountDetailsModal.tsx   # User profile and session inspection modal
│   │   ├── Button.tsx                # Accessible, styled button component
│   │   ├── DistanceClausesModal.tsx  # Terrain, axle, and hazard clause factor modal
│   │   ├── Header.tsx                # Top navigation bar with active alerts & user badge
│   │   ├── JourneyPlanningModal.tsx  # Dispatcher multi-candidate route evaluator modal
│   │   ├── Sidebar.tsx               # Collapsible navigation drawer with role-based links
│   │   ├── StatusBadge.tsx           # Semantic badges (OPEN, CAUTION, HIGH_RISK, BLOCKED)
│   │   └── VectorGisMap.tsx          # Leaflet GIS map with route polylines & hazard markers
│   ├── layouts/
│   │   └── AuthenticatedLayout.tsx   # Master layout with responsive sidebar and header
│   ├── pages/                        # Role-specific operational views
│   │   ├── AlertFeed.tsx             # Real-time incident alert broadcast & acknowledgment feed
│   │   ├── CorridorMonitor.tsx       # Live NH corridor status, risk scoring, and incident counts
│   │   ├── Dashboard.tsx             # Master dispatch command center (map + KPI metrics + feed)
│   │   ├── FieldReports.tsx          # Incident verification workbench with photo evidence lightbox
│   │   ├── Login.tsx                 # Official & Admin secure authentication portal
│   │   ├── SystemSettings.tsx        # System governance, risk thresholds, jurisdiction, alert rules
│   │   └── UserManagement.tsx        # Role administration & personnel provisioning
│   ├── routes/
│   │   └── RoleGuard.tsx             # Client-side route protection by role hierarchy
│   ├── services/
│   │   └── api.ts                    # Typed API client with automatic JWT header attachment
│   ├── state/
│   │   └── AuthContext.tsx           # React Context providing user profile and 30-min inactivity logout
│   ├── test/                         # Vitest test specs
│   │   ├── Interactivity.test.tsx    # Modal interactions, form controls, and UI element tests
│   │   ├── LiveTrackingAndClauses.test.tsx # Live vehicle tracking and distance clause tests
│   │   └── Login.test.tsx            # Authentication flow tests
│   ├── types/
│   │   └── auth.ts                   # TypeScript interfaces for users, roles, and tokens
│   ├── App.tsx                       # Root routing configuration
│   ├── index.css                     # Global typography, color tokens, responsive utility classes
│   └── main.tsx                      # Vite React application entrypoint
├── index.html                        # HTML shell
├── package.json                      # NPM package definitions and scripts
├── tsconfig.json                     # TypeScript compiler configuration
└── vite.config.ts                    # Vite build and test configuration
```

---

## 3. Key Features & Workflows

### 3.1 Interactive GIS Corridor Map (`VectorGisMap.tsx`)
- Renders the primary logistics arteries (NH-06 Guwahati–Shillong corridor, Damra–Mawkyrwat bypass, NH-27, NH-37).
- Color-codes road segments by real-time accessibility state:
  - 🟢 **OPEN**: Normal transit conditions.
  - 🟡 **CAUTION**: Deteriorating weather or minor surface runoff.
  - 🟠 **HIGH RISK**: Impending landslide threat or heavy waterlogging.
  - 🔴 **BLOCKED**: Confirmed physical obstruction or structural road cut.
- Overlays live GPS fleet radar pins with vehicle speed, heading, and driver contact info.
- Google Maps styled layer switcher: Default, Satellite, Terrain.

### 3.2 Field Incident Verification Workbench (`FieldReports.tsx`)
- Disaster officials review crowdsourced and field-worker hazard reports.
- Inspects geotagged photo evidence in an interactive full-screen lightbox, GPS coordinate accuracy, and reporter credibility.
- One-click verification (`PATCH /api/v1/reports/{id}/verify`) applies official confirmation, recalculates road risk, and triggers automated push alerts to approaching vehicles.

### 3.3 Dynamic Journey Planning & Route Evaluation (`JourneyPlanningModal.tsx`)
- Enables dispatchers to input origin and destination logistics hubs.
- Queries backend `/api/v1/routes/evaluate` to compare:
  - **Safest Viable Route:** Minimizes multi-factor hazard score ($R_{\text{composite}}$).
  - **Fastest Available Route:** Minimizes travel time without safety penalization.
- Displays elevation profile, predicted weather intensity, and disruption probability ($P_{\text{disrupt}}$).

### 3.4 System Settings & Governance (`SystemSettings.tsx`)
- Officials and administrators configure platform designation, jurisdiction, monsoon season dates, risk thresholds, and alert rules.
- All settings are persisted to the backend API (`GET/PUT /api/v1/settings`) and applied system-wide.

### 3.5 User Management (`UserManagement.tsx`)
- Administrators invite users to any role (including Official/Admin), toggle account status (active/suspended), and delete accounts.
- Synchronized with the backend via `fetchUsers()`, `inviteUser()`, `updateUser()`, and `deleteUser()`.

### 3.6 Role-Based Security & Governance (`RoleGuard.tsx`)
- Public registration does not allow creating `OFFICIAL` or `ADMIN` accounts.
- `RoleGuard` verifies active role claims and redirects unauthorized users away from governance screens.
- Web session uses `sessionStorage` (cleared on tab/browser close) with a 30-minute inactivity auto-logout.

---

## 4. Responsive Design

The console uses a 4-tier mobile-first breakpoint system:
- `sm` < 640px — stacked single-column layouts
- `md` 640–1023px — compact two-column layouts
- `lg` 1024–1439px — standard operational dashboard
- `xl` ≥ 1440px — widescreen command center

All tables are wrapped in `.table-responsive-wrapper` for horizontal scroll on narrow viewports. Minimum touch targets are 40px/44px for accessibility compliance.

---

## 5. Setup & Running

### Prerequisites
- Node.js 18+ and npm 9+
- Running TiyraSense backend (`http://localhost:8000`)

### Installation
```bash
cd web
npm install
```

### Development Server
```bash
npm run dev
```
The console will start at `http://localhost:5173`.

### Production Build
```bash
npm run build
```
Generates a type-checked, minified production build in `web/dist/`. Includes `_redirects` for Cloudflare Pages SPA routing.

### Running Tests
```bash
npm test
```
Executes all 26 Vitest unit and integration tests across login flows, interactive modals, and real-time tracking components.

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `VITE_API_URL` | Optional | Backend API base URL. Defaults to `https://tiyrasense-api.onrender.com/api/v1` when running on a non-localhost domain. |

### Cloud Deployment (Cloudflare Pages)
1. Connect the repository to Cloudflare Pages.
2. Set build command: `npm run build`, output directory: `dist`, root directory: `web`.
3. Set `VITE_API_URL` environment variable to your production backend URL.
4. The `public/_redirects` file handles SPA routing automatically.
