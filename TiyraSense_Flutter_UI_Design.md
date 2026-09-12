# TiyraSense Mobile — Flutter UI/UX Design System
### Google Stitch MCP Generation Document · SIH 2026 · Problem Statement 26002

> **Stitch Instructions:** This is a self-contained design brief. Ignore any previously generated screens. Generate every screen fresh using only the tokens and specifications defined here. No prior context applies.

---

## 0. Design Philosophy

| Rule | Detail |
|---|---|
| **Icon-first** | Use icons and color-coded status indicators. Text is for labels that icons cannot replace. |
| **Logo only — no wordmark** | "TiyraSense" text appears ONLY on Splash and Login. Every other screen uses the app icon only. |
| **Strictly light** | Pure white card surfaces on a cool slate canvas. No dark mode. No gradients on backgrounds. |
| **Spacious and clean** | Generous white space. Cards breathe. Hierarchy is visual, not textual. |
| **Action-forward** | Primary actions are always the most prominent element on each screen. |

---

## 1. Design Tokens

### Colors

```
CANVAS         #F8FAFC   App background — cool off-white (Slate 50)
SURFACE        #FFFFFF   Cards, bottom sheets, nav bar
CONTAINER      #F1F5F9   Inner containers, chips, strips (Slate 100)
BORDER-LIGHT   #E2E8F0   Card hairline borders (Slate 200)
BORDER-MED     #CBD5E1   Dividers, separators (Slate 300)

TEXT-HIGH      #0F172A   Headlines and primary content (Slate 900)
TEXT-MID       #475569   Descriptions, secondary labels (Slate 600)
TEXT-LOW       #64748B   Captions, timestamps, muted (Slate 500)

BLUE           #0284C7   Primary actions, active states, links (Sky 600)
BLUE-LIGHT     #E0F2FE   Blue tint — chips, highlights (Sky 100)
BLUE-DARK      #0369A1   Pressed blue, hover (Sky 700)

GREEN          #10B981   Passable / Online / Synced (Emerald 500)
AMBER          #F59E0B   Caution / Warning (Amber 500)
ORANGE         #F97316   Restricted access (Orange 500)
RED            #DC2626   High risk / Critical / Destructive (Red 600)
DARK-RED       #991B1B   Blocked / Emergency (Red 800)

GREEN-BG       #ECFDF5   Green tinted surface
AMBER-BG       #FFFBEB   Amber tinted surface
RED-BG         #FEF2F2   Red tinted surface
BLUE-BG        #F0F9FF   Blue tinted surface
```

### Typography

```
DISPLAY        Inter 800  28px   Splash app name only
H1             Inter 800  22px   Page headings
H2             Inter 800  18px   Card headings
H3             Inter 700  15px   Section headings inside cards
BODY-LARGE     Inter 600  14px   Key data values, metrics
BODY           Inter 400  13px   Descriptions, body text
BODY-SMALL     Inter 400  12px   Sub-labels, secondary info
LABEL          Inter 700  11px   ALL-CAPS section labels, 0.6px letter-spacing
MONO           Roboto Mono 600  11px   Coordinates, codes, timestamps
```

### Shape and Spacing

```
Card border-radius:        16px
Button border-radius:      12px
Chip border-radius:        20px (pill) / 8px (square chip)
Icon container radius:     12px
Bottom sheet top radius:   24px
Screen horizontal margin:  16px
Card internal padding:     16px
Vertical gap between cards: 12px
Base spacing unit:          4px
```

### Shadows

```
CARD-SHADOW:    0 2px 8px rgba(0,0,0,0.06)
ACTIVE-SHADOW:  0 4px 16px rgba(0,0,0,0.10)
NAV-SHADOW:     0 -1px 0 #E2E8F0, 0 -8px 24px rgba(0,0,0,0.06)
ICON-GLOW:      0 8px 32px rgba(2,132,199,0.18)
```

### Status Pill Badge System

Every status is shown as a pill badge: `[● STATUS]`

```
● PASSABLE    GREEN dot  · GREEN-BG tint  · GREEN border 25%
● CAUTION     AMBER dot  · AMBER-BG tint  · AMBER border 25%
● RESTRICTED  ORANGE dot · ORANGE-BG tint · ORANGE border 25%
● HIGH RISK   RED dot    · RED-BG tint    · RED border 25%
● BLOCKED     DARK-RED dot · RED-BG tint · DARK-RED border 25%
● ONLINE      GREEN dot  · GREEN-BG tint
● SYNCED      GREEN dot  · GREEN-BG tint
● PENDING     AMBER dot  · AMBER-BG tint
● OFFLINE     gray dot   · gray tint
```

Dot: 6px circle. Text: LABEL style (11px 700 uppercase). Padding: 6px horizontal, 3px vertical.

---

## 2. Screen Map

```
S0  SPLASH
 └─ S1  LOGIN ──────────── S2  SIGN UP
         │
    Role detected
    ┌────┴────┐
    │         │
  DRIVER    FIELD WORKER
    │         │
  S3 Home   S5 Home    ← Bottom nav tabs
  S4 Map    S6 Map
  S7 Alerts
  S8 Profile (shared)
  S9 Side Drawer (shared overlay)
  S10 Journey Planning Sheet (Driver modal)
  S11 Hazard Report Sheet (shared modal)
```

---

## 3. Screen Specifications

---

### S0 — SPLASH

**Purpose:** App launch, 2-second hold, then auto-navigate to Login (or Home if session exists).

**Background:** Solid `#F8FAFC`. No gradient. No texture. No pattern.

**Content:**
- Single centered element: app icon only
- Icon size: 96 × 96 px
- Corner radius: 22px
- Shadow below icon: `ICON-GLOW`
- Nothing else. No tagline. No app name. No spinner. No progress bar.

**Feel:** Breathing whitespace. Premium minimalism. The icon floats in silence.

---

**STITCH PROMPT — S0 SPLASH:**

```
Generate a Flutter mobile splash screen. Light theme only.

Background: flat solid #F8FAFC (cool off-white). No gradient. No pattern.

Content: A single square icon centered both vertically and horizontally on screen. Icon size: 96x96px. Corner radius: 22px. Drop a soft blue glow shadow below it: rgba(2,132,199,0.18) blur 32px offset 0 8px.

Nothing else on screen. No text. No app name. No tagline. No loading indicator. No logo wordmark. Pure empty whitespace surrounds the icon.

Style: extremely minimal, premium, clean. Feels like a luxury app.
```

---

### S1 — LOGIN

**Purpose:** User authentication. Only screen (besides Splash) that shows the app wordmark.

**Background:** `#F8FAFC`

**Layout:** Single scrollable column, 24px horizontal padding, vertically centered when keyboard is hidden.

**Sections top to bottom:**

