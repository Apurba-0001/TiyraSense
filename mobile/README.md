# TiyraSense Mobile Client

The mobile tier of **TiyraSense** is an offline-first Flutter application engineered specifically for commercial truck drivers, logistics operators, and field incident responders traversing connectivity-deprived mountain corridors across the North Eastern Region (NER).

It features encrypted local session storage, offline incident queuing, live GPS radar telemetry streaming, multi-candidate route comparisons (Safest Viable vs Fastest Available), in-transit hazard lookahead alerts, and geotagged field photo compression and upload.

---

## 1. Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|:---:|---|
| **Framework** | Flutter | 3.x | Cross-platform mobile development (Android, iOS) |
| **Language** | Dart | 3.x | Object-oriented typed client development |
| **Encrypted Storage** | `flutter_secure_storage` | 11.0+ | Hardware-backed encrypted session persistence (Android Keystore AES-GCM / iOS Keychain) |
| **Offline Data Cache** | `OfflineStorageService` | Custom / Local | Local persistence for pending field reports, route geometries, and user settings |
| **Location & GPS** | `geolocator` | 14.0+ | High-accuracy GPS polling, speed computation, and bearing calculations |
| **Camera & Media** | `image_picker` + `image` | 1.2+ / 4.9+ | Field incident photo capture, metadata extraction, and client-side downscaling |
| **Cloud Storage** | Cloudinary Direct Upload | REST API | Unsigned geotagged photo evidence upload with local offline retry queue |
| **Local Notifications**| `flutter_local_notifications` | 22.3+ | Critical audible and heads-up hazard warnings even when app is backgrounded |
| **HTTP Networking** | `http` | 1.6+ | REST communication with FastAPI backend attaching `X-TiyraSense-Data-Label` |
| **Code Quality** | `flutter_lints` | 6.0+ | Strict Dart linting and null-aware element enforcement |

---

## 2. Directory Structure

```text
mobile/
├── lib/
│   ├── models/                       # Client domain models
│   │   └── user_model.dart           # Authenticated user state, role, and credentials
│   ├── screens/                      # User interface screens
│   │   ├── admin_home_screen.dart    # Mobile system status inspection
│   │   ├── alerts_screen.dart        # Emergency notifications and active corridor warnings
│   │   ├── driver_home_screen.dart   # Driver dashboard: active trip, quick reporting, radar
│   │   ├── driver_map_screen.dart    # Fullscreen GIS navigation map with live hazard pins
│   │   ├── field_worker_home_screen.dart # Field responder view: pending reports, photo queue
│   │   ├── field_worker_map_screen.dart  # Spatial report submission and boundary checks
│   │   ├── login_screen.dart         # Secure credential entry and session restoration
│   │   ├── official_home_screen.dart # Quick report verification view for field officers
│   │   ├── profile_screen.dart       # User details, assigned vehicle, and offline storage stats
│   │   ├── report_history_screen.dart# Historical and pending field incident submissions
│   │   ├── signup_screen.dart        # Role-restricted registration (Driver & Field Worker only)
│   │   └── splash_screen.dart        # Cold-start session check and role-based route dispatch
│   ├── services/                     # Business logic and device services
│   │   ├── alert_service.py          # Active alert polling and local notification dispatch
│   │   ├── api_service.dart          # Central HTTP client with JWT header attachment
│   │   ├── image_compressor_service.dart # Compresses camera photos to <500KB before upload
│   │   ├── localization_service.dart # Indic language strings (Assamese, Bengali, Hindi, English)
│   │   ├── location_service.dart     # GPS coordinates, heading, and distance-to-hazard tracking
│   │   ├── notification_service.dart # Heads-up notification channels and emergency alarms
│   │   ├── offline_storage_service.dart # Persistent storage for offline report queue & sync
│   │   ├── report_service.dart       # Incident submission, photo upload, and offline queuing
│   │   └── vehicle_service.dart      # Vehicle profile, gross weight, and cargo type parameters
│   ├── state/
│   │   └── auth_provider.dart        # Riverpod/ChangeNotifier authentication state
│   ├── theme/
│   │   └── app_theme.dart            # High-visibility dark theme optimized for in-cab viewing
│   ├── utils/
│   │   └── distance_utils.dart       # Haversine distance and spatial containment math
│   ├── widgets/                      # Modular UI widgets
│   │   ├── app_logo.dart             # Branded vector logo
│   │   ├── hazard_report_sheet.dart  # Modal bottom sheet for rapid 1-tap incident reporting
│   │   ├── journey_planning_sheet.dart# Route evaluation modal (Safest Viable vs Fastest)
│   │   ├── live_notification_card.dart# Real-time incident banner with sound & vibration
│   │   ├── map_layer_sheet.dart      # Toggle weather overlays, hazard pins, and telemetry
│   │   ├── side_drawer.dart          # Navigation drawer with sync indicator and sign-out
│   │   ├── slippy_tile_layer.dart    # OpenStreetMap slippy map tile renderer
│   │   ├── status_pill_badge.dart    # Accessibility badges (OPEN, CAUTION, BLOCKED)
│   │   └── vehicle_profile_sheet.dart# Vehicle axle, clearance, and weight editor
│   └── main.dart                     # App initialization, secure storage bootstrap, root widget
├── test/                             # Flutter widget and unit tests (54 passing tests)
└── pubspec.yaml                      # Flutter dependencies and asset configuration
```

