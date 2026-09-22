# TiyraSense Web Operations Console & Admin Portal

The web frontend of **TiyraSense** provides an interactive, real-time command dashboard for disaster management officials, regional transport authorities, and fleet dispatchers across the North Eastern Region (NER).

It features dynamic GIS map visualization, live corridor risk heatmaps, vehicle radar telemetry tracking, field incident verification workbenches with photo evidence review, emergency alert broadcasting, and system administration.

---

## 1. Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|:---:|---|
| **Core Framework** | React | 18.2+ | Component-driven declarative UI |
| **Language** | TypeScript | 5.4+ | Strict type safety and compilation verification |
| **Build & Dev Tooling** | Vite | 8.2+ | Lightning-fast HMR and optimized production bundling |
| **Routing** | React Router | 7.18+ | Client-side declarative routing and history management |
| **GIS Mapping** | Leaflet + OpenStreetMap | 1.9+ | Interactive spatial rendering, route overlays, hazard markers |
| **Styling & Design** | Vanilla CSS + CSS Variables | Modern CSS | Responsive layouts, high-contrast dark theme, and fluid status cards |
| **Iconography** | Lucide React | 0.363+ | Clean, accessible vector UI icons |
| **State & Auth** | React Context (`AuthContext`) | Native | Session token management, user roles, profile state |
| **Security / RBAC** | `RoleGuard` Route Component | Custom | Client-side authorization gate enforcing `OFFICIAL` & `ADMIN` access |
| **Testing** | Vitest + React Testing Library + jsdom | 5.0+ / 14.2+ | Component mounting, interaction, and integration test coverage |

---

## 2. Directory Structure

```text
web/
├── public/                           # Static assets, icons, web manifest
├── src/
│   ├── assets/                       # SVG logos and branded graphics
│   ├── components/                   # Reusable modular UI components
│   │   ├── AccountDetailsModal.tsx   # User profile and session inspection modal
│   │   ├── Button.tsx                # Accessible, styled button component
│   │   ├── Header.tsx                # Top navigation bar with active alerts & user badge
│   │   ├── Input.tsx                 # Standardized form input field with error states
│   │   ├── JourneyPlanningModal.tsx  # Dispatcher multi-candidate route evaluator modal
│   │   ├── Sidebar.tsx               # Collapsible navigation drawer with role-based links
│   │   ├── StatusBadge.tsx           # Semantic badges (OPEN, CAUTION, HIGH_RISK, BLOCKED)
│   │   └── VectorGisMap.tsx          # Leaflet GIS map with route polylines & hazard markers
│   ├── layouts/
│   │   └── AuthenticatedLayout.tsx   # Master layout with responsive sidebar and header
│   ├── pages/                        # Role-specific operational views
│   │   ├── Admin.tsx                 # Administrative console for system health & audit logs
│   │   ├── AlertFeed.tsx             # Real-time incident alert broadcast & acknowledgment feed
│   │   ├── CorridorMonitor.tsx       # Live status of NH-06, NH-27, and Damra bypass corridors
│   │   ├── Dashboard.tsx             # Master dispatch command center (map + metrics + feed)
│   │   ├── FieldReports.tsx          # Incident verification workbench with photo evidence modal
│   │   ├── Login.tsx                 # Official & Admin secure authentication portal
│   │   ├── SystemSettings.tsx        # Algorithm risk weights & weather polling parameters
│   │   └── UserManagement.tsx        # Role administration & personnel provisioning
│   ├── routes/
│   │   └── RoleGuard.tsx             # Client-side route protection by role hierarchy
│   ├── services/
│   │   └── api.ts                    # Typed API client with automatic JWT header attachment
│   ├── state/
│   │   └── AuthContext.tsx           # React Context providing user profile and login/logout
│   ├── test/                         # Vitest test specs (Login, Interactivity, Tracking)
│   ├── types/
│   │   └── auth.ts                   # TypeScript interfaces for users, roles, and tokens
│   ├── App.tsx                       # Root routing configuration
│   ├── index.css                     # Global typography, color tokens, and utility classes
│   └── main.tsx                      # Vite React application entrypoint
├── index.html                        # HTML shell
├── package.json                      # NPM package definitions and scripts
├── tsconfig.json                     # TypeScript compiler configuration
└── vite.config.ts                    # Vite build and test configuration
```

---

## 3. Key Features & Workflows

### 3.1 Interactive GIS Corridor Map (`VectorGisMap.tsx`)
- Renders the primary logistics arteries (e.g. NH-06 Guwahati–Shillong corridor and Damra–Mawkyrwat bypass).
- Color-codes road segments by real-time accessibility state:
  - 🟢 **OPEN**: Normal transit conditions.
  - 🟡 **CAUTION**: Deteriorating weather or minor surface runoff.
  - 🟠 **RESTRICTED / HIGH RISK**: Impending landslide threat or heavy waterlogging.
  - 🔴 **BLOCKED**: Confirmed physical obstruction or structural road cut.
- Overlays live GPS fleet radar pins with vehicle speed, heading, and driver contact info.

### 3.2 Field Incident Verification Workbench (`FieldReports.tsx`)
- Disasters officials review crowd-sourced and field-worker hazard reports.
- Inspects geotagged photo evidence, GPS coordinate accuracy, and reporter credibility.
- One-click verification (`PATCH /api/v1/reports/{id}/verify`) applies official confirmation, recalculates road risk, and triggers automated push alerts to approaching vehicles.

### 3.3 Dynamic Journey Planning & Route Evaluation (`JourneyPlanningModal.tsx`)
- Enables dispatchers to input origin and destination logistics hubs.
- Queries backend `/api/v1/routes/evaluate` to compare:
  - **Safest Viable Route**: Minimizes multi-factor hazard score ($R_{\text{composite}}$).
  - **Fastest Available Route**: Minimizes travel time without safety penalization.
- Displays elevation profile, predicted weather intensity, and disruption probability ($P_{\text{disrupt}}$).

### 3.4 Role-Based Security & Governance (`RoleGuard.tsx`)
- Public registration does not allow creating `OFFICIAL` or `ADMIN` accounts.
- `RoleGuard` verifies active role claims and redirects unauthorized users away from governance screens.
- Attaches the provenance header `X-TiyraSense-Data-Label` to outgoing requests.

---

## 4. Setup & Running

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
Generates a type-checked, minified production build in `web/dist/`.

### Running Tests
```bash
npm test
```
Executes all 26 Vitest unit and integration tests across login flows, interactive modals, and real-time tracking components.