**Brand Block (center-aligned):**
- App icon: 72 × 72px, corner radius 18px, `ICON-GLOW` shadow
- App name: "TiyraSense" — DISPLAY style (Inter 800, 28px), color `#0F172A`, center
- Tagline: "NER Logistics Intelligence" — BODY-SMALL style, color `#64748B`, center
- Vertical gap after: 28px

**Form Block:**
- Email field: outlined (10px radius), filled `#FFFFFF`, prefix icon `mail_outline` in `#64748B`
  - Label: "Email"
  - Placeholder: "you@domain.com"
- 14px gap
- Password field: outlined, filled `#FFFFFF`, prefix icon `lock_outline`, suffix show/hide eye toggle
  - Label: "Password"
- 22px gap
- Sign In button: full-width, height 52px, background `#0284C7`, corner radius 12px
  - Label: "Sign In" — Inter 700, 15px, white
  - Loading state: shows small white spinner inside button, button disabled

**Demo Roles Card:**
- 24px gap after button
- Card background: `#F1F5F9`, corner radius 14px, padding 14px, border 1px `#E2E8F0`
- Caption row: "DEMO ROLES" left (LABEL style, `#64748B`) + "Tap to fill" right (BODY-SMALL, `#64748B`)
- 12px gap
- Wrap row of 4 chips:
  - Chip style: background `#F8FAFC`, border 1px `#E2E8F0`, corner radius 10px, padding 8px 10px
  - Each chip: colored icon (16px) + label BODY-SMALL weight 600 in `TEXT-HIGH`
  - Chip 1: truck icon `#0284C7` + "Driver"
  - Chip 2: map-person icon `#F59E0B` + "Field Worker"
  - Chip 3: shield icon `#7C3AED` + "Official"
  - Chip 4: gear icon `#64748B` + "Admin"

**Footer:**
- 20px gap
- Center text: "New here?" in `#64748B` + " Register" in `#0284C7` (tappable, leads to S2)

---

**STITCH PROMPT — S1 LOGIN:**

```
Generate a Flutter mobile login screen. Light theme. Background #F8FAFC.
24px horizontal padding. Single scrollable column.

TOP SECTION — Brand block, center-aligned:
- Square app icon 72x72px, corner radius 18px, soft blue glow shadow (rgba(2,132,199,0.18))
- "TiyraSense" bold 28px #0F172A centered below icon
- "NER Logistics Intelligence" 12px #64748B centered
- 28px gap below

FORM SECTION:
- Outlined text field (10px radius, white fill): "Email", mail icon prefix, placeholder "you@domain.com"
- 14px gap
- Outlined text field: "Password", lock icon prefix, eye toggle suffix
- 22px gap
- Full-width button: 52px height, #0284C7 background, 12px radius, "Sign In" bold white 15px

DEMO ROLES CARD (below button, 24px gap):
- Card: #F1F5F9 bg, 14px radius, 1px #E2E8F0 border
- "DEMO ROLES" 11px uppercase gray left, "Tap to fill" 11px gray right
- 4 chips in a wrap: each chip has colored icon + label, white bg, gray border, 10px radius
  - Blue truck icon + "Driver"
  - Amber map-person icon + "Field Worker"
  - Purple shield icon + "Official"
  - Gray gear icon + "Admin"

FOOTER: "New here? Register" centered, "Register" in blue #0284C7

Overall: Airy, spacious, premium minimal. No decorations. No gradients. Clean white form.
```

---

### S2 — SIGN UP

**Purpose:** Self-registration for Driver or Field Worker roles only.

**Background:** `#F8FAFC`

**Layout:** Scrollable column, 24px horizontal padding.

**AppBar:**
- Leading: back arrow `#475569`, no elevation, background `#F8FAFC`
- No title text in AppBar

**Sections top to bottom:**

**Header Block (center-aligned):**
- App icon: 56 × 56px, corner radius 14px, `ICON-GLOW` shadow (smaller than login)
- Title: "Create Account" — H1 style, center, `#0F172A`
- Subtitle: "Driver and Field Worker registration" — BODY-SMALL, `#64748B`, center
- 16px gap

**Info Banner:**
- Background: `#E0F2FE`
- Border: 1px rgba(2,132,199,0.30)
- Corner radius: 12px
- Padding: 12px
- Row: `info_outline` icon `#0284C7` + text BODY-SMALL `#475569`: "Official and Admin accounts are provisioned by administrators only."

**Form (16px gap after banner):**
- Full Name field: person_outline icon prefix
- Email field: mail_outline icon prefix
- Password field: lock_outline icon prefix
  - Below field: 4-segment password strength bar, full width, height 4px
    - Segments: red → amber → green → green, fill left to right as password gets stronger
- Confirm Password field: lock_outline icon prefix
- 16px gap

**Role Selector:**
- Label: "Select Your Role" — LABEL style, `#64748B`, margin bottom 8px
- Full-width segmented control, height 48px, corner radius 10px
- Two equal segments: "Driver" (truck icon left) | "Field Worker" (map-person icon left)
- Active segment: `#0284C7` bg, white icon + white text
- Inactive segment: `#F1F5F9` bg, `#64748B` icon + `#475569` text
- No gap between segments

**CTA:**
- Full-width button: "Create Account", height 52px, `#0284C7`, 12px radius, Inter 700 white

**Footer:**
- "Already registered? Sign In" — "Sign In" in `#0284C7`

---

**STITCH PROMPT — S2 SIGN UP:**

```
Generate a Flutter mobile registration screen. Light theme. Background #F8FAFC.
24px horizontal padding. Scrollable column. Minimal back arrow appbar.

HEADER (center-aligned):
- App icon 56x56px, corner radius 14px, subtle blue glow shadow
- "Create Account" bold 22px #0F172A centered
- "Driver and Field Worker registration" 12px #64748B centered

INFO BANNER (16px below header):
- #E0F2FE background, 1px rgba(2,132,199,0.30) border, 12px radius, 12px padding
- Blue info icon + "Official and Admin accounts are provisioned by administrators only." 12px #475569

FORM (16px below banner, 14px gaps between fields):
- Outlined field: "Full Name", person icon prefix
- Outlined field: "Email", mail icon prefix
- Outlined field: "Password", lock icon prefix
  - 4-segment strength bar below (height 4px, full width): 4 rounded segments fill red>amber>green>green
- Outlined field: "Confirm Password", lock icon prefix

ROLE SELECTOR (16px below form):
- "SELECT YOUR ROLE" 11px uppercase #64748B label
- Full-width segmented control 48px: two equal halves
  - Left: truck icon + "Driver" — active state: #0284C7 bg + white text+icon
  - Right: map-person icon + "Field Worker" — inactive state: #F1F5F9 bg + gray
  - Corner radius 10px, no gap between segments

CTA (16px below selector):
- Full-width "Create Account" button, 52px, #0284C7, 12px radius, bold white

FOOTER: "Already registered? Sign In" — "Sign In" in blue #0284C7
```

---

### S3 — DRIVER HOME

**Navigation structure:** 5-tab bottom navigation bar