---

## 3. Key Architectural Features

### 3.1 Offline-First Launch & Resilient Storage (`auth_provider.dart`)
- On app launch, `AuthProvider` reads stored credentials from `flutter_secure_storage`.
- If credentials are valid, the user immediately transitions to their role-specific home console without ever seeing a login screen.
- **Network Dead-Zone Resilience**: Cold-starting in a valley with zero cellular reception will **never** log the driver out. Credentials are only cleared upon explicit user logout or an authoritative HTTP 401 response from the server.

### 3.2 Dual Operating Persona Shells
- **Driver Shell (`driver_home_screen.dart`)**:
  - Simplified high-contrast dashboard for night and rain operation.
  - One-tap journey activation with OSRM route comparison (Safest Viable vs Fastest Available).
  - Background GPS breadcrumb telemetry streamed to `/api/v1/journeys/{id}/telemetry`.
  - In-transit forward hazard radar alerting drivers to blockages up to 25km ahead.
- **Field Worker Shell (`field_worker_home_screen.dart`)**:
  - Ground-truth reporting interface with high-accuracy GPS capture.
  - Incident category selection (Landslide, Mudslide, Waterlogging, Road Collapse, Tree Fall).
  - Camera capture with automated client-side downscaling to ensure upload in 2G/EDGE networks.

### 3.3 Offline Incident Queueing & Auto-Sync (`report_service.dart`)
- When a driver or field worker submits an incident in an area without signal, the submission is stored locally in `OfflineStorageService` with status `PENDING`.
- As soon as network connectivity is re-established, the sync daemon automatically uploads the queued reports and photographs to Cloudinary and the FastAPI backend without requiring manual user action.

---

## 4. Setup & Running

### Prerequisites
- Flutter SDK 3.13+ / Dart 3.x
- Android Studio / Xcode / Windows build tools

### Installation
```bash
cd mobile
flutter pub get
```

### Static Analysis & Linter
```bash
flutter analyze
```
Verification passes with **0 errors, 0 warnings, and 0 hints**.

### Running Tests
```bash
flutter test
```
Executes all 54 comprehensive unit and widget tests covering session restoration, offline queuing, role navigation, and map layers.

### Running on Device / Emulator
```bash
# Start backend at localhost:8000
flutter run -d chrome      # Web preview
flutter run -d windows     # Windows desktop preview
flutter run -d <device_id> # Physical Android / iOS device
```
