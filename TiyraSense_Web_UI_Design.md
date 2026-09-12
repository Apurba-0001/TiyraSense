# TiyraSense Web — React + TypeScript UI/UX Design System
### Google Stitch MCP Generation Document · SIH 2026 · Problem Statement 26002

> **Stitch Instructions:** Fully self-contained design brief for the web dashboard. Ignore any previously generated screens or web designs. Generate every view fresh using only the tokens and specifications defined here. No prior context applies.

---

## 0. Design Philosophy

| Rule | Detail |
|---|---|
| **Dashboard-first** | Decision-support platform for Officials and Admins. Every pixel serves situational awareness. |
| **Data density with breathing room** | Compact enough to see everything. Spacious enough to read anything. Cards use padding, not cramped tables. |
| **Light command center** | Clean off-white canvas with white card surfaces — not dark. Feels like a premium civil operations tool. |
| **Color codes information, not decoration** | Color is reserved for status and severity. Chrome stays neutral. |
| **Logo only — no wordmark in UI chrome** | "TiyraSense" text appears ONLY on Login. Every authenticated view uses the icon mark only. |
| **Left sidebar navigation** | Fixed vertical sidebar. No horizontal top nav. Content fills the remaining viewport. |

---

## 1. Design Tokens

> These tokens mirror the Flutter mobile app exactly for visual consistency across platforms.

### Colors

```
CANVAS         #F8FAFC   App background (Slate 50)
SURFACE        #FFFFFF   Cards, sidebar, topbar, modals
CONTAINER      #F1F5F9   Inner fills, chip backgrounds, row stripes (Slate 100)
BORDER-LIGHT   #E2E8F0   Card hairline borders (Slate 200)
BORDER-MED     #CBD5E1   Dividers, separators (Slate 300)

TEXT-HIGH      #0F172A   Headings, primary content (Slate 900)
TEXT-MID       #475569   Descriptions, secondary labels (Slate 600)
TEXT-LOW       #64748B   Captions, timestamps, muted text (Slate 500)
TEXT-XLOW      #94A3B8   Disabled, placeholder (Slate 400)

BLUE           #0284C7   Primary actions, links, active state (Sky 600)
BLUE-LIGHT     #E0F2FE   Blue chip/highlight tint (Sky 100)
BLUE-DARK      #0369A1   Hovered/pressed blue (Sky 700)
BLUE-BG        #F0F9FF   Blue tinted surface (Sky 50)

GREEN          #10B981   Passable / Online / Verified (Emerald 500)
AMBER          #F59E0B   Caution / Warning / Pending (Amber 500)
ORANGE         #F97316   Restricted (Orange 500)
RED            #DC2626   High risk / Critical (Red 600)
DARK-RED       #991B1B   Blocked / Emergency (Red 800)

GREEN-BG       #ECFDF5   Green tinted surface
AMBER-BG       #FFFBEB   Amber tinted surface
ORANGE-BG      #FFF7ED   Orange tinted surface
RED-BG         #FEF2F2   Red tinted surface
```

### Typography

```
DISPLAY        Inter 800  32px / lh 1.2   Page-level titles (Login only)
H1             Inter 800  22px / lh 1.3   Page section titles
H2             Inter 700  17px / lh 1.4   Card headings, panel headings
H3             Inter 700  14px / lh 1.4   Sub-card headings, row titles
BODY-LARGE     Inter 600  14px / lh 1.5   Key metric values
BODY           Inter 400  13px / lh 1.6   Descriptions, table cells, body text
BODY-SMALL     Inter 400  12px / lh 1.5   Sub-labels, captions
LABEL          Inter 700  11px            ALL-CAPS section labels, 0.6px letter-spacing
MONO           Roboto Mono 500  12px      Coordinates, IDs, timestamps, codes
TAG            Inter 600  11px            Badge text, chip text
```

### Shape

```
Card radius:             12px
Button radius:           8px
Input radius:            8px
Pill chip radius:        20px
Square chip radius:      6px
Icon container radius:   8px
Modal radius:            16px
Sidebar width expanded:  240px
Sidebar width collapsed: 64px
Topbar height:           60px
```

### Spacing

```
4px   xs          Content horizontal padding inside card: 20px
8px   sm          Gap between cards in grid: 16px
12px  md          Gap between sections: 24px
16px  lg
20px  xl
24px  2xl
32px  3xl
```

### Shadows

```
CARD-SHADOW:     0 1px 4px rgba(15,23,42,0.06), 0 1px 2px rgba(15,23,42,0.04)
ACTIVE-SHADOW:   0 4px 16px rgba(15,23,42,0.10)
MODAL-SHADOW:    0 20px 60px rgba(15,23,42,0.18)
TOPBAR-SHADOW:   0 1px 0 #E2E8F0
DROPDOWN-SHADOW: 0 8px 24px rgba(15,23,42,0.12)
```

### Status Badge System

All statuses: `[● LABEL]` pill

```
● PASSABLE    #10B981 dot · GREEN-BG bg · #10B981 text
● CAUTION     #F59E0B dot · AMBER-BG bg · #D97706 text
● RESTRICTED  #F97316 dot · ORANGE-BG bg · #EA580C text
● HIGH RISK   #DC2626 dot · RED-BG bg · #DC2626 text
● BLOCKED     #991B1B dot · RED-BG bg · #991B1B text
● LIVE        #10B981 dot · GREEN-BG bg · pulsing animation
● PENDING     #F59E0B dot · AMBER-BG bg
● OFFLINE     #94A3B8 dot · #F8FAFC bg
● VERIFIED    #10B981 dot · GREEN-BG bg
● DISPATCHED  #0284C7 dot · BLUE-BG bg
● EMERGENCY   #991B1B dot · RED-BG bg
```

Dot: 6px circle. Padding: 5px 10px. Radius: 20px. Text: TAG style.

---

## 2. Application Architecture

### Roles and Views

| Role | Access | Landing |
|---|---|---|
| OFFICIAL | Dashboard, Corridors, Reports, Alerts | /dashboard |
| ADMIN | All Official views + User Management, Settings | /dashboard |