**Bottom Navigation Bar:**
```
Tab 1: Home      — house icon
Tab 2: Map       — map icon
Tab 3: Journey   — alt-route icon
Tab 4: Alerts    — bell icon
Tab 5: Profile   — person icon
```
- Bar background: `#FFFFFF`
- Bar shadow: `NAV-SHADOW`
- Bar height: 64px + safe area inset
- Selected tab: icon `#0284C7`, small 4px wide 2px tall rounded indicator line above the icon (like a top dot/pip), label `#0284C7` BODY-SMALL visible
- Unselected tab: icon `#64748B`, no label
- Icon size: 24px

**AppBar:**
- Background: `#FFFFFF`
- Elevation: 0
- Bottom border: 1px `#E2E8F0`
- Leading: app icon 36×36px, corner radius 9px — no text beside it
- Title zone: user name H3 style `#0F172A` + below it: 7px green filled circle + "On Duty" BODY-SMALL `#64748B` inline
- Trailing: bell icon `#64748B` with small red badge count if alerts exist
- NO app name text. NO "TiyraSense" text anywhere.

**Home Tab — Scrollable body (16px horizontal padding, 12px vertical gaps):**

**Strip 1 — GPS Status (40px tall pill):**
- Background: `#F1F5F9`, corner radius 10px, padding 12px horizontal
- Left: satellite icon `#10B981` + "GPS / NavIC Locked" LABEL style `#0F172A`
- Right: "Updated 2m ago" MONO style `#64748B`

**Card 2 — Corridor Intelligence Card:**
- Background: `#FFFFFF`, padding 16px, corner radius 16px, `CARD-SHADOW`
- Left border accent: 4px vertical strip, color matches accessibility status (GREEN=passable, AMBER=caution, RED=high risk)
- Top row:
  - Left: 44×44px square container (GREEN-BG `#ECFDF5`, corner radius 12px) with `check_circle` icon `#10B981` 26px
  - Center (flex): H3 corridor name `#0F172A` + BODY-SMALL road identifier `#64748B`
  - Right: status badge pill "● PASSABLE" in green
- Bottom row (inside card, 8px gap):
  - `#F1F5F9` inner container, padding 8px 10px, corner radius 8px
  - `info_outline` icon `#0284C7` 14px + advisory text BODY-SMALL `#64748B`

**Card 3 — Telemetry Row:**
- "OPERATIONAL TELEMETRY" LABEL style `#64748B` above
- 3 equal tiles in a row (horizontal row, 8px gap between):
  - Each tile: `#F1F5F9` bg, corner radius 10px, padding 10px
  - Row: icon 14px colored + caption LABEL 10px `#64748B`
  - Below: metric value BODY-LARGE weight 800 in metric color
  - Tile 1: speed icon `#0284C7` + "Traffic" + "Regulated" in BLUE
  - Tile 2: landslide icon `#10B981` + "Slip Risk" + "18% Low" in GREEN
  - Tile 3: shield icon `#10B981` + "Confidence" + "98%" in GREEN

**CTA 4 — Plan Safer Journey Button (64px tall):**
- Background: `#0284C7`, corner radius 14px, full width
- Left: 40px white circle with `alt_route` icon white 24px
- Center column: "Plan Safer Journey" H3 white + "AI checks risk, detours, timing" BODY-SMALL rgba(255,255,255,0.70)
- Right: `arrow_forward` icon white 22px

**Grid 5 — Quick Actions (2×2):**
- "QUICK ACTIONS" LABEL `#64748B` above grid
- 4 cards in 2 columns, gap 10px, aspect ratio 1.7:
  - Each card: `#FFFFFF` bg, `CARD-SHADOW`, 14px radius, padding 12px
  - Top-left: 30×30px icon container (accent color 12% alpha bg, 8px radius) with icon
  - Top-right: small badge chip (accent 10% alpha bg, 4px radius, 9px text, bold, accent color)
  - Bottom: title H3 style `#0F172A` + subtitle BODY-SMALL `#64748B`
  - Card A: `add_alert` icon AMBER + "Report Hazard" + "Mud, Rock, Slip" + "1-Tap" tag
  - Card B: `warning_amber` icon ORANGE + "Corridor Alerts" + "NH-29 & NH-06" + "2 Active" tag
  - Card C: `thunderstorm` icon BLUE + "Weather Radar" + "Doppler Feed" + "8mm/h" tag
  - Card D: `emergency` icon RED + "SOS" + "BRO / Police Post" + "Priority" tag

**Card 6 — Active Route Timeline:**
- Background: `#FFFFFF`, padding 16px, 16px radius, `CARD-SHADOW`
- Header row: "Active Route" H3 `#0F172A` + route label chip (BLUE-LIGHT bg, BLUE text, 6px radius) right
- Timeline — 4 waypoints:
  - Dot-connector vertical layout
  - Passed waypoints: `#10B981` dot (14px), `#10B981` connector line (2px wide)
  - Current waypoint: `#0284C7` dot, bold title
  - Future waypoints: `#CBD5E1` dot, `#E2E8F0` connector
  - Each waypoint: title BODY weight 600 + KM / ETA BODY-SMALL `#64748B`

---

**STITCH PROMPT — S3 DRIVER HOME:**

```
Generate a premium Flutter mobile Driver Home dashboard. Light theme only.
Background #F8FAFC. NO gradients. NO dark elements.

APPBAR:
- Pure white, no elevation, 1px #E2E8F0 bottom border
- Left: app icon 36x36px rounded square (9px radius)
- Center-left: user name bold 15px #0F172A, below it: small 7px green circle + "On Duty" 12px #64748B inline
- Right: bell icon #64748B with small red circular badge

BODY (scrollable, 16px horizontal padding, 12px gaps between blocks):

BLOCK 1 — GPS STRIP:
Full-width 40px pill container, #F1F5F9 bg, 10px radius.
Left: green satellite icon + "GPS / NavIC Locked" 11px bold uppercase.
Right: "Updated 2m ago" monospace 11px #64748B.

BLOCK 2 — CORRIDOR STATUS CARD:
White card, 16px padding, 16px radius, subtle shadow.
Left 4px green border accent strip.
Inside: 44px green-tinted square (12px radius) with green check-circle icon.
Right of icon: "NH-06 Guwahati to Shillong" bold 15px + route ID 12px below.
Far right: "● PASSABLE" green pill badge.
Below full-width: #F1F5F9 inner container with info icon + advisory note 12px gray.

BLOCK 3 — TELEMETRY 3-TILE ROW:
"OPERATIONAL TELEMETRY" 11px uppercase #64748B label above.
3 equal #F1F5F9 tiles in a row, 10px radius, 10px padding:
- Tile 1: speed icon blue + "Traffic" 10px label + "Regulated" 14px bold blue
- Tile 2: landslide icon green + "Slip Risk" 10px label + "18% Low" 14px bold green
- Tile 3: shield icon green + "Confidence" 10px label + "98%" 14px bold green

BLOCK 4 — JOURNEY CTA BUTTON:
Full-width, 64px height, #0284C7 blue, 14px radius.
Left: 40px white circle with white alt-route icon.
Center: "Plan Safer Journey" bold white 15px + "AI checks risk, detours, timing" white 60% 11px below.
Right: white arrow icon.

BLOCK 5 — QUICK ACTIONS 2x2 GRID:
"QUICK ACTIONS" 11px uppercase #64748B label.
4 white cards (14px radius, subtle shadow, 12px padding), 2 columns:
Card A: amber icon in amber-tinted circle + "Report Hazard" bold + "Mud, Rock, Slip" small + "1-Tap" amber tag top-right
Card B: orange icon in orange-tinted circle + "Corridor Alerts" bold + "NH-29 & NH-06" + "2 Active" orange tag
Card C: blue icon in blue-tinted circle + "Weather Radar" bold + "Doppler Feed" + "8mm/h" blue tag
Card D: red icon in red-tinted circle + "SOS" bold + "BRO / Police" + "Priority" red tag

BLOCK 6 — ROUTE TIMELINE CARD:
White card 16px padding 16px radius shadow.
"Active Route" bold 15px heading + route chip right (light blue bg, blue text).
4 waypoints with dot-connector line:
- 2 passed: green dots + green connector lines
- 1 current: blue dot, bold title
- 1 future: gray dot + gray connector
Each: name bold + KM/ETA 11px gray below.

BOTTOM NAVIGATION (5 tabs):
Pure white bar, top shadow.
Tabs: Home (house), Map (map), Journey (alt-route), Alerts (bell), Profile (person).
Active: #0284C7 icon + #0284C7 label + 4px wide 2px tall blue pip above icon.
Inactive: #64748B icon, no label.
```

---

### S4 — DRIVER MAP

**Navigation:** Map tab (Tab 2) of Driver bottom nav.

**AppBar:**
- White background, no elevation, 1px `#E2E8F0` bottom border
- Leading: app icon 36×36px, 9px radius
- Center: location breadcrumb chip — `#F1F5F9` bg, `my_location` icon `#0284C7`, "NH-06 Km 52.4" H3 weight 700 `#0F172A`, corner radius 20px
- Trailing: `layers` icon + `search` icon, both `#64748B`

**Body:** Map fills entire body height. Overlays float above.

**Map tiles:** Light cartographic style — muted colors, white roads on gray terrain, minimal labels.

**Overlays:**

Top-right floating column (12px gap, 16px from right edge, 16px from top):
- 44×44px white circle card `CARD-SHADOW`: compass rose icon `#475569`
- 44×44px white circle card `CARD-SHADOW`: `my_location` icon `#0284C7`

Left side floating strip (vertical, centered, 16px from left):
- `#FFFFFF` pill with `CARD-SHADOW`, padding 8px
- 3 rows: green dot + "Open" label, amber dot + "Caution" label, red dot + "Risk" label — all BODY-SMALL, 10px gap between

Map route layers:
- Safe route: 4px solid `#0284C7` line
- Risk route: 3px dashed `#F59E0B` line
- Incident markers: emoji-sized icons (landslide=🟤, flood=🔵, debris=🟠)
- Origin: 14px filled green circle
- Destination: blue map pin

**Bottom Peek Sheet (always visible, 180px tall, 24px top radius):**
- Background `#FFFFFF`, shadow `NAV-SHADOW` inverted
- Drag handle: 36×4px pill `#CBD5E1`, centered, 8px from top
- Route title: "Guwahati → Shillong" H2 style `#0F172A` (inline arrow character)
- Meta row: "ETA 6h 05m" BODY-LARGE BLUE + " · " + "98.4 km" BODY `#475569`
- Route chips row (12px gap):
  - "Recommended" chip: GREEN-BG `#ECFDF5`, green border 25%, `#10B981` text, 20px radius
  - "Faster" chip: AMBER-BG `#FFFBEB`, amber border 25%, `#F59E0B` text, 20px radius
- "Navigate" button: full-width, 48px, `#0284C7`, 12px radius, white "Navigate" bold

---

**STITCH PROMPT — S4 DRIVER MAP:**

```
Generate a Flutter mobile map view screen for a logistics driver. Light theme.

APPBAR:
White background, 1px #E2E8F0 bottom border.
Left: app icon 36px rounded square.
Center: location breadcrumb pill (#F1F5F9 bg, blue location icon, "NH-06 Km 52.4" bold, 20px radius).
Right: layers icon + search icon, gray.

BODY:
Full-height light cartographic map (OpenStreetMap style, muted pastel). Map fills entire body height.

ON-MAP OVERLAYS:
Top-right: Two stacked 44px white circular shadow cards — compass icon, then blue location icon.
Left center: White vertical pill with 3 rows: green dot "Open", amber dot "Caution", red dot "Risk".
Map routes: thick 4px solid blue line (safe route), 3px dashed amber line (risk route).
Map markers: green filled circle origin, blue pin destination, small colored incident icons.

BOTTOM PEEK CARD (always visible, 180px, 24px top radius):
White. Drag handle pill gray centered top.
"Guwahati → Shillong" bold 18px #0F172A.
"ETA 6h 05m" bold blue + "· 98.4 km" gray inline.
Two chips: "Recommended" (green tinted pill), "Faster" (amber tinted pill).
Full-width "Navigate" #0284C7 button 48px.

BOTTOM NAV: 5-tab bar. White. Active tab blue with pip. Same as driver home.
```

---

### S5 — FIELD WORKER HOME

**Navigation:** 4-tab bottom navigation bar

**Bottom Navigation Bar:**
```
Tab 1: Home      — house icon
Tab 2: Map       — map icon
Tab 3: History   — list icon
Tab 4: Profile   — person icon
```
Same visual spec as Driver bottom nav but 4 tabs.

**AppBar:**
- Same structure as Driver AppBar
- Status dot: `#F59E0B` AMBER (not green) — field workers have a different status color
- Caption: "Field Unit" instead of "On Duty"
- Trailing: sync pulse indicator — 10px circle that pulses (green=synced, amber=pending, gray=offline)

**Home Tab Body (16px horizontal padding, 14px gaps):**

**Card 1 — Connectivity Card:**
- White card, 16px padding, 16px radius, `CARD-SHADOW`
- Top row: `wifi_tethering` icon `#0284C7` 20px + "Connectivity & Sync" H3 `#0F172A` | Sync status badge right
- 12px gap
- Inner container: `#F1F5F9` bg, 10px radius, padding 12px
  - Left: `my_location` icon `#10B981` 16px + "Sector: NH-06 KM 42.8" BODY weight 700 `#0F172A`
  - Right: "+/- 2.1m · WGS-84" MONO `#64748B`