### Route Map

```
/login         W1 Login              (public)
/dashboard     W2 Dashboard          (Official + Admin)
/corridors     W3 Corridor Monitor   (Official + Admin)
/reports       W4 Field Reports      (Official + Admin)
/alerts        W5 Alert Feed         (Official + Admin)
/users         W6 User Management    (Admin only)
/settings      W7 Settings           (Admin only)
```

### Layout Shell (all authenticated views)

```
+--------------------------------------------------------------+
| TOPBAR (60px, full-width)                                    |
+---------------+----------------------------------------------+
|               |                                              |
|   SIDEBAR     |   MAIN CONTENT AREA                          |
|   (240px)     |   (flex-fill, scrollable, #F8FAFC bg)        |
|               |                                              |
|   Fixed left  |   24px horizontal padding                    |
|               |                                              |
+---------------+----------------------------------------------+
```

---

## 3. Shared Layout Components

---

### TOPBAR

Height: 60px · Background: #FFFFFF · Bottom border: 1px #E2E8F0

**Left zone (240px — aligned with sidebar):**
- App icon: 32x32px, 8px radius, white background — NO text

**Center zone:**
- "● LIVE FEED" green pulsing pill badge (#ECFDF5 bg, #10B981 text+dot, 20px radius)
- thin 1px #E2E8F0 vertical divider
- "Coverage: NER 8 Corridors" BODY 13px #475569
- thin divider
- "Updated 2m ago" MONO 12px #64748B

**Right zone:**
- Bell icon #64748B + small red circular badge count
- Avatar: 34px circle, #0284C7 bg, Inter 700 white initials
- Name: Inter 600 13px #0F172A
- Caret icon #94A3B8

---

**STITCH PROMPT — TOPBAR:**

```
Generate a web application topbar for a logistics intelligence platform. Light theme only.
Height 60px. Background #FFFFFF. 1px #E2E8F0 bottom border. Full viewport width. Flex row.

LEFT (240px width): App icon 32x32px rounded square (8px radius), white background. No text beside it.

CENTER: Horizontal inline status strip:
- "● LIVE FEED" small green pulsing pill badge (#ECFDF5 bg, #10B981 text+dot, 20px radius, 5px 10px padding)
- 1px vertical divider #E2E8F0
- "Coverage: NER 8 Corridors" 13px #475569
- 1px divider
- "Updated 2m ago" monospace 12px #64748B

RIGHT: Bell icon gray #64748B + small red circular badge "3". Thin vertical divider.
34px avatar circle: #0284C7 bg, white "RA" Inter 700.
"Rajeev Agarwal" 13px bold #0F172A. Caret icon gray.

Overall: Minimal, clean. No gradient. Only bottom border for separation.
```

---

### LEFT SIDEBAR

Width: 240px · Background: #FFFFFF · Right border: 1px #E2E8F0 · Full height fixed

**Nav items:**
- Height: 40px · Padding: 12px horizontal · Border radius: 8px
- Icon 20px + 8px gap + label 13px Inter 500
- Active: #F0F9FF bg, #0284C7 icon+label Inter 600, 3px left accent border #0284C7
- Hover: #F8FAFC bg
- Inactive: #64748B icon, #475569 label

**Navigation groups:**

```
GROUP "OPERATIONS" — 11px uppercase #94A3B8 label
  grid icon        Dashboard
  route icon       Corridors
  assignment icon  Field Reports
  bell icon        Alerts           [blue badge "3" right-aligned]

GROUP "ADMINISTRATION" — Admin role only
  people icon      User Management
  gear icon        Settings
```

**Bottom block:**
- 1px #E2E8F0 divider
- Sign Out row 40px: red logout icon + "Sign Out" #DC2626
- "TiyraSense v1.0" BODY-SMALL #94A3B8 centered 8px bottom

---

**STITCH PROMPT — SIDEBAR:**

```
Generate a web application left navigation sidebar. Light theme. Width 240px. White background.
Right 1px #E2E8F0 border. Full-height fixed.

NAV ITEMS: 40px height, 12px horizontal padding, 8px border radius.
Icon 20px left + 8px gap + label 13px Inter 500.
Active item: #F0F9FF bg, #0284C7 icon and label Inter 600, 3px #0284C7 left border accent.
Hover: #F8FAFC bg. Inactive: #64748B icon, #475569 label.

SECTION "OPERATIONS" — 11px uppercase #94A3B8:
1. Grid icon + "Dashboard" (active state)
2. Route icon + "Corridors"
3. Assignment/document icon + "Field Reports"
4. Bell icon + "Alerts" + small blue badge "3" right-aligned

SECTION "ADMINISTRATION" — 11px uppercase #94A3B8:
5. People icon + "User Management"
6. Gear icon + "Settings"

BOTTOM: 1px divider. Red logout icon + "Sign Out" 13px #DC2626. "TiyraSense v1.0" 11px #94A3B8 centered.

Clean, functional, minimal. No gradients. No shadows inside sidebar.
```

---

## 4. Screen Specifications

---

### W1 — LOGIN

**Layout:** Full viewport height. Two-column split screen.

**Left column (45% width, #F8FAFC bg, vertically centered, 48px horizontal padding):**
- App icon: 56x56px, 14px radius, white background, CARD-SHADOW
- "TiyraSense" — DISPLAY style (Inter 800 32px #0F172A), 12px below icon
- "AI-Powered Logistics Intelligence Platform" — BODY-SMALL #64748B
- 32px gap
- "NER Operations Dashboard" — H2 #0F172A
- "Authorized access for ASDMA Officials and System Administrators" — BODY #64748B
- 48px gap
- Feature list (3 rows, 16px gap each):
  - Green check-circle icon 16px + BODY 13px #475569 text
  - "Real-time corridor risk across 8 NER highway corridors"
  - "AI-assisted disruption probability and route analysis"
  - "Field report verification and incident response workflow"
- Bottom: "For Driver and Field Worker access, use the mobile app." BODY-SMALL #94A3B8

**Right column (55% width, #FFFFFF bg, vertically centered, 64px horizontal padding):**
- Left border: 1px #E2E8F0
- "Sign in to your account" — H1 #0F172A
- "Official and Admin credentials only" — BODY-SMALL #64748B, 24px gap after
- Email field: full-width outlined (44px height, 8px radius, 1px #E2E8F0 border, mail icon prefix)
  - Label above: "Email address" BODY-SMALL Inter 600 #0F172A
- 16px gap
- Password field: full-width outlined (lock icon prefix, eye toggle suffix)
  - Label: "Password" BODY-SMALL Inter 600 #0F172A
  - "Forgot password?" BODY-SMALL #0284C7 link, far right below field
- 24px gap
- "Sign In" button: full-width 44px height, #0284C7 bg, 8px radius, Inter 700 13px white
- 24px gap
- Demo Credentials Card (#F8FAFC bg, 1px #E2E8F0 border, 12px radius, 16px padding):
  - "DEMO CREDENTIALS" LABEL #64748B left + "Click to fill" BODY-SMALL #94A3B8 right
  - Two chips (16px gap): purple shield icon + "Official" | gray gear icon + "Admin"
  - "Driver and Field Worker roles are mobile-only" BODY-SMALL #94A3B8

---

**STITCH PROMPT — W1 LOGIN:**

```
Generate a web browser login page for a logistics intelligence platform. Light theme only.
Full viewport height. Two-column split layout.

LEFT COLUMN (45%, #F8FAFC bg, vertically centered, 48px horizontal padding):
- App icon 56x56px: white bg, 14px radius, subtle shadow.
- "TiyraSense" bold 32px #0F172A (12px below icon).
- "AI-Powered Logistics Intelligence Platform" 12px #64748B.
- 32px gap.
- "NER Operations Dashboard" bold 17px #0F172A.
- "Authorized access for ASDMA Officials and System Administrators" 13px #64748B.
- 48px gap.
- 3 feature rows (16px gap each):
  Green check-circle icon + "Real-time corridor risk across 8 NER highway corridors" 13px #475569.
  Green check-circle + "AI-assisted disruption probability and route analysis".
  Green check-circle + "Field report verification and incident response workflow".
- Bottom: "For Driver and Field Worker access, use the mobile app." 12px #94A3B8.

RIGHT COLUMN (55%, #FFFFFF bg, vertically centered, 64px horizontal padding, left 1px #E2E8F0 border):
- "Sign in to your account" bold 22px #0F172A.
- "Official and Admin credentials only" 12px #64748B. 24px gap.
- "Email address" label 12px bold + outlined input 44px height 8px radius mail icon prefix.
- 16px gap.
- "Password" label + outlined input lock icon prefix eye toggle. "Forgot password?" blue link far right below.
- 24px gap.
- "Sign In" full-width 44px #0284C7 8px radius bold white button.
- 24px gap.
- Demo card (#F8FAFC bg, 1px #E2E8F0 border, 12px radius, 16px padding):
  "DEMO CREDENTIALS" 11px uppercase gray left. "Click to fill" 12px gray right.
  Two chips (16px gap): purple shield icon + "Official". Gray gear icon + "Admin".
  "Driver and Field Worker roles are mobile-only" 12px #94A3B8.

Extremely clean, professional. No decorations. Balanced split. Breathable spacing.
```

---

### W2 — DASHBOARD (Operations Overview)

**Audience:** Official, Admin.

**Page header (24px top + horizontal padding, 20px bottom):**
- "Operations Overview" H1 #0F172A
- "NER Logistics Intelligence · 8 Corridors Monitored · DATA: LIVE" BODY-SMALL #64748B
- Right: "Export Report" outlined button 36px + "Refresh" icon button 36px

**Row 1 — KPI Strip (4 equal white cards, 16px gap, 12px radius, 20px padding):**

```
CARD A  green 36px icon container (route icon #10B981)
        "8 / 8" H1 Inter 800 #0F172A · "Corridors Active" LABEL #64748B
        footer: small green "▲ +0 since 06:00"

CARD B  blue 36px icon container (shield icon #0284C7)
        "14" H1 · "Field Teams Online" LABEL
        footer: small blue "▲ 3 synced in last 1h"

CARD C  amber 36px icon container (warning icon #F59E0B)
        "3" H1 #F59E0B · "Open Incidents" LABEL
        footer: small amber "▼ 1 resolved today"

CARD D  red 36px icon container (alert icon #DC2626)
        "1" H1 #DC2626 · "Emergency Alerts" LABEL
        footer: small red "NH-06 KM 52"
```

**Row 2 — Two columns (60% / 40%, 16px gap):**

*LEFT — Corridor Status Table (white card, 12px radius, 20px padding):*
- "Corridor Status" H2 + "All Corridors" outlined pill button right
- Table columns: Corridor | Status | Risk Score | Disruption Prob. | Last Report | Action
- Header: LABEL #94A3B8, 44px height, #F8FAFC bg, 1px bottom border
- Rows: 52px height, 1px #E2E8F0 divider, hover #F8FAFC
  - Corridor: map icon 16px + name Inter 600 14px + route ID BODY-SMALL below
  - Status: status badge pill
  - Risk Score: colored bold number + 4px progress bar 60px below
  - Disruption Prob: colored bold percentage + 48px sparkline
  - Last Report: MONO 12px relative time
  - Action: "View" link #0284C7 Inter 600
- Footer: count BODY-SMALL #94A3B8 left + pagination right

*RIGHT — Live Alert Feed (white card, 12px radius, 20px padding):*
- "Live Alerts" H2 + "● LIVE" green pulsing badge right
- Scrollable list max-height 420px, 8px item gap:
  - Each item: 12px radius, 12px padding, 4px colored left accent strip
  - Severity badge + corridor MONO + time MONO
  - Alert title Inter 600 13px #0F172A
  - Description BODY-SMALL #64748B, max 2 lines
  - "Acknowledge" blue link right
  - Emergency: #FEF2F2 bg, #991B1B accent strip
  - Caution: #FFFBEB bg, #F59E0B accent
  - Info: #F0F9FF bg, #0284C7 accent

**Row 3 — Three equal panels (16px gap):**

*Panel A — Disruption Probability Chart (white card):*
- "Disruption Probability — Next 48h" H2 + "ML forecast · HISTORICAL+LIVE" BODY-SMALL #94A3B8
- 200px height chart, 2 lines (blue=NH-06, amber=NH-29), MONO hour labels x-axis, % y-axis, #F1F5F9 grid lines
- Legend: 8px colored square + corridor label BODY-SMALL

*Panel B — Field Coverage (white card):*
- "Field Coverage by Sector" H2
- 5 rows (8px gap): sector label + count badge BLUE right + 6px full-width pill progress bar below
  - GREEN fill if >= 80% · AMBER if 40-79% · RED if < 40%

*Panel C — Activity Timeline (white card):*
- "Recent Activity" H2
- 5 entries newest-first: 8px colored dot + 2px #E2E8F0 connector + actor name Inter 600 13px + action BODY + time MONO 11px

---

**STITCH PROMPT — W2 DASHBOARD:**

```
Generate a web operations dashboard for a logistics intelligence platform. Light theme.
Background #F8FAFC. Content right of 240px sidebar, below 60px topbar. 24px padding.

PAGE HEADER:
"Operations Overview" bold 22px #0F172A.
"NER Logistics Intelligence · 8 Corridors Monitored · DATA: LIVE" 12px #64748B below.
Right: "Export Report" outlined 36px button + icon-only "Refresh" 36px button.

ROW 1 — 4 EQUAL KPI CARDS (16px gap, white #FFFFFF, 12px radius, 20px padding):
Card A: 36px green tinted icon container (route icon #10B981) + "8 / 8" bold 22px + "Corridors Active" 11px uppercase gray + "▲ +0 since 06:00" small green.
Card B: blue tinted (shield icon #0284C7) + "14" bold + "Field Teams Online" + "▲ 3 synced 1h" blue.
Card C: amber tinted (warning icon #F59E0B) + "3" bold amber + "Open Incidents" + "▼ 1 resolved" amber.
Card D: red tinted (alert icon #DC2626) + "1" bold red + "Emergency Alerts" + "NH-06 KM 52" red.

ROW 2 — TWO COLUMNS (60% + 40%, 16px gap):

LEFT — CORRIDOR TABLE (white, 12px radius, 20px padding):
"Corridor Status" bold 17px + "All Corridors" outlined pill button right.
Columns: Corridor | Status | Risk Score | Disruption Prob. | Last Report | Action
Header: 11px uppercase #94A3B8, 44px, #F8FAFC bg, bottom border.
8 data rows (52px, 1px dividers, hover #F8FAFC):
Row 1: route icon + "NH-06 Guwahati-Shillong" bold + ID below | PASSABLE green pill | "28" green bold + 4px green bar | "14%" green + sparkline | "6m ago" | "View" blue
Row 2: "NH-29 Guwahati-Silchar" | CAUTION amber | "61" amber | "52%" | "18m ago" | "View"
Row 3: "NH-37 Numaligarh" | HIGH RISK red | "84" red | "78%" | "2h ago" | "View"
Rows 4-8: alternating statuses.
Footer: count gray + pagination.

RIGHT — LIVE ALERT FEED (white, 12px radius, 20px padding, scrollable max 420px):
"Live Alerts" bold 17px + "● LIVE" small green pulsing badge.
5 alert items (12px padding, 8px gap, 12px radius, 4px left accent strip):
Item 1 Emergency: #FEF2F2 bg, dark-red strip, "EMERGENCY" badge + "NH-06" + "5m ago" + "Landslide — Full Blockage" bold + "Both lanes blocked." 12px + "Acknowledge" blue link.
Item 2 Caution: #FFFBEB bg, amber strip. Items 3-5: #F0F9FF bg, blue strip, INFO.

ROW 3 — THREE EQUAL PANELS (16px gap, white, 12px radius, 20px padding):
Panel A: "Disruption Probability — Next 48h" bold 17px + "ML forecast · HISTORICAL+LIVE" 12px gray. 200px line chart (blue NH-06, amber NH-29 lines), MONO axis labels, gray grid. Color legend below.
Panel B: "Field Coverage by Sector" bold 17px. 5 rows: label + badge count right + 6px bar (green/amber/red threshold fills). NH-06 88%, NH-29 65%, NH-37 22%, NH-40 75%, NH-51 91%.
Panel C: "Recent Activity" bold 17px. 5 timeline entries: colored 8px dot + 2px gray connector + actor bold 13px + action 13px gray + "Xm ago" mono 11px.

Professional, data-rich, clean. Premium command center without dark chrome.
```

---

### W3 — CORRIDOR MONITOR

**Page header:**
- "Corridor Monitor" H1 + "● LIVE" green pulsing badge
- Filter row: corridor selector dropdown + date-range picker + risk filter chips (ALL / HIGH RISK / CAUTION / PASSABLE) + "Apply" button 36px

**Split layout: Left 340px + Right flex, 16px gap**

*LEFT — Corridor List (white card, 12px radius):*
- 8 rows, 72px height, 1px #E2E8F0 dividers, hover #F8FAFC
- Each: 8px colored status dot + corridor name Inter 600 14px + route ID BODY-SMALL below | status pill + risk score colored circle (white number inside)
- Selected: #F0F9FF bg + 3px #0284C7 left border

*RIGHT — Detail Panel (stacked cards, 16px gap):*

CARD 1 — Header (white, 20px padding, 12px radius):
- Corridor name H1 + status badge + "Updated 6m ago" MONO #64748B right
- 3 stat tiles (#F8FAFC bg, 12px radius, 12px padding, 12px gap):
  - Risk Score: large colored number + trend arrow
  - Disruption Prob: large colored percentage + sparkline
  - Field Reports: count + "verified today" BODY-SMALL

CARD 2 — Map Placeholder (white, 12px radius, 320px height):
- #F1F5F9 bg, dashed 2px #CBD5E1 inner border
- Centered: map icon 36px #CBD5E1 + "Map Integration — Provider TBD" H3 #94A3B8 + "Spatial routing renders here" BODY-SMALL #94A3B8

CARD 3 — Risk Factor Breakdown (white, 20px padding, 12px radius):
- "Risk Factor Breakdown" H2
- 4 rows (16px gap): factor name Inter 600 14px + severity label right + 8px progress bar + BODY-SMALL detail below
  - "Precipitation Index" 62% AMBER
  - "Slope Stability" 31% GREEN
  - "Traffic Density" 45% AMBER
  - "Infrastructure Condition" 18% GREEN

CARD 4 — Incident Timeline (white, 20px padding, 12px radius):
- "Incident Timeline — Last 30 Days" H2
- 10 chronological rows: MONO date 80px col + 6px colored dot + incident title BODY + status badge right + worker name BODY-SMALL below

---

**STITCH PROMPT — W3 CORRIDOR MONITOR:**

```
Generate a web corridor monitoring view. Light theme. Background #F8FAFC. Topbar+sidebar shell. 24px padding.

PAGE HEADER:
"Corridor Monitor" bold 22px + "● LIVE" green pulsing badge inline.
Filter row: corridor dropdown (150px, 8px radius) + date range picker + filter chips (ALL active blue / HIGH RISK red / CAUTION amber / PASSABLE green) + "Apply" blue button 36px.

SPLIT LAYOUT: 340px left + flex right, 16px gap.

LEFT PANEL (white card, 12px radius):
8 corridor rows (72px, 1px dividers, hover #F8FAFC):
Each: 8px colored dot + corridor name bold 14px + route ID 12px gray below | status pill badge + small colored circle with white risk score number right.
Selected row: #F0F9FF bg + 3px blue left border accent.

RIGHT PANEL (stacked cards, 16px gap):

CARD 1 (white, 20px padding, 12px radius):
"NH-06 Guwahati-Shillong" bold 22px + "● PASSABLE" green badge + "Updated 6m ago" mono gray right.
3 stat tiles row (#F8FAFC bg, 12px radius, 12px padding, 12px gap):
"Risk Score: 28" green bold large + "▼ improving" small arrow.
"Disruption: 14%" green large + tiny sparkline.
"Field Reports: 6 verified today" blue.

CARD 2 Map (white, 12px radius, 320px height, #F1F5F9 bg, dashed 2px #CBD5E1 inner border):
Centered: map icon 36px gray + "Map Integration — Provider TBD" bold 17px gray + "Spatial routing renders here" 13px gray.

CARD 3 Risk Breakdown (white, 20px padding, 12px radius):
"Risk Factor Breakdown" bold 17px.
4 rows (16px gap): factor name bold 14px + severity label right + 8px progress bar + 12px gray detail.
Precipitation Index 62% amber. Slope Stability 31% green. Traffic Density 45% amber. Infrastructure 18% green.

CARD 4 Timeline (white, 20px padding, 12px radius):
"Incident Timeline — Last 30 Days" bold 17px.
10 rows: date mono (80px col) + 6px colored dot + incident title 13px + status badge right + worker name 12px gray below.
```

---

### W4 — FIELD REPORTS

**Page header:** "Field Reports" H1 + "14 new today" blue badge + Export button

**Filter bar:** Status chips (ALL / PENDING / VERIFIED / DISPATCHED / REJECTED) + search input (200px) + date picker + corridor selector

**Reports Table (white card, 12px radius, 20px padding):**
Columns: Report ID | Submitted | Corridor/KM | Hazard Type | Severity | Status | Field Worker | Action
- Header: LABEL #94A3B8, 44px, #F8FAFC bg
- Rows: 64px, 1px #E2E8F0 divider, hover #F8FAFC
  - Report ID: MONO 12px #64748B
  - Submitted: MONO relative + absolute date below
  - Corridor/KM: Inter 600 13px
  - Hazard Type: colored square chip + label (landslide=amber, flood=blue, debris=orange)
  - Severity: "FULL BLOCKAGE" red bold / "PARTIAL" amber / "SHOULDER" green
  - Status: pill badge
  - Field Worker: 28px avatar initials (#F1F5F9 bg, #475569 text) + name BODY 13px
  - Action: "Review" #0284C7 link + "Reject" #DC2626 link

**Report Detail Side Panel (480px, slides from right, #FFFFFF, left 1px #E2E8F0, MODAL-SHADOW):**
- "Report Detail" H2 + close X
- Report ID MONO + GPS coordinates MONO + "GPS LOCKED" green badge
- 2-column photo grid: 120px height, #F1F5F9 placeholder, camera icon centered
- Hazard description BODY #475569
- Field worker: 32px avatar + name + timestamp BODY-SMALL
- Pinned bottom actions (16px padding):
  - "Verify & Dispatch" full-width 44px #10B981 green button
  - "Reject Report" full-width 36px outlined #DC2626 button

---

**STITCH PROMPT — W4 FIELD REPORTS:**

```
Generate a field reports management view. Light theme. Background #F8FAFC. Topbar+sidebar shell.

PAGE HEADER: "Field Reports" bold 22px + "14 new today" blue badge + Export button far right.

FILTER BAR: Status chips (ALL blue active, PENDING amber, VERIFIED green, DISPATCHED blue, REJECTED gray) + search input 200px (search icon prefix) + date picker + corridor selector.

REPORTS TABLE (white card, 12px radius, 20px padding):
Columns: Report ID | Submitted | Corridor/KM | Hazard Type | Severity | Status | Field Worker | Action
Header: 11px uppercase #94A3B8, 44px, #F8FAFC bg, bottom border.
8 rows (64px, 1px dividers, hover #F8FAFC):
Row 1: "RP-2847" mono | "6m ago" | "NH-06 / KM 52.3" bold | amber chip "Landslide" | "FULL BLOCKAGE" red bold | PENDING amber pill | 28px avatar "SK" + "Sanjay Kumar" | "Review" blue / "Reject" red.
Row 2: "RP-2846" | "18m ago" | "NH-29 / KM 81.1" | blue chip "Flash Flood" | "PARTIAL" amber | VERIFIED green | avatar "PM" + "Priya Mao" | links.
Rows 3-8: varied hazard types and statuses.

SIDE PANEL (480px from right, white, left 1px #E2E8F0 border, shadow):
"Report Detail" bold 17px + X close icon.
"RP-2847" mono gray below.
"NH-06 KM 52.3 — 26.0124 N, 91.8901 E" mono black + "GPS LOCKED" green badge.
2-column image grid: 2 placeholders 120px height, #F1F5F9 bg, camera icon centered.
"Large boulder roll-down on left shoulder. One lane blocked." 13px gray.
32px avatar + "Sanjay Kumar · Field Unit 4 · Today 06:20" 12px gray.
PINNED BOTTOM:
"Verify & Dispatch" full-width 44px #10B981 green solid button.
"Reject Report" full-width 36px outlined #DC2626 red button.
```

---

### W5 — ALERT FEED

**Page header:** "Alert Feed" H1 + "3 unacknowledged" RED badge + "Acknowledge All" outlined button

**Stats strip (4 white cards, 12px radius, 12px padding, 16px gap):**
- "1" RED H2 + "Emergency" LABEL #64748B
- "3" ORANGE H2 + "High Risk" LABEL
- "5" AMBER H2 + "Caution" LABEL
- "8" BLUE H2 + "Informational" LABEL

**Two columns (equal width, 16px gap):**

*LEFT — Active / Unacknowledged (cards, 16px gap):*
- Each card: 12px radius, 16px padding, 4px left accent strip
- Emergency: #FEF2F2 bg, #991B1B strip, "EMERGENCY" badge
- High Risk: #FFF7ED bg, #F97316 strip, "HIGH RISK" badge
- Caution: #FFFBEB bg, #F59E0B strip, "CAUTION" badge
- Info: #F0F9FF bg, #0284C7 strip, "INFO" badge
- Each card body: title H3 + description BODY-SMALL + "Affects: [corridor] [KM range]" + "View Details" blue + "Acknowledge" outlined gray button

*RIGHT — Acknowledged / Resolved (cards, 16px gap):*
- Each: #F8FAFC bg, 1px #E2E8F0 border, 12px radius
- Muted gray badge + gray title + gray description
- "Resolved by: [name] · [time]" MONO footer

---

**STITCH PROMPT — W5 ALERT FEED:**

```
Generate an alert management view. Light theme. Background #F8FAFC. Topbar+sidebar shell.

PAGE HEADER:
"Alert Feed" bold 22px + "3 unacknowledged" red badge + "Acknowledge All" outlined button right.

STATS STRIP (4 equal white cards, 12px radius, 12px padding, 16px gap):
"1" bold 22px red + "Emergency" 11px uppercase gray.
"3" bold 22px orange + "High Risk" gray.
"5" bold 22px amber + "Caution" gray.
"8" bold 22px blue + "Informational" gray.

TWO EQUAL COLUMNS (16px gap):

LEFT — ACTIVE ALERTS (cards, 16px gap each):
Card 1 Emergency: #FEF2F2 bg, 4px dark-red #991B1B left strip, 12px radius, 16px padding.
"EMERGENCY" dark-red pill badge + "5m ago" mono + "NH-06" mono.
"Landslide — Full Road Blockage at KM 52" bold 14px #0F172A.
"Boulder confirmed. BRO Crew 4 dispatched. NH-06 fully blocked." 12px #475569.
"Affects: NH-06 KM 48-55" LABEL + pill.
"View Details" blue link + "Acknowledge" outlined gray button.
Card 2: #FFF7ED bg, orange strip, HIGH RISK, flood warning.
Card 3: #FFFBEB bg, amber strip, CAUTION, rain warning.
Card 4: #F0F9FF bg, blue strip, INFO, route clearance.

RIGHT — ACKNOWLEDGED:
4 muted cards (#F8FAFC bg, 1px #E2E8F0 border, 12px radius):
Gray badge + gray title + gray description + "Resolved by: Official R. Agarwal · 14:22" mono 11px footer.
```

---

### W6 — USER MANAGEMENT (Admin only)

**Page header:** "User Management" H1 + "Invite User" primary blue button right

**Summary tiles (3 white cards, 12px radius, 16px padding, 16px gap):**
- "47" H1 #0F172A + "Active Users" LABEL + "31 Drivers · 11 Field Workers · 3 Officials · 2 Admins" BODY-SMALL
- "2" H1 AMBER + "Pending Approval"
- "1" H1 RED + "Suspended"

**Users Table (white card, 12px radius, 20px padding):**
Filter: role chips (ALL / DRIVER / FIELD WORKER / OFFICIAL / ADMIN) + search input + status dropdown
Columns: User | Role | Status | Last Active | Registered | Action
- Header: LABEL #94A3B8, 44px, #F8FAFC bg
- Rows: 56px, 1px divider, hover #F8FAFC
- User: 32px avatar initials (#F1F5F9 bg) + name Inter 600 + email BODY-SMALL below
- Role chip: Driver=#F0F9FF+#0284C7 | Field Worker=#FFFBEB+#D97706 | Official=#F5F3FF+#7C3AED | Admin=#F1F5F9+#475569
- Status pill: ACTIVE green / PENDING amber / SUSPENDED red
- Last Active: MONO relative
- Registered: MONO date
- Action: "Edit" #0284C7 + "Suspend" #DC2626 links

**Invite User Modal (centered, 480px, 16px radius, #FFFFFF, MODAL-SHADOW, 40% backdrop):**
- "Invite New User" H2 + X
- Full Name, Email Address, Role segmented (Driver / Field Worker / Official / Admin), Organization
- "Send Invitation" full-width 44px #0284C7 button

---

**STITCH PROMPT — W6 USER MANAGEMENT:**

```
Generate a user management admin view. Light theme. Background #F8FAFC. Topbar+sidebar shell.

PAGE HEADER: "User Management" bold 22px + "Invite User" blue solid button 44px 8px radius right.

SUMMARY TILES (3 white cards, 12px radius, 16px padding, 16px gap):
"47" bold 22px #0F172A + "Active Users" 11px uppercase + "31 Drivers · 11 Field Workers · 3 Officials · 2 Admins" 12px gray.
"2" bold amber + "Pending Approval".
"1" bold red + "Suspended".

USERS TABLE (white card, 12px radius, 20px padding):
Role filter chips (ALL active blue, DRIVER, FIELD WORKER, OFFICIAL, ADMIN) + search 200px + status dropdown.
Columns: User | Role | Status | Last Active | Registered | Action — 11px uppercase gray header, #F8FAFC bg.
8 rows (56px, 1px dividers, hover #F8FAFC):
Row 1: 32px avatar "RD" + "Ratan Das" bold + "ratan.das@example.in" 12px gray | "Driver" blue chip | ACTIVE green pill | "2h ago" | "Jan 12, 2026" | "Edit" blue / "Suspend" red.
Row 2: "PM" + "Priya Mao" | "Field Worker" amber chip | ACTIVE | "18m ago" | links.
Row 3: "RA" + "Rajeev Agarwal" | "Official" purple chip | ACTIVE | "Just now" | links.
Rows 4-8: varied.

INVITE MODAL (centered overlay, white 480px, 16px radius, shadow, dark 40% backdrop):
"Invite New User" bold 17px + X close icon.
Outlined inputs: "Full Name", "Email Address".
"Role" segmented control: Driver / Field Worker / Official / Admin.
"Organization" outlined input.
"Send Invitation" full-width 44px #0284C7 solid button.
```

---

### W7 — SETTINGS (Admin only)

**Layout:** Inner two columns (240px settings nav + flex right)

**Left settings nav (white card, 12px radius, items 40px each, icon 18px + label 13px):**
Active: #F0F9FF bg + blue text. Hover: #F8FAFC.
Options: General (active) · Data Sources · Risk Thresholds · Alert Rules · Access Logs · About

**Right — 3 section cards (16px gap):**

CARD "Platform Identity" (white, 12px radius, 20px padding):
- App icon 40px rounded + "TiyraSense" Inter 700 17px + "v1.0 · SIH 2026" BODY-SMALL #94A3B8
- "Platform Name: TiyraSense NER ILP" + "Edit" #0284C7 link right
- "Operating Region: NER — Assam, Meghalaya, Nagaland, Manipur, Tripura, Mizoram, Arunachal Pradesh, Sikkim" + "Edit" right

CARD "Data Source Status" (white, 12px radius, 20px padding):
- "Data Source Status" H2
- 4 rows (40px each, 1px #E2E8F0 dividers):
  - icon + source name Inter 600 | status badge right | last ping MONO far right
  - "PostGIS Database" · CONNECTED green badge · "0ms"
  - "IMD Weather Feed" · LIVE green pulsing · "2m 14s"
  - "ASDMA Field API" · CONNECTED green · "8s"
  - "OSRM Routing Engine" · "PROVIDER TBD" gray badge

CARD "Risk Score Thresholds" (white, 12px radius, 20px padding):
- "Risk Score Thresholds" H2 + "Changes require Admin approval" BODY-SMALL #64748B
- 3 rows (20px gap): factor label Inter 600 + value badge right + 8px colored slider track below
  - "LOW / CAUTION boundary" + "30" blue badge + green fill 0-30%
  - "CAUTION / HIGH boundary" + "70" amber badge + amber fill 0-70%
  - "Emergency trigger threshold" + "85" red badge + red fill 0-85%

---

**STITCH PROMPT — W7 SETTINGS:**

```
Generate a platform settings view. Light theme. Background #F8FAFC. Topbar+sidebar shell.

INNER TWO-COLUMN LAYOUT (240px left + flex right, 16px gap):

LEFT SETTINGS NAV (white card, 12px radius):
Items 40px each (icon 18px + label 13px, 8px hover radius):
"General" grid icon (active: #F0F9FF bg, blue icon+text) · "Data Sources" database · "Risk Thresholds" sliders · "Alert Rules" bell · "Access Logs" list · "About" info.

RIGHT — 3 SECTION CARDS (16px gap, white, 12px radius, 20px padding):

CARD 1 "Platform Identity":
App icon 40px rounded + "TiyraSense" bold 17px + "v1.0 · SIH 2026" 12px gray inline.
Row: "Platform Name: TiyraSense NER ILP" 13px + "Edit" blue link right.
Row: "Operating Region: NER — Assam, Meghalaya, Nagaland, Manipur, Tripura, Mizoram, Arunachal Pradesh, Sikkim" 13px + "Edit" right.

CARD 2 "Data Source Status":
"Data Source Status" bold 17px.
4 rows (40px, 1px dividers): icon + source name bold 13px | status badge | ping mono far right.
PostGIS Database - CONNECTED green badge - 0ms.
IMD Weather Feed - LIVE green pulsing - 2m 14s.
ASDMA Field API - CONNECTED green - 8s.
OSRM Routing Engine - PROVIDER TBD gray badge.

CARD 3 "Risk Score Thresholds":
"Risk Score Thresholds" bold 17px + "Changes require Admin approval" 12px gray.
3 rows (20px gap each):
"LOW / CAUTION boundary" bold 13px + "30" blue badge right + 8px slider track (green fill to 30%).
"CAUTION / HIGH boundary" + "70" amber badge + amber fill to 70%.
"Emergency trigger threshold" + "85" red badge + red fill to 85%.
```

---

## 5. Shared UI Patterns

### Data Table Pattern

```
Filter bar always above the table
Header row: LABEL 11px uppercase #94A3B8, 44px height, #F8FAFC bg, 1px bottom border
Data rows: 52-64px height, 1px #E2E8F0 bottom divider, hover #F8FAFC
Actions in last column: link-style buttons, destructive action in #DC2626
Footer: count label left, pagination right
Empty state: centered icon + H2 gray + BODY #94A3B8
Loading: skeleton shimmer rows
```

### Empty State Pattern

```
Centered vertically and horizontally in container
Icon: 48px, #CBD5E1
Title: H2 #CBD5E1
Body: BODY #94A3B8, max 280px centered
Optional: primary action button below
```

### Modal / Overlay Pattern

```
Backdrop: rgba(15,23,42,0.40)
Modal card: #FFFFFF, 480px wide, 16px radius, MODAL-SHADOW
Header: H2 #0F172A + X button (32px circle, #F1F5F9 bg, #64748B icon)
Content: 24px padding
Footer CTA: pinned to modal bottom, full-width primary button
Dismiss: backdrop click or X
```

### Status Badge Anatomy

```
[● LABEL]
Dot: 6px circle, margin-right 5px
Text: TAG style (Inter 600, 11px)
Padding: 5px 10px
Radius: 20px
Background and border always match severity tint
```

### Card Hover Behavior

```
Default: CARD-SHADOW
Hover: ACTIVE-SHADOW + border-color #CBD5E1
Transition: 180ms ease-out
Cursor: pointer for clickable cards, default for display cards
```

### Skeleton Loader Pattern

```
Background: #F1F5F9
Shimmer: background-position animation, #E2E8F0 highlight sweep, 1.5s linear infinite
Text skeleton: 12-16px height, 6px radius, varied widths
Avatar skeleton: circle at avatar size
Card skeleton: full card height with 3 inner skeleton rows
```

---

## 6. Motion Specifications

| Element | Motion | Duration | Easing |
|---|---|---|---|
| Page navigation | Fade 0 to 1 | 200ms | ease-out |
| Card enter staggered | Slide up 6px + fade | 180ms | ease-out, 30ms stagger |
| Sidebar collapse/expand | Width 240px to 64px | 220ms | ease-in-out |
| Modal open | Scale 0.96 to 1 + fade | 200ms | ease-out |
| Modal close | Scale 1 to 0.96 + fade | 150ms | ease-in |
| Table row hover | Background color | 120ms | linear |
| LIVE badge pulse | Opacity 1 to 0.5 loop | 2s | ease |
| Alert card enter | Slide right 8px + fade | 200ms | ease-out |
| Sidebar item active | Background color | 120ms | ease |
| Button press | Scale 0.98 | 80ms | linear |
| Detail panel slide-in | Translate X 100% to 0% | 250ms | ease-out |
| Skeleton shimmer | BG position sweep | 1.5s | linear infinite |

---

## 7. Responsive Breakpoints

```
DESKTOP   >= 1280px    Full 3-panel layouts. Full 240px sidebar. All columns visible.
LAPTOP    1024-1279px  Sidebar icon-only 64px. 2-column content grids.
TABLET    768-1023px   Sidebar hidden, hamburger menu. Single column. Tables scroll horizontally.
MOBILE    < 768px      Shows "Use the TiyraSense mobile app" redirect. Not designed for mobile.
```

---

## 8. Accessibility Requirements

1. All interactive elements: >= 36x36px click target
2. All text: WCAG AA contrast (4.5:1 body, 3:1 large text)
3. Focus rings: 2px #0284C7 outline, 2px offset, on all interactive elements
4. Color never the sole status differentiator — always paired with text label
5. Data tables have th scope and ARIA labels
6. Modals trap focus, return focus on close
7. DATA: LIVE / HISTORICAL / SIMULATED / TEST label visible near all data sources
8. All numeric metrics have accessible aria-label attributes

---

## 9. Stitch Generation Order

```
1. W1 Login             establishes color, type, brand identity
2. TOPBAR               establishes shared shell chrome
3. SIDEBAR              establishes navigation system
4. W2 Dashboard         card system, tables, stat tiles, alerts
5. W3 Corridor Monitor  split-panel layout, map placeholder
6. W4 Field Reports     table + side panel pattern
7. W5 Alert Feed        two-column alert management
8. W6 User Management   CRUD table + modal pattern
9. W7 Settings          nested nav + configuration cards
```

---

## 10. Token Cross-Reference — Mobile (Flutter) to Web (React)

| Token | Hex Value | Mobile Name | Web CSS Custom Property |
|---|---|---|---|
| Canvas background | #F8FAFC | CANVAS | --color-canvas |
| Surface / card | #FFFFFF | SURFACE | --color-surface |
| Inner container | #F1F5F9 | CONTAINER | --color-container |
| Border hairline | #E2E8F0 | BORDER-LIGHT | --color-border |
| Text primary | #0F172A | TEXT-HIGH | --color-text-primary |
| Text secondary | #475569 | TEXT-MID | --color-text-secondary |
| Text muted | #64748B | TEXT-LOW | --color-text-muted |
| Text disabled | #94A3B8 | TEXT-XLOW | --color-text-disabled |
| Primary action | #0284C7 | BLUE | --color-primary |
| Primary hover | #0369A1 | BLUE-DARK | --color-primary-hover |
| Primary tint | #E0F2FE | BLUE-LIGHT | --color-primary-light |
| Primary surface | #F0F9FF | BLUE-BG | --color-primary-bg |
| Success / green | #10B981 | GREEN | --color-success |
| Warning / amber | #F59E0B | AMBER | --color-warning |
| Danger / red | #DC2626 | RED | --color-danger |
| Emergency | #991B1B | DARK-RED | --color-emergency |

---

## 11. Pre-Generation Checklist

Before generating any web screen, confirm:

- [ ] Background is #F8FAFC — not pure white
- [ ] Cards are #FFFFFF — visible contrast against canvas
- [ ] "TiyraSense" wordmark appears ONLY on W1 Login
- [ ] Topbar is present on all authenticated views (W2-W7)
- [ ] Sidebar is present on all authenticated views (W2-W7)
- [ ] Zero dark elements, zero inverted navigation bars
- [ ] Primary actions use #0284C7 only
- [ ] Destructive/emergency use #DC2626 or #991B1B only
- [ ] Status always shown as pill badge with dot plus text label
- [ ] Data provenance label (LIVE / HISTORICAL / SIMULATED / TEST) visible near all data
- [ ] Tables have defined skeleton loading states
- [ ] Section labels: 11px Inter 700 uppercase #94A3B8

---

*TiyraSense Web · SIH 2026 · Problem Statement 26002*
*Google Stitch MCP: generate-screen-from-text · edit-screens · generate-variants*
*Token parity maintained with TiyraSense_Flutter_UI_Design.md*