**Button 2 — Primary Hazard Report (full-width, 56px, 14px radius):**
- Background: `#DC2626`
- Layout: icon `add_alert` white 22px left | center column: "Report Road Hazard" H3 white + "GPS tagged · synced to ASDMA" BODY-SMALL white 60% | arrow right white
- This is the most prominent element on the screen

**Card 3 — Quick Dispatch Grid:**
- White card, 16px padding, 16px radius, `CARD-SHADOW`
- "QUICK DISPATCH" LABEL `#64748B` above grid
- 2×2 grid of tiles, 10px gap, aspect ratio 2.2:
  - Each tile: accent-bg (8% alpha), accent-border (25%), 12px radius, padding 10px
  - Row layout: icon 22px + label H3 in accent color
  - Tile A: `landscape` icon `#D97706` amber + "Landslide" amber
  - Tile B: `flood` icon `#0284C7` blue + "Flash Flood" blue
  - Tile C: `hide_image` icon `#DC2626` red + "Subsidence" red
  - Tile D: `park` icon `#059669` green + "Fallen Tree" green

**Card 4 — Recent Reports List:**
- White card, 16px padding, 16px radius, `CARD-SHADOW`
- Header: "Recent Reports" H3 `#0F172A` | "Synced" chip right (`#F1F5F9` bg, `#64748B` text BODY-SMALL)
- 12px gap
- List of report rows (separated by 1px `#E2E8F0` dividers):
  - Left: 8px status dot (GREEN=verified, AMBER=dispatched)
  - Center: report title BODY weight 700 + below: location + time BODY-SMALL `#64748B`
  - Right: status badge pill (GREEN "VERIFIED", AMBER "DISPATCHED", BLUE "CLEARED")

---

**STITCH PROMPT — S5 FIELD WORKER HOME:**

```
Generate a Flutter mobile Field Worker home screen. Light theme. Background #F8FAFC.
NO gradients. NO dark elements.

APPBAR:
Pure white, no elevation, 1px #E2E8F0 bottom border.
Left: app icon 36x36px rounded square (9px radius).
Center-left: user name bold 15px #0F172A, below: 7px amber circle + "Field Unit" 12px #64748B.
Right: 10px pulsing circle indicator (green when synced, amber when pending).
NO app name text anywhere.

BODY (scrollable, 16px horizontal padding, 14px gaps):

CARD 1 — CONNECTIVITY:
White card (16px radius, subtle shadow, 16px padding).
Top row: blue wifi icon (20px) + "Connectivity & Sync" bold 15px | green "● ONLINE" pill badge right.
Below: #F1F5F9 inner container (10px radius, 12px padding):
  Left: green location icon + "Sector: NH-06 KM 42.8" bold 13px.
  Right: "+/- 2.1m · WGS-84" monospace 11px gray.

BUTTON 2 — HAZARD REPORT (full-width, 56px, 14px radius):
Background #DC2626 red. 
Left: white alert icon 22px.
Center: "Report Road Hazard" bold white 15px + "GPS tagged · synced to ASDMA" white 60% 11px below.
Right: white arrow icon.
This is the most prominent element — make it visually dominant.

CARD 3 — QUICK DISPATCH:
White card (16px radius, shadow, 16px padding).
"QUICK DISPATCH" 11px uppercase #64748B label.
2x2 grid, 10px gap:
- Landslide: amber tinted bg + amber border + amber landscape icon (22px) + "Landslide" amber bold
- Flash Flood: blue tinted bg + blue border + blue flood icon + "Flash Flood" blue bold
- Subsidence: red tinted bg + red border + red icon + "Subsidence" red bold
- Fallen Tree: green tinted bg + green border + green park icon + "Fallen Tree" green bold
Each tile: 12px radius, aspect ratio ~2.2, horizontal icon+label layout.

CARD 4 — RECENT REPORTS:
White card (16px radius, shadow, 16px padding).
"Recent Reports" bold 15px | "Synced" gray chip right.
Two list rows with 1px gray dividers:
Row 1: green 8px dot + "Boulder Roll-Down on NH-06 Shoulder" bold + "KM 52.3 · Today 06:20" gray | "VERIFIED" green pill
Row 2: amber 8px dot + "Culvert Water Inundation" bold + "KM 38.1 · Yesterday" gray | "DISPATCHED" amber pill

BOTTOM NAV (4 tabs):
White bar, top shadow.
Tabs: Home (house), Map (map), History (list), Profile (person).
Active: #0284C7 icon + label + pip. Inactive: #64748B icon.
```

---

### S6 — FIELD WORKER MAP

**Differs from Driver Map in:** FAB button, coordinate pill, heat-map overlay, sector-focused bottom sheet.

**AppBar:** Same as S4 but with amber status dot variant.

**Map:** Light cartographic, same base. Replaces route lines with incident cluster heat blobs (amber and red semi-transparent blobs at incident coordinates).

**Floating elements:**
- Same compass + location buttons top-right
- Coordinate pill top-center (not breadcrumb): `#F1F5F9` bg, "26.0124° N, 91.8901° E" MONO `#0F172A`
- FAB bottom-right: 56×56px circle `#DC2626`, `add_alert` icon white 26px, shadow `ACTIVE-SHADOW`

**Incident markers (richer):**
- Own unsubmitted: dashed blue circle
- Dispatched: amber pulsing ring
- Verified by official: solid green icon
- Others' reports: standard colored icons

**Bottom Peek Sheet:**
- "My Sector" H2 `#0F172A`
- Last sync: "Last sync: 3m ago" MONO `#64748B`
- Two buttons side by side: "New Report" `#DC2626` filled 48px (flex 1) | "View Incidents" outlined `#0284C7` border 48px (flex 1)

---

**STITCH PROMPT — S6 FIELD WORKER MAP:**

```
Generate a Flutter mobile field worker map screen. Light theme. Same base structure as driver map but:

APPBAR: Same as driver map but amber status indicator variant.

MAP BODY:
Light cartographic map full height.
Instead of route lines: amber and red semi-transparent heat blobs at 3 locations on map (incident clusters).
Same compass + location floating buttons top-right.
Coordinate pill top-center: #F1F5F9 bg pill, "26.0124° N, 91.8901° E" monospace text.
Red floating FAB button bottom-right: 56px circle, #DC2626, white alert icon, strong shadow.

INCIDENT MARKERS:
- Dashed blue circles for own pending reports
- Amber pulsing rings for dispatched reports
- Solid green shield icons for verified incidents

BOTTOM PEEK CARD (24px top radius, white, always visible):
Drag handle gray pill top-center.
"My Sector" bold 18px.
"Last sync: 3m ago" monospace 11px gray.
Two equal buttons side by side:
  Left: "New Report" solid #DC2626 button 48px.
  Right: "View Incidents" outlined #0284C7 border button 48px.

BOTTOM NAV: 4-tab bar same as field worker home.
```

---

## 4. Shared Components

---

### SIDE DRAWER

**Width:** 280px
**Background:** `#FFFFFF`
**Shadow:** `0 0 24px rgba(0,0,0,0.12)` on right edge

**Header (120px height):**
- Background: linear gradient left-right `#0284C7` → `#0369A1`
- App icon: 40×40px white-tinted square, 10px radius, top-left 16px 16px inset
- User initials avatar: 48px circle, `#FFFFFF` bg, `#0284C7` text Inter 800, bottom-left 16px inset
- User name: Inter 700 15px white, 8px below avatar left
- Role pill: `rgba(255,255,255,0.20)` bg, white border 20% alpha, white BODY-SMALL text, inline after/below name

**Nav Items:**
- Each: 56px height, 16px horizontal padding, vertical centered
- Icon: 24px `#64748B` + 14px gap + label BODY `#0F172A`
- Active item: `#E0F2FE` bg, icon `#0284C7`, label `#0284C7` Inter 600
- Hover/press: `#F1F5F9` bg

**Driver items:**
1. `home` → "Dashboard" (active on home tab)
2. `alt_route` → "Route Planner"
3. `history` → "Journey History"
4. `notifications` → "Alerts"
5. `settings` → "Preferences"
6. `[divider 1px #E2E8F0]`
7. `logout` → "Sign Out" icon `#DC2626` label `#DC2626`

**Field Worker items:**
1. `home` → "Dashboard"
2. `add_alert` → "Submit Report"
3. `assignment` → "My Reports"
4. `cloud_sync` → "Sync Status"
5. `settings` → "Preferences"
6. `[divider 1px #E2E8F0]`
7. `logout` → "Sign Out" icon `#DC2626` label `#DC2626`

---

**STITCH PROMPT — SIDE DRAWER:**

```
Generate a Flutter side navigation drawer. Light theme. Width 280px. White background. Right-edge drop shadow.

HEADER (120px tall):
Linear gradient #0284C7 to #0369A1 (left to right).
Top-left 16px inset: app icon 40px white-tinted rounded.
Bottom-left 16px inset: 48px user avatar circle (white bg, blue bold initials).
Below avatar left: user name bold 15px white. Role pill (semi-transparent white bg, white border, white text small) inline.

NAV ITEMS (below header):
Each item 56px tall, 16px horizontal padding, icon left 24px + label 13px.
Active state: light blue #E0F2FE background, blue icon and label.

DRIVER DRAWER — 7 items:
1. house icon + "Dashboard" (active)
2. alt-route icon + "Route Planner"
3. history icon + "Journey History"
4. bell icon + "Alerts"
5. settings icon + "Preferences"
[1px #E2E8F0 divider]
6. logout icon RED #DC2626 + "Sign Out" RED

Clean, functional, minimal.
```

---

### JOURNEY PLANNING BOTTOM SHEET

**Trigger:** Journey CTA button on Driver Home
**Sheet height:** 75% of screen, `isScrollControlled: true`
**Background:** `#FFFFFF`, 24px top corner radius

**Content:**

Handle: 36×4px pill `#CBD5E1`, centered, 12px from top

Header row: "Plan Journey" H1 `#0F172A` + corridor chip right (`#E0F2FE` bg, `#0284C7` text, "Guwahati ↔ Shillong")

**Origin/Destination Selector (20px top padding):**
- Row 1: 14px green filled circle + "Guwahati Port Hub" BODY-LARGE `#0F172A` + `edit` icon `#64748B` right
- Vertical dotted connector: 2px dashed `#CBD5E1`, 20px tall, 7px from left edge
- Row 2: 14px blue filled circle + "Shillong Terminal Hub" BODY-LARGE `#0F172A` + `edit` icon right

**Route Option Cards (16px gap, stack vertically):**

Card A — Recommended:
- White card, 16px padding, 14px radius, 4px LEFT accent strip in `#10B981`
- Top right: "Recommended" badge chip GREEN-BG, GREEN text, 8px radius
- "ETA: 6h 05m" H2 `#0F172A` + "98.4 km" BODY `#64748B` inline
- Row: "14% Disruption" chip GREEN + "Risk: LOW" BODY-SMALL `#10B981`

Card B — Faster:
- White card, 4px LEFT accent strip in `#F59E0B`
- Top right: "Faster" badge chip AMBER-BG, AMBER text
- "ETA: 5h 20m" H2 `#0F172A`
- Row: "78% Disruption" chip RED + "Risk: HIGH" BODY-SMALL `#DC2626`

**Risk Legend (compact horizontal row):**
- "● Low" green dot + text | "● Moderate" amber | "● High" red — BODY-SMALL, 16px gaps

**Vehicle/Cargo Chips (2 chips, horizontal):**
- Chip 1: `local_shipping` icon + "Tata Prima 31T" — `#F1F5F9` bg, 20px radius
- Chip 2: `inventory` icon + "FMCG Critical" — `#F1F5F9` bg, 20px radius

**CTA:** "Confirm Safe Route" full-width 52px `#0284C7` 12px radius white Inter 700

---

**STITCH PROMPT — JOURNEY PLANNING SHEET:**

```
Generate a Flutter modal bottom sheet for journey planning. Light theme. White #FFFFFF bg. 24px top radius. 75% screen height.

TOP:
- Gray drag handle pill centered (36x4px).
- "Plan Journey" bold 22px #0F172A left + "Guwahati ↔ Shillong" blue tinted chip right.

ORIGIN/DESTINATION:
Two rows with vertical 2px dashed gray connector between them.
Row 1: 14px green filled circle + "Guwahati Port Hub" bold 14px + edit icon far right.
[dashed vertical line, 20px tall]
Row 2: 14px blue filled circle + "Shillong Terminal Hub" bold 14px + edit icon far right.

TWO ROUTE CARDS (stacked, 12px gap):
Card A: white bg, 4px solid green left accent border, 14px radius.
  Top-right: "Recommended" green chip.
  "ETA: 6h 05m" bold 18px + "98.4 km" gray inline.
  "14% Disruption" green chip + "Risk: LOW" green text.

Card B: white bg, 4px solid amber left accent border.
  Top-right: "Faster" amber chip.
  "ETA: 5h 20m" bold 18px.
  "78% Disruption" red chip + "Risk: HIGH" red text.

RISK LEGEND: ● Low green · ● Moderate amber · ● High red — horizontal 12px #64748B text.

VEHICLE CHIPS: truck icon + "Tata Prima 31T" pill gray · cargo icon + "FMCG Critical" pill gray.

CTA: "Confirm Safe Route" full-width 52px #0284C7 12px radius bold white.
```

---

### HAZARD REPORT BOTTOM SHEET

**Trigger:** Report button on Driver or Field Worker home
**Sheet:** `DraggableScrollableSheet`, background `#FFFFFF`, 24px top radius

**Handle:** 36×4px pill `#CBD5E1`

**Header:**
- "Report Hazard" H1 `#0F172A`
- "GPS-tagged field observation" BODY-SMALL `#64748B`

**GPS Row:**
- `#F1F5F9` container, 10px radius, padding 10px
- Left: `gps_fixed` icon `#10B981` 16px + coordinates MONO `#0F172A`
- Right: "GPS LOCKED" badge GREEN-BG, GREEN text

**Hazard Type — Horizontal scrollable chips:**
- Options: Landslide · Flash Flood · Subsidence · Fallen Tree · Debris · Bridge Issue · Other
- Selected chip: `#0284C7` bg, white text, 20px radius
- Unselected chip: `#F1F5F9` bg, `#0F172A` text, `#E2E8F0` border

**Severity Segmented Toggle (full-width, 3 segments):**
- Options: "Partial" | "Full Blockage" | "Shoulder"
- Active segment: `#0284C7` bg, white text
- Inactive: `#F1F5F9` bg, `#475569` text
- Height: 44px, corner radius 10px

**Photo Upload Area:**
- Dashed 2px `#CBD5E1` border, 10px radius, 120px height, full-width
- Center: `camera_alt` icon `#64748B` 28px + "Tap to add photo" BODY-SMALL `#64748B`

**Notes Field:** Multi-line `TextField`, outlined, min 3 lines, label "Observations (optional)"

**Submit CTA:** "Broadcast Incident Report" full-width 52px `#DC2626` 12px radius white Inter 700

---

**STITCH PROMPT — HAZARD REPORT SHEET:**

```
Generate a Flutter modal bottom sheet for field hazard reporting. Light theme. White bg. 24px top radius. Scrollable.

Gray drag handle pill top-center.
"Report Hazard" bold 22px #0F172A.
"GPS-tagged field observation" 12px #64748B.

GPS ROW:
#F1F5F9 container (10px radius, 10px padding full-width).
Left: green gps icon 16px + "NH-06 KM 42.8 · 26.0124° N, 91.8901° E" monospace #0F172A.
Right: "GPS LOCKED" green pill badge.

HAZARD TYPE (label "Hazard Type" 11px uppercase #64748B above):
Horizontal scrollable row of choice chips: Landslide, Flash Flood, Subsidence, Fallen Tree, Debris, Bridge Issue, Other.
Selected: #0284C7 blue filled, white text, 20px radius.
Unselected: #F1F5F9 bg, gray border, #0F172A text.

SEVERITY (label "Severity" above):
Full-width 3-segment toggle (44px height, 10px radius): Partial | Full Blockage | Shoulder.
Active: #0284C7 bg + white text. Inactive: #F1F5F9 bg + #475569 text.

PHOTO UPLOAD:
Full-width dashed-border box (120px height, 10px radius, 2px dashed #CBD5E1).
Camera icon 28px gray + "Tap to add photo" 12px gray centered inside.

NOTES: Multi-line outlined text field, "Observations (optional)" label, 3 min lines.

SUBMIT: "Broadcast Incident Report" full-width 52px #DC2626 red, 12px radius, bold white text.
```

---

### ALERTS SCREEN

**Navigation:** Alerts tab (Tab 4) of Driver bottom nav.

**AppBar:**
- White, no elevation, 1px `#E2E8F0` bottom border
- Leading: app icon 36×36px
- Title: "Alerts" H2 `#0F172A`
- Trailing: "Mark all read" BODY-SMALL `#0284C7` tappable text

**Filter Chips Row (horizontal scroll, 16px horizontal padding, 16px vertical padding):**
- 4 filter chips: ALL (badge "4") | CORRIDOR | WEATHER | EMERGENCY
- Active: `#0284C7` bg, white text, 20px radius
- Inactive: `#F1F5F9` bg, `#0F172A` text, `#E2E8F0` border
- Count badge on each active filter

**Alert Cards List (16px padding, 12px gaps):**

Card style: white `#FFFFFF`, 12px radius, `CARD-SHADOW`, 4px LEFT vertical accent strip

Card 1 — Emergency:
- Left strip: `#991B1B` dark red
- Card bg: `#FEF2F2` light red tint
- Top row: "EMERGENCY" badge DARK-RED | "NH-06 KM 52" BODY-SMALL `#64748B` | "5m ago" BODY-SMALL `#64748B`
- Title: "Landslide — Full Road Closure" H3 `#0F172A`
- Body: "Both lanes blocked. BRO crew dispatched. Use NH-37." BODY `#475569`
- Action chips: "View on Map" `#0284C7` tinted chip | "Dismiss" `#F1F5F9` chip

Card 2 — Caution:
- Left strip: `#F59E0B` amber
- Top row: "CAUTION" badge amber
- Title: "NH-29 — Heavy Rain Warning 48h"
- Body: "Expected 80mm+ in next 48h. Monitor slope condition."
- Action chips same pattern

Card 3 — Info:
- Left strip: `#0284C7` blue
- Top row: "INFO" badge blue
- Title: "Convoy Escort Lifted at Nongpoh"
- Body: "Both lanes now operational. Convoy restriction removed."

**Empty State (below cards or when no alerts):**
- `shield_outlined` icon 48px `#CBD5E1`, center
- "All Clear" H2 `#CBD5E1`, center
- "No active alerts on your corridors" BODY `#94A3B8`, center

---

**STITCH PROMPT — ALERTS SCREEN:**

```
Generate a Flutter alerts screen. Light theme. Background #F8FAFC.

APPBAR:
White, no elevation, 1px #E2E8F0 bottom border.
Left: app icon 36px rounded square.
Center: "Alerts" bold 18px #0F172A.
Right: "Mark all read" small blue text link.

FILTER ROW (horizontal scroll, 16px padding vertical):
4 filter chips: ALL (badge "4"), CORRIDOR, WEATHER, EMERGENCY.
Active chip: #0284C7 filled white text 20px radius.
Inactive: #F1F5F9 bg gray border gray text.

ALERT CARDS (16px horizontal padding, 12px gaps):

CARD 1 — Emergency:
#FEF2F2 light red tinted bg. 12px radius. Subtle shadow. 4px dark red #991B1B left accent strip.
Top row: "EMERGENCY" dark red badge pill | "NH-06 KM 52" gray caption | "5m ago" gray right.
"Landslide — Full Road Closure" bold 15px #0F172A.
"Both lanes blocked. BRO crew dispatched. Use NH-37." 13px #475569.
Bottom: "View on Map" blue tinted chip + "Dismiss" gray chip.

CARD 2 — Caution:
White bg. 4px amber left accent. "CAUTION" amber badge.
"NH-29 — Heavy Rain Warning 48h" bold.
"Expected 80mm+ in next 48h." 13px gray.
Action chips.

CARD 3 — Info:
White bg. 4px blue left accent. "INFO" blue badge.
"Convoy Escort Lifted at Nongpoh" bold.
"Both lanes now operational." 13px gray.

EMPTY STATE (below cards):
Centered: shield-outline icon 48px #CBD5E1, "All Clear" bold 22px #CBD5E1, "No active alerts on your corridors" 13px #94A3B8.

BOTTOM NAV: 5-tab bar. Alerts tab active.
```

---

### PROFILE SCREEN

**Navigation:** Profile tab (last tab) of both Driver and Field Worker bottom nav.

**AppBar:**
- White, no elevation, 1px `#E2E8F0` bottom border
- Leading: app icon 36×36px
- No title text in AppBar

**Profile Header (center-aligned, `#FFFFFF` card, padding 24px, 16px radius, `CARD-SHADOW`):**
- Avatar: 72px circle, `#0284C7` background, Inter 800 24px white initials, centered
- Name: H1 `#0F172A`, center
- Role badge pill: `#E0F2FE` bg, `#0284C7` text Inter 600 12px, 20px radius, center
- Organization: BODY-SMALL `#64748B`, center, 4px above

**Stats Row (3 tiles, `#F1F5F9` bg, 10px radius, 12px gap, inside a 16px padded card):**
- Each tile: padding 12px, centered
- Bold number: H1 style `#0F172A`
- Caption: LABEL `#64748B`
- Tile 1: "47" + "Journeys"
- Tile 2: "12" + "Reports"
- Tile 3: "98" + "Alert Score"

**Settings Sections (16px card padding, `#FFFFFF`, `#F8FAFC` section header bg):**

Section: "ACCOUNT" (LABEL style `#64748B`, `#F1F5F9` bg strip 36px tall, 8px horizontal padding)
- `person_outline` + "Edit Profile" → chevron right
- `lock_outline` + "Change Password" → chevron right

Section: "APP"
- `download` + "Offline Data" → chevron right
- `notifications_outlined` + "Notifications" → chevron right
- `translate` + "Language" → "English" BODY-SMALL `#0284C7` right

Section: "DATA"
- `delete_outline` + "Clear Cache" → chevron right
- `sync` + "Sync Now" → chevron right

**Sign Out (16px horizontal padding, 16px top margin):**
- Full-width outlined button: 48px height, `#DC2626` border 1.5px, `#DC2626` text Inter 600, 12px radius, `logout` icon left

**Version:**
- "TiyraSense v1.0 · SIH 2026" BODY-SMALL `#94A3B8`, center, 24px bottom padding

---

**STITCH PROMPT — PROFILE SCREEN:**

```
Generate a Flutter profile screen. Light theme. Background #F8FAFC.

APPBAR:
White, no elevation, 1px #E2E8F0 bottom border.
Left: app icon 36px rounded square only. No title text.

PROFILE HEADER CARD (white, 16px radius, shadow, 24px padding, center-aligned):
72px circle avatar: #0284C7 blue bg, white bold 24px initials "RD" centered.
User name bold 22px #0F172A centered below.
Role badge pill: #E0F2FE bg, #0284C7 text 12px bold, 20px radius, centered.
"Dimapur–Guwahati Transport Corp." 12px #64748B centered.

STATS ROW (inside card or separate, 3 equal tiles, #F1F5F9 bg, 10px radius):
Tile 1: "47" bold 22px #0F172A + "Journeys" 11px #64748B below.
Tile 2: "12" bold 22px + "Reports".
Tile 3: "98" bold 22px + "Alert Score".

SETTINGS SECTIONS (white card, 16px padding):
Section label "ACCOUNT" 11px uppercase #64748B on #F1F5F9 strip.
Rows: person icon + "Edit Profile" + chevron right | lock icon + "Change Password" + chevron right.
Section label "APP".
Rows: download icon + "Offline Data" | bell icon + "Notifications" | translate icon + "Language" + "English" blue text right.
Section label "DATA".
Rows: delete icon + "Clear Cache" | sync icon + "Sync Now".

SIGN OUT BUTTON (16px horizontal padding, 16px top margin):
Full-width outlined button: 48px height, #DC2626 red border 1.5px, #DC2626 red text bold, logout icon left, 12px radius.

VERSION: "TiyraSense v1.0 · SIH 2026" tiny 11px #94A3B8 centered bottom.

BOTTOM NAV: Profile tab active.
```

---

## 5. Motion Specifications

| Element | Motion | Duration | Easing |
|---|---|---|---|
| Screen push | Slide right-to-left + fade in | 300ms | easeOut |
| Screen pop | Slide left-to-right + fade out | 250ms | easeIn |
| Bottom sheet open | Slide up from bottom | 350ms | spring |
| Status badge | Opacity pulse 100%→70%→100% loop | 1.5s | ease |
| Sync dot | Scale pulse 1.0→1.3→1.0 loop | 2s | ease |
| CTA button press | Scale 0.97 | 80ms | linear |
| Alert card entry | Slide up 8px + fade in, staggered 50ms per card | 200ms | easeOut |
| Drawer open | Slide from left edge | 250ms | easeOut |
| Route select | Border accent color transition | 200ms | ease |

---

## 6. Accessibility

1. Minimum touch target: 44×44px for all interactive elements
2. Text contrast: all body text meets WCAG AA 4.5:1 minimum
3. Color is never the sole differentiator — always paired with icon or text label
4. Offline mode: every timestamp is shown relative ("3m ago", "Offline since 14:22") — never stale data without a freshness indicator
5. Loading: skeleton shimmer loaders, not spinning circles
6. Errors: inline banners, never blocking modals for form errors
7. Empty states: every list view has a designed empty state

---

## 7. Stitch Generation Order

Generate in this exact order — each screen inherits token confidence from the previous:

```
1. S1  Login          → establishes color, type, spacing
2. S0  Splash         → validates minimal icon treatment
3. S2  Sign Up        → builds on Login form language
4. S3  Driver Home    → establishes card system + bottom nav
5. S5  Field Worker Home → variant of Driver Home
6. S4  Driver Map     → unique map layout
7. S6  Field Worker Map → variant of Driver Map
8.     Journey Sheet  → derives from S3 CTA
9.     Hazard Sheet   → derives from S5 CTA
10.    Alerts Screen  → derives from bottom nav tab
11.    Profile Screen → derives from bottom nav tab
12.    Side Drawer    → overlay component
```

---

## 8. Pre-Generation Checklist

Before generating any screen, confirm:

- [ ] Background is `#F8FAFC` — not pure white
- [ ] Cards are `#FFFFFF` — contrasts against canvas
- [ ] App name "TiyraSense" appears ONLY in S0 and S1
- [ ] App icon used in AppBar leading on ALL other screens
- [ ] Bottom nav present on ALL post-login screens
- [ ] Zero dark elements, zero gradients on backgrounds
- [ ] All primary CTAs use `#0284C7` only
- [ ] Destructive actions use `#DC2626` only
- [ ] Section labels are 11px Inter 700 uppercase with 0.6px letter-spacing
- [ ] Card radius consistently 16px
- [ ] Button radius consistently 12px
- [ ] Status always shown as colored pill badge with matching dot

---

*TiyraSense · SIH 2026 · Problem Statement 26002*
*Google Stitch MCP: generate-screen-from-text · edit-screens · generate-variants*
