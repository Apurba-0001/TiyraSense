# TiyraSense
# SIH 2026 Problem Statement 26002
# AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)

> **Project context document**
>
> This document captures the complete project idea, problem definition, intended solution, product decisions, user roles, system behavior, AI/ML approach, routing philosophy, offline requirements, implementation direction, MVP scope, and future scalability decisions established during project planning.
>
> The purpose of this file is that **anyone reading it should be able to understand the project without needing the previous conversation**.

---

## Project Identity

**Project Name:** TiyraSense  
**Problem Statement:** SIH 2026 · 26002  
**Project Subtitle:** AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)

> **TiyraSense** is the project/product identity. The technical description remains the subtitle so the name can be used consistently across the mobile app, web dashboard, backend, documentation, and future deployment.

---

## 1. Executive Summary

The North Eastern Region (NER) of India faces difficult logistics and accessibility conditions because of challenging terrain, heavy and unpredictable weather, landslides, floods, road damage, infrastructure gaps, and limited connectivity to remote areas.

The project proposes an **AI-powered Logistics Safety and Accessibility Intelligence Platform** that helps drivers, field workers, logistics operators, officials, and administrators understand:

- whether a route is currently accessible,
- what risks exist along a route,
- what is likely to happen in the next few hours,
- how likely a road is to become disrupted,
- which safer alternatives are available,
- which vehicles are affected by an incident,
- and what officials need to monitor during normal and emergency conditions.

The system will combine real-time and historical information from multiple sources, including:

- government and official data,
- field reports,
- weather conditions and forecasts,
- traffic data where available,
- GIS/map and terrain information,
- historical disruption records,
- and other reliable external sources where necessary.

A central **data intelligence and conflict-resolution layer** will evaluate these sources based on factors such as reliability, recency, geographic relevance, supporting evidence, and consistency with other data.

The resulting intelligence will be used by:

1. an **AI/ML disruption prediction engine**,
2. a **road accessibility and risk engine**,
3. a **route optimization engine**,
4. an **incident and alert engine**,
5. and an **emergency-area intelligence system**.

The mobile application will be developed with **Flutter**, targeting Android and iOS where practical, with Android prioritized if cross-platform implementation becomes a constraint.

A separate web dashboard will be used by **officials and administrators** for monitoring, validation, incident management, vehicle monitoring, predictions, alerts, and system administration.

The TiyraSense platform will be designed **offline-first** because low-connectivity environments are part of the problem. Important route and alert information should remain available offline, while incident reports created without connectivity will be stored locally and automatically synchronized when connectivity returns.

The primary goal is not simply to show maps, track vehicles, or display weather. The primary goal is:

> **Use current data, historical patterns, and field intelligence to predict route disruption risk and recommend the safest viable route before and during a journey.**

---

# 2. Problem Statement

## 2.1 Official SIH problem context

The problem statement describes major logistics and accessibility challenges in the North Eastern Region due to:

- difficult terrain,
- extreme weather,
- limited transport connectivity,
- landslides,
- floods,
- road damage,
- infrastructure limitations,
- and disruptions affecting remote districts.

These disruptions can delay movement of:

- medicines,
- food supplies,
- agricultural produce,
- construction materials,
- and other essential goods.

The result can include:

- supply shortages,
- increased transportation costs,
- delayed delivery,
- disrupted public services,
- and slower emergency response.

The intended solution requires an integrated intelligent platform combining AI/ML, GIS, weather data, GPS, field inputs, route optimization, alerts, dashboards, multilingual support, and offline operation.

---

# 3. The Real Problem We Want to Solve

The practical problem is not only that roads become blocked.

The deeper problem is:

> **Drivers and authorities often do not have a single system that combines current road conditions, weather, historical disruption patterns, field reports, and geographic information to estimate what is happening now and what is likely to happen next.**

A driver may know a road exists, but may not know:

- whether the road is currently safe,
- whether a landslide is developing,
- whether heavy rainfall is likely to cause disruption,
- whether another driver has already encountered a problem,
- whether an alternate route is safer,
- or whether the delay of a longer route is worth accepting for a lower risk.

Similarly, an official may receive reports from different places but have no integrated operational view of:

- affected roads,
- affected vehicles,
- incidents,
- predicted high-risk corridors,
- alternative routes,
- and emergency impact zones.

The project therefore aims to convert **fragmented information into route-level operational intelligence**.

---

# 4. Why This Approach

A simple navigation application is not sufficient for this problem.

Normal route planning generally focuses on finding a route based on static road networks and factors such as travel time or distance.

This project needs to answer a different question:

> **Which route is the safest viable route given the current and predicted conditions?**

That requires combining:

### Current data
What is happening now?

### Predictive data
What is likely to happen soon?

### Historical data
What has happened in this area before?

### Field intelligence
What are people on the ground observing?

### Geographic context
Is the road located in a landslide-, flood-, or terrain-sensitive area?

### Operational context
What vehicle is being used and how important is the delivery?

The result should be a **risk-aware route recommendation**, not simply a shortest-path recommendation.

---

# 5. Core Product Vision

The core product loop is:

```text
Collect data
    ↓
Normalize data
    ↓
Assess source reliability
    ↓
Resolve conflicts
    ↓
Understand current road condition
    ↓
Predict future disruption risk
    ↓
Evaluate candidate routes
    ↓
Recommend the safest viable route
    ↓
Alert affected users
    ↓
Receive new field reports
    ↓
Recalculate intelligence
    ↓
Store actual outcomes
    ↓
Improve historical dataset and models
```

This creates a continuous intelligence loop rather than a static application.

---

# 6. One-Sentence Product Definition

> **An AI-powered logistics safety platform that combines real-time, historical, geographic, weather, and field intelligence to predict route disruptions, assess accessibility, recommend safer alternatives, and alert drivers and officials before and during critical logistics journeys.**

---

# 7. Main Users

The TiyraSense platform will use role-based access.

## 7.1 Driver

The driver uses the mobile application to:

- enter or select a destination,
- view the route,
- see current road accessibility,
- see route risk,
- see predicted disruption probability,
- receive real-time incident alerts,
- receive safer alternate route recommendations,
- optionally view the fastest alternative,
- track the journey,
- submit incident reports,
- and operate with low connectivity.

The driver is both a **consumer of intelligence** and a **source of field intelligence**.

---

## 7.2 Field Worker

Field workers use the mobile application to:

- report road problems,
- report traffic problems,
- report weather-related hazards,
- capture photographs,
- attach GPS coordinates,
- record severity,
- add short descriptions,
- and submit information while online or offline.

Field workers provide ground-truth information that can become an important signal for the intelligence engine.

---

## 7.3 Official

Officials use the web application to:

- monitor incidents,
- monitor road accessibility,
- review field reports,
- validate incidents,
- monitor vehicles,
- view risk predictions,
- monitor affected corridors,
- inspect emergency zones,
- and review system alerts.

Officials are responsible for operational oversight and validation rather than replacing the automated intelligence system.

---

## 7.4 Admin

Administrators use the web dashboard to:

- manage users,
- manage roles,
- manage system configuration,
- manage data sources,
- manage incident and alert settings,
- manage geographic areas,
- monitor system health,
- and manage the broader platform.

---

# 8. Platform Structure

The project will have two primary user-facing applications and one backend intelligence platform.

## 8.1 Mobile Application

Technology:

**Flutter**

Primary users:

- Drivers
- Field workers

Main capabilities:

- route planning,
- route risk,
- road accessibility,
- disruption alerts,
- alternate routes,
- incident reporting,
- GPS,
- offline operation,
- synchronization.

---

## 8.2 Web Dashboard

Primary users:

- Officials
- Admins

Main capabilities:

- regional map,
- incident monitoring,
- road accessibility monitoring,
- vehicle monitoring,
- prediction monitoring,
- report validation,
- emergency response view,
- alert management,
- analytics,
- administration.

---

## 8.3 Backend Intelligence Platform

The backend acts as the central processing layer.

It is responsible for:

- authentication,
- APIs,
- data ingestion,
- data normalization,
- geospatial processing,
- source reliability evaluation,
- conflict resolution,
- AI/ML prediction,
- route risk calculation,
- route optimization,
- incident processing,
- alerts,
- vehicle tracking,
- offline synchronization,
- historical data storage,
- and model feedback.

---

# 9. The Most Important Product Decision: Safety First

The route recommendation policy is:

> **Prefer the safer route over the fastest route.**

However, the application should not hide faster options.

Example:

### Route A

```text
ETA: 5h 20m
Disruption probability: 78%
Overall route risk: HIGH
```

### Route B

```text
ETA: 6h 05m
Disruption probability: 14%
Overall route risk: LOW
```

The system should recommend:

> **Recommended Route: Route B**

while still allowing the driver to view:

> **Fastest Route: Route A**

The user should understand the trade-off rather than receiving an unexplained route choice.

---

# 10. Risk Must Be Defined Clearly

The system should not use one vague AI-generated number for every form of risk.

There should be at least three different concepts.

## 10.1 Current Accessibility

Describes what the system believes about the road **right now**.

Suggested states:

```text
OPEN
CAUTION
RESTRICTED
HIGH RISK
BLOCKED
UNKNOWN
```

---

## 10.2 Disruption Probability

This is the predictive ML output.

Example:

> **There is a 72% probability that this road will become blocked within the next 12 hours.**

This is specifically a predicted probability of future disruption.

It should be associated with a time horizon.

Examples:

- next 1 hour,
- next 3 hours,
- next 6 hours,
- next 12 hours,
- next 24 hours.

The initial design should focus on **current conditions plus approximately the next 24 hours**.

---

## 10.3 Route Risk Score

This describes the risk of the **entire route**.

Example:

```text
Route Risk: 24 / 100
```

This score can incorporate:

- current road accessibility,
- predicted disruption probability,
- weather,
- flood risk,
- landslide risk,
- traffic,
- road restrictions,
- vehicle compatibility,
- delivery priority,
- emergency status,
- and data confidence.

---

# 11. Why Separate These Metrics

Example:

```text
Current Accessibility: OPEN
Disruption Probability: 78%
```

This means:

> The road is currently usable, but conditions suggest a high possibility that it may become disrupted soon.

That is different from:

```text
Current Accessibility: BLOCKED
Disruption Probability: 95%
```

The second is already blocked.

Keeping these concepts separate makes the product easier to understand, easier to model, and safer to communicate.

---

# 12. Data Sources

The platform is designed to combine multiple sources.

Primary planned sources:

1. Government and official data
2. Field reports
3. Weather data and forecasts
4. Traffic data where available
5. GIS/map data
6. Terrain/geographic information
7. Historical road-disruption records

Additional sources may be used when appropriate and reliable, including strong external reports or other information sources.

The actual list of APIs and providers is a **technical selection that still needs validation** based on availability, coverage, licensing, reliability, and free-tier limits.

The project should not claim that a source is available until it has actually been verified.

---

# 13. Data Philosophy

No source should automatically be treated as perfectly correct.

Instead, information should be evaluated based on:

- source reliability,
- freshness,
- geographic relevance,
- supporting evidence,
- consistency with other observations,
- and historical/environmental context.

This is the basis of the project's **conflict-resolution engine**.

---

# 14. Conflict-Resolution Engine

The system must be able to handle inconsistent reports.

Example:

```text
Government source:
Road OPEN

Driver:
Road partially blocked

Field worker:
Landslide observed

Weather:
Heavy rainfall

Historical data:
High landslide susceptibility
```

The system should not blindly select one source.

Instead, it should evaluate all available evidence and produce an operational assessment.

Possible result:

```text
Current Status: HIGH RISK
Confidence: 91%

Reason:
Multiple recent field reports,
heavy rainfall,
and historical landslide susceptibility
support increased disruption risk.
```

The exact algorithm is still to be implemented and validated, but the principle is fixed:

> **Use all relevant evidence and resolve conflicts according to reliability, recency, relevance, and corroboration.**

---

# 15. Source Reliability and Confidence

The system should maintain an internal confidence score for important intelligence.

Example:

| Source | Information | Example confidence |
|---|---|---:|
| Official road authority | Road closure | 98% |
| Verified field report | Landslide | 95% |
| Multiple independent reports | Flooding | 90% |
| Weather model | Heavy rainfall | 85% |
| Unverified user report | Road issue | 45% |

These values are examples, not final production values.

The actual reliability weights should be determined through testing and validation.

The TiyraSense platform should also preserve:

- source,
- timestamp,
- location,
- evidence,
- and processing history

so that important system decisions are traceable.

---

# 16. Geographic and Road Model

The TiyraSense platform should primarily reason about **road segments**, not just raw GPS points.

A road segment can have:

```text
Road Segment ID
Current accessibility
Historical incidents
Weather conditions
Terrain characteristics
Flood susceptibility
Landslide susceptibility
Traffic information
Active reports
Prediction
Risk score
Route impact
```

This structure allows the same road information to be reused by:

- drivers,
- route optimization,
- prediction,
- alerts,
- officials,
- and analytics.

---

# 17. Routing Strategy

The project should use an available road-network and routing solution rather than trying to build an entire routing engine from scratch.

The overall process is:

```text
Road network
     ↓
Generate candidate routes
     ↓
Evaluate road segments
     ↓
Apply accessibility restrictions
     ↓
Calculate route-level risk
     ↓
Consider vehicle and operational requirements
     ↓
Rank candidate routes
     ↓
Recommend safest viable route
```

The route engine is therefore combined with the project's intelligence rather than replacing established map/routing technology.

---

# 18. Route Evaluation Factors

Routes should eventually be evaluated using:

1. Current road condition
2. Weather
3. Flood risk
4. Landslide risk
5. Predicted disruption
6. Traffic
7. Road restrictions
8. Vehicle type
9. Delivery priority
10. Emergency conditions
11. Data confidence
12. Expected travel time

The system should prioritize safety while maintaining practical travel time.

---

# 19. Vehicle Model

For the first implementation:

> **Four-wheelers are the baseline vehicle category.**

The interface and backend should still be designed so that additional vehicle types can be introduced later.

Future vehicle categories may include:

- heavy trucks,
- light commercial vehicles,
- ambulances,
- emergency vehicles,
- small delivery vehicles,
- two-wheelers,
- and other specialized vehicles.

Vehicle-specific restrictions are intentionally part of the scalable design rather than the first mandatory implementation.

---

# 20. Delivery Priority

The TiyraSense platform should support the concept that different deliveries have different operational priorities.

Examples:

### Emergency medicine
Safety is critical and delay should be minimized within acceptable risk.

### Normal construction materials
Safety remains important, but a longer route may be more acceptable.

### Agricultural produce
Time sensitivity may be more important depending on the product.

The final optimization weights should be configurable rather than permanently hard-coded.

---

# 21. Field Reporting

Drivers and field workers should be able to create incident reports.

A report contains:

- GPS location,
- photograph,
- incident type/status,
- timestamp,
- severity,
- short description.

Example:

```text
Incident Type: Landslide
Severity: High
GPS: Automatically captured
Photo: Attached
Description: Road blocked by debris
Time: Automatically captured
```

The report is then processed by the backend intelligence system.

---

# 22. Incident Processing Workflow

The intended workflow is:

```text
User submits report
       ↓
Store report
       ↓
Validate basic information
       ↓
Determine geographic road segment
       ↓
Evaluate source reliability
       ↓
Compare with other data
       ↓
Update incident intelligence
       ↓
Recalculate road accessibility
       ↓
Recalculate route risk
       ↓
Check affected routes
       ↓
Generate alerts if needed
```

This closes the loop between field activity and route intelligence.

---

# 23. Optional AI Image Analysis

AI-based image analysis is a useful extension but is not a prerequisite for the core system.

Potential classifications:

- landslide,
- flooding,
- fallen tree,
- debris,
- damaged road,
- bridge damage,
- severe road obstruction,
- or no obvious incident.

The image model should function as an **additional evidence source**.

It should not by itself automatically declare that a road is blocked.

Example:

```text
Photo
  ↓
Vision model
  ↓
Possible landslide detected
Confidence: 88%
  ↓
Combine with:
weather
terrain
field reports
historical data
official data
  ↓
Final incident assessment
```

---

# 24. Real-Time Disruption Prediction

One of the core AI goals is to answer:

> **What is the probability that a road will become disrupted within the next few hours?**

Initial prediction horizon:

> **Current condition plus approximately the next 24 hours.**

A prediction might look like:

```text
Road: NH-6
Disruption probability:
78%

Prediction window:
Next 12 hours

Main contributing factors:
- Heavy rainfall forecast
- Historical landslide occurrence
- Terrain vulnerability
- Recent field reports
```

The actual mathematical model must be trained, validated, and calibrated before production use.

---

# 25. Machine Learning Data

The long-term model should learn from both current and historical records.

Potential features include:

### Environmental
- rainfall,
- forecast rainfall,
- temperature,
- weather conditions,
- flood indicators.

### Geographic
- terrain,
- slope,
- elevation,
- location,
- road segment characteristics.

### Historical
- previous landslides,
- previous floods,
- previous closures,
- previous disruptions,
- time and season patterns.

### Operational
- traffic,
- road condition,
- restrictions,
- field reports.

### Outcome
A historical target such as:

```text
disrupted = 0
or
disrupted = 1
```

with an appropriate future time window.

---

# 26. Proposed AI/ML Components

The system should use specialized components instead of one "AI model."

## Model 1: Disruption Prediction

Purpose:

> Estimate probability of disruption within the selected future time horizon.

---

## Model 2: Travel-Time Prediction

Purpose:

> Estimate expected travel time under current conditions.

---

## Model 3: Route Risk Model

Purpose:

> Combine road-level risk into a route-level safety score.

---

## Model 4: Incident Classification

Purpose:

> Classify user-reported incidents into useful categories.

---

## Model 5: Image Analysis

Purpose:

> Extract additional evidence from incident photographs.

The first model to prioritize is the **road disruption prediction model**.

---

# 27. ML Technology Direction

The first implementation should prioritize reliable structured-data ML over unnecessary complexity.

Candidate model families for the initial structured prediction problem include:

- Random Forest,
- Gradient Boosting,
- XGBoost/LightGBM-style models.

The final model should be selected based on:

- available training data,
- predictive performance,
- calibration,
- interpretability,
- speed,
- robustness,
- and ease of deployment.

Deep learning can be introduced later if the data volume and problem justify it.

The project should not use deep learning merely for presentation value.

---

# 28. AI Safety and Reliability Principle

Because route recommendations can affect real-world travel and potentially human safety:

The TiyraSense platform should never represent predictions as guarantees.

Preferred wording:

> **Based on available evidence, Route B has a lower predicted disruption risk.**

Not:

> **Route B is guaranteed safe.**

Important decisions should retain:

- prediction,
- confidence,
- timestamp,
- relevant evidence,
- and model version.

This supports monitoring, auditing, and future improvement.

---

# 29. Continuous Learning

The system should learn from actual outcomes.

Example:

```text
Prediction:
75% chance of disruption

Actual result:
Road remained open
```

That real-world outcome becomes part of the historical record.

The long-term learning cycle is:

```text
Historical data
     ↓
Training dataset
     ↓
Model training
     ↓
Validation
     ↓
Production model
     ↓
Predictions
     ↓
Actual outcomes
     ↓
New historical record
     ↓
Dataset improvement
     ↓
Model retraining
```

Model updates should be controlled and validated, not automatically deployed blindly.

---

# 30. Emergency Mode

The TiyraSense platform should have a dedicated emergency mode for severe events such as:

- landslides,
- heavy rainfall,
- flooding,
- and other severe disruptions.

The emergency system should make the event operationally visible.

Example:

```text
LANDSLIDE ALERT

NH-6
14 km ahead

Blockage probability: 89%

Recommended action:
Take Route B
```

---

# 31. Affected-Area Intelligence

Emergency events should create a geographic affected zone.

The system should identify:

- vehicles inside the zone,
- vehicles approaching the zone,
- routes crossing the zone,
- affected roads,
- nearby officials,
- nearby field workers,
- and other relevant users.

Example:

```text
Incident
   ↓
Affected geographic area
   ↓
Affected road segments
   ↓
Affected routes
   ↓
Affected vehicles
   ↓
Targeted alerts
```

This avoids sending every alert to every user unnecessarily.

---

# 32. Alerting System

Alerts should be event-based and targeted.

Example:

```text
LANDSLIDE ALERT

NH-6
14 km ahead
High probability of blockage

Recommended:
Take Route B
```

Potential alert recipients:

- drivers whose current route is affected,
- drivers approaching an affected zone,
- officials responsible for the area,
- relevant field workers,
- and other authorized users within the affected area.

Alerts should be recalculated when new evidence changes the situation.

---

# 33. Vehicle Tracking

The mobile app should support real-time location tracking where available.

At minimum, the system should also support a trip based on:

```text
Source
+
Destination
```

so that the backend can evaluate:

- route risk,
- expected availability,
- active incidents,
- disruptions,
- and alternative routes.

The journey screen should provide a map-style experience.

When a route changes, the user should be able to see the new route visually.

---

# 34. Route Journey Experience

Example:

```text
Current Route
Guwahati → Destination

ETA: 6h 05m
Risk: LOW
Accessibility: OPEN

Next significant risk:
Heavy rainfall area
42 km ahead
```

After a disruption:

```text
ROUTE UPDATE

Original route:
HIGH RISK

New recommended route:
LOW RISK

ETA change:
+45 minutes
```

The user should understand both the recommendation and the reason for the recommendation.

---

# 35. Offline-First Requirement

Offline functionality is a core requirement because low connectivity is part of the target environment.

The system should not treat offline support as a later convenience feature.

---

# 36. Offline Reporting

If a driver or field worker is offline:

```text
Create report
      ↓
Store locally
      ↓
Continue working
```

When connectivity returns:

```text
Local report
      ↓
Automatic synchronization
      ↓
Backend
      ↓
Normal processing
```

The application should make the status clear:

> **Saved offline. Will sync automatically when network returns.**

---

# 37. Offline Important Information

The mobile application should retain important journey information locally, including where practical:

- active route,
- recent map/route data,
- latest road statuses,
- relevant alerts,
- important incident information,
- and necessary journey context.

Before entering a low-connectivity area, the app should have enough synchronized information to remain useful.

Offline data must carry timestamps so that stale information is not mistaken for current information.

---

# 38. Synchronization Strategy

The mobile application should use local storage plus a synchronization mechanism.

Conceptually:

```text
ONLINE
Cloud ↔ Mobile

OFFLINE
Mobile → Local Database

NETWORK RESTORED
Local Database → Sync Queue → Cloud
```

The system should handle:

- duplicate submissions,
- retry after failed sync,
- timestamps,
- synchronization state,
- and conflicts.

---

# 39. Current Product Boundary

The first implementation is intended to be a **real working prototype with a path toward real deployment**, not a mockup that only looks intelligent.

At the same time, every data source and model must be validated before real operational claims are made.

The product should be built step-by-step.

---

# 40. Geographic Scope

The long-term scope is:

> **North Eastern Region of India**

The project should eventually support the NER broadly and be architected so it can expand to other states/regions.

However, the implementation should initially use a controlled geographic scope or selected corridors to ensure:

- data quality,
- manageable testing,
- reliable predictions,
- realistic demonstrations,
- and meaningful validation.

The exact first demonstration geography is still to be selected.

---

# 41. Real-World Data Requirement

The project intends to use real-time APIs and real data.

Where government data is available and suitable:

> Prefer authoritative government/official data.

Where government data is insufficient or unavailable:

> Use appropriate alternative sources such as weather, GIS, traffic, or other reliable sources.

The TiyraSense platform should not fabricate unavailable real-time information.

For development and model construction, synthetic or simulated records may be used when necessary, but the system should clearly distinguish:

- simulated data,
- historical data,
- live data,
- and verified field data.

---

# 42. Free-First Development Strategy

Initial development should be:

> **As free as reasonably possible.**

Use:

- open-source software,
- free APIs/free tiers where practical,
- local development,
- open map data where appropriate,
- and low-cost/free cloud resources during the prototype stage.

The architecture should remain modular so that after funding becomes available, better commercial or infrastructure resources can be introduced without rewriting the entire system.

The design should therefore avoid hard dependencies on one vendor wherever practical.

---

# 43. High-Level System Architecture

```text
                         ┌──────────────────────┐
                         │   Flutter Mobile App │
                         │ Drivers / Field      │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   Backend API Layer  │
                         └──────────┬───────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
          ▼                         ▼                         ▼
 ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
 │ Data Ingestion   │     │ Intelligence     │     │ User / App       │
 │ Services         │     │ Services         │     │ Services         │
 └────────┬─────────┘     └────────┬─────────┘     └──────────────────┘
          │                        │
          ▼                        ▼
 Government data            Conflict Resolution
 Weather                    Accessibility Engine
 Traffic                    ML Prediction
 GIS / Maps                 Route Risk
 Field reports              Route Optimization
 Historical data            Incident Analysis
 Other validated sources   Alert Decisions
          │                        │
          └──────────────┬─────────┘
                         ▼
                ┌────────────────────┐
                │ Geospatial / Core  │
                │ Database Layer     │
                └─────────┬──────────┘
                          │
                          ▼
                 ┌───────────────────┐
                 │ Web Dashboard     │
                 │ Officials / Admin │
                 └───────────────────┘
```

---

# 44. Suggested Technology Direction

These are current architectural directions, not final vendor commitments.

## Mobile

**Flutter**

Target:

- Android,
- iOS where practical.

Android may receive priority if implementation constraints make full cross-platform support difficult.

---

## Backend

A backend technology that integrates naturally with data/ML processing is preferred.

Python is a strong candidate because it can support:

- APIs,
- data processing,
- geospatial processing,
- ML workflows,
- and model serving.

A final backend framework is still a technical selection to make.

---

## Database

The TiyraSense platform should use a relational database with geospatial capabilities.

The data model needs to support:

- roads,
- road segments,
- coordinates,
- incidents,
- users,
- vehicles,
- routes,
- alerts,
- geographic zones,
- historical records,
- and prediction results.

---

## Maps and Routing

An OpenStreetMap-based ecosystem is a strong starting point for free-first development.

The exact map/routing provider or self-hosted routing engine should be selected after comparing:

- road coverage,
- routing quality,
- NER suitability,
- API limits,
- licensing,
- offline support,
- and cost.

---

## ML

Python ML tooling is appropriate for the initial prediction pipeline.

The first structured risk model should be chosen based on actual dataset availability and validation results.

---

## Local Mobile Storage

The Flutter application should include local persistent storage for:

- reports,
- pending sync items,
- cached journey data,
- alerts,
- and other required offline information.

The exact local database technology remains a technical implementation decision.

---

# 45. Data Pipeline

The intended data pipeline is:

```text
External Sources
      ↓
Data Collection
      ↓
Validation
      ↓
Normalization
      ↓
Geospatial Mapping
      ↓
Source Reliability
      ↓
Conflict Resolution
      ↓
Current State Engine
      ↓
Prediction Engine
      ↓
Route Risk Engine
      ↓
Route Optimization
      ↓
Alerts / Dashboards / Mobile
```

---

# 46. Data Normalization

Different data sources may use different:

- timestamps,
- coordinate formats,
- names,
- road identifiers,
- categories,
- units,
- and reporting structures.

Before intelligence processing, data should be normalized into a common internal representation.

For example, every incident should ultimately have:

```text
incident_id
source
timestamp
location
road_segment
type
severity
evidence
confidence
status
```

---

# 47. Core Data Entities

The initial data model should include entities such as:

## User

```text
user_id
name
role
contact
permissions
status
```

Roles:

- DRIVER
- FIELD_WORKER
- OFFICIAL
- ADMIN

---

## Vehicle

```text
vehicle_id
user/operator
vehicle_type
current_location
status
```

The initial implementation can assume a four-wheeler baseline.

---

## Road Segment

```text
road_segment_id
geometry
road_name
district
state
current_accessibility
current_risk
```

---

## Incident

```text
incident_id
type
severity
location
road_segment
reported_by
timestamp
photo/evidence
description
status
confidence
```

---

## Weather Observation

```text
timestamp
location
rainfall
forecast
temperature
other relevant variables
source
```

---

## Prediction

```text
prediction_id
road_segment
prediction_time
horizon
disruption_probability
confidence
model_version
```

---

## Route

```text
route_id
origin
destination
geometry
eta
risk_score
disruption_probability
accessibility
```

---

## Alert

```text
alert_id
incident
affected_area
severity
message
created_at
recipients
status
```

---

# 48. Road Status Update Logic

A road status can be influenced by:

```text
Official updates
+
Field reports
+
Weather
+
Traffic
+
Historical patterns
+
GIS/terrain
+
Incident evidence
+
Other validated sources
```

The result should be a current accessibility state.

Example:

```text
OPEN
↓
CAUTION
↓
HIGH RISK
↓
BLOCKED
```

or, if evidence improves:

```text
BLOCKED
↓
RESTRICTED
↓
OPEN
```

The system should maintain the supporting evidence behind significant transitions.

---

# 49. Notification Philosophy

Notifications should be:

- relevant,
- location-aware,
- route-aware,
- time-sensitive,
- and understandable.

A driver should not receive every event in NER.

The primary principle is:

> **Alert users who can actually be affected.**

For example:

A landslide 200 km away on a route unrelated to the driver's journey should not trigger a high-priority alert.

A landslide 14 km ahead on the driver's active route should.

---

# 50. Dashboard Design Philosophy

The web dashboard should answer operational questions quickly.

Important top-level information can include:

```text
Active Incidents
High-Risk Corridors
Blocked Roads
Vehicles in Transit
Affected Districts
Emergency Events
```

The dashboard should then provide:

### Regional Map

- roads,
- incidents,
- vehicles,
- risk,
- weather,
- affected areas.

### Incident Management

- new reports,
- under review,
- validated,
- resolved.

### Prediction View

- roads with elevated future disruption probability.

### Vehicle View

- current vehicles,
- route,
- status,
- risk,
- active alerts.

---

# 51. Mobile App Primary Screens

A likely initial structure is:

1. Login / Role access
2. Home / current status
3. Plan Journey
4. Route Results
5. Active Navigation / Journey
6. Route Risk Details
7. Incident Alerts
8. Report Incident
9. My Reports
10. Offline/Sync status
11. Profile/settings

The exact UI should be designed after the system flows are finalized.

---

# 52. Example Driver Journey

## Step 1

Driver enters:

```text
Source: Guwahati
Destination: Remote district
Vehicle: Four-wheeler
Priority: Essential delivery
```

## Step 2

System evaluates:

- map network,
- current road status,
- weather,
- traffic,
- historical risk,
- active incidents,
- predicted disruptions.

## Step 3

The system generates route candidates.

Example:

```text
Route A
ETA: 5h 20m
Risk: 72%
```

```text
Route B
ETA: 6h 05m
Risk: 14%
```

## Step 4

The system recommends Route B.

## Step 5

Driver begins journey.

## Step 6

Heavy rain increases.

## Step 7

The ML system increases disruption probability.

## Step 8

A field worker reports a landslide.

## Step 9

The conflict-resolution engine combines:

- field report,
- weather,
- terrain,
- historical evidence,
- and any official information.

## Step 10

The affected road becomes HIGH RISK or BLOCKED.

## Step 11

The driver receives:

```text
LANDSLIDE ALERT
14 km ahead

High probability of blockage.

Recommended:
Take Route B
```

## Step 12

The routing engine recalculates.

## Step 13

The driver receives the new route and ETA.

This sequence should be the central demonstration scenario.

---

# 53. Primary SIH Demonstration Scenario

The selected demonstration concept is a **combined severe-weather + landslide + rerouting scenario**.

It combines:

- predictive weather risk,
- historical pattern recognition,
- current conditions,
- field reporting,
- incident intelligence,
- route risk,
- alternate routing,
- location-aware alerting,
- and emergency response.

Example sequence:

```text
Journey Begins
      ↓
Heavy rainfall detected/forecast
      ↓
Road disruption risk begins rising
      ↓
Model predicts high risk
      ↓
Field report appears
      ↓
Evidence is combined
      ↓
Road becomes HIGH RISK / BLOCKED
      ↓
Affected drivers identified
      ↓
Emergency alert issued
      ↓
Safer route calculated
      ↓
Driver rerouted
      ↓
Official dashboard updates
```

This scenario demonstrates the largest amount of the platform in one understandable story.

---

# 54. MVP Scope

The first serious implementation should prioritize the following.

| Capability | Priority |
|---|---|
| Flutter driver/field app | Core |
| GPS | Core |
| GIS/map | Core |
| Route planning | Core |
| Current road accessibility | Core |
| Weather integration | Core |
| Route risk score | Core |
| Disruption prediction | Core |
| Alternate routing | Core |
| Incident reporting | Core |
| Alerts | Core |
| Conflict resolution | Core |
| Offline reports | Core |
| Offline important route data | Core |
| Official web dashboard | Core |
| Emergency mode | Core |
| Vehicle tracking | Core |
| AI image analysis | Optional initially |
| Multiple vehicle types | Future |
| Entire NER production coverage | Future |

---

# 55. What Is Not the Initial Priority

The following should not delay the core product:

- highly advanced computer vision,
- every possible vehicle type,
- full nationwide deployment,
- every possible government integration,
- complicated deep-learning architectures,
- unnecessary UI features,
- or a huge number of third-party APIs.

The goal is to build a **working intelligent safety platform first**.

---

# 56. Development Roadmap

The development should proceed in controlled stages.

## Stage 1: Product and Data Specification

Define:

- exact user flows,
- route behavior,
- risk definitions,
- incident lifecycle,
- data entities,
- source types,
- and validation rules.

Do not start by building large amounts of UI.

---

## Stage 2: Data Source Research

For every planned source, document:

```text
Source
What it provides
Coverage
Update frequency
Reliability
API/interface
License
Cost
Historical availability
NER suitability
```

Only verified sources should be treated as real implementation dependencies.

---

## Stage 3: Core Geospatial System

Build:

- map,
- road network,
- coordinates,
- road segments,
- incident locations,
- geographic zones.

The system should be able to identify which road segment a report belongs to.

---

## Stage 4: Backend Foundation

Build:

- authentication,
- user roles,
- APIs,
- database,
- geospatial services,
- incident service,
- basic alert service.

---

## Stage 5: Mobile Foundation

Build the Flutter app with:

- login,
- home,
- journey planning,
- map,
- report incident,
- local storage,
- sync state.

---

## Stage 6: Real-Time Data Integration

Connect verified sources for:

- weather,
- traffic where available,
- GIS/map information,
- official data where available.

Create the normalization layer.

---

## Stage 7: Accessibility and Risk Engine

Implement:

- road statuses,
- evidence aggregation,
- confidence,
- conflict resolution,
- route risk calculation.

At this stage the system should already produce useful non-ML risk-aware route behavior.

---

## Stage 8: Historical Dataset

Build a usable historical dataset from:

- historical incidents,
- historical weather,
- geographic characteristics,
- road information,
- and actual known outcomes.

The dataset should be structured around road segments and time windows.

---

## Stage 9: ML Prediction

Train and validate the disruption prediction model.

Initial target:

> **Probability of disruption within the selected future horizon.**

Evaluate:

- precision,
- recall,
- calibration,
- false positives,
- false negatives,
- performance by geographic area,
- and performance across weather conditions.

Because safety is important, false negatives should be treated as a serious consideration.

---

## Stage 10: Route Intelligence

Integrate:

- routing engine,
- road accessibility,
- route risk,
- predicted disruptions,
- vehicle baseline,
- delivery priority.

Then implement:

> **Safest viable route recommendation + fastest route alternative.**

---

## Stage 11: Field Reporting and Feedback

Connect incident reporting to the intelligence engine.

New reports should affect:

- road status,
- incident state,
- risk,
- route recommendations,
- and alerts where appropriate.

---

## Stage 12: Emergency Mode

Implement:

- incident zone,
- affected users,
- affected vehicles,
- emergency routes,
- targeted alerts,
- dashboard emergency view.

---

## Stage 13: Offline and Sync Hardening

Test:

- no network,
- weak network,
- network interruption during report upload,
- repeated retry,
- duplicate reports,
- stale data,
- and reconnection.

The app must remain usable when connectivity is poor.

---

## Stage 14: Dashboard

Build official/admin views for:

- map,
- incidents,
- roads,
- vehicles,
- risk,
- predictions,
- alerts,
- validation,
- and emergency events.

---

## Stage 15: End-to-End Testing

Test realistic scenarios:

### Normal journey
No disruption.

### Heavy rainfall
Risk increases.

### Field report
New evidence changes risk.

### Landslide
Road status changes.

### Route blocked
Alternative route appears.

### Offline report
Data stays locally stored.

### Network restored
Report synchronizes.

### Conflicting reports
Conflict engine resolves evidence.

### Emergency event
Affected users receive alerts.

---

# 57. Validation Strategy

The system should not only be demonstrated with a successful scenario.

It should be tested against actual outcomes.

For prediction:

```text
Predicted
vs
Actual
```

For routing:

```text
Recommended route
vs
Known road restrictions/incidents
```

For alerts:

```text
Affected users
vs
Actually affected users
```

For field reporting:

```text
Report received
vs
System state update
```

This should become part of model and product evaluation.

---

# 58. Metrics That Matter

Useful system metrics include:

### Prediction

- disruption prediction accuracy,
- precision,
- recall,
- calibration,
- false-negative rate.

### Routing

- route feasibility,
- travel-time error,
- avoided high-risk segments,
- successful rerouting rate.

### Alerts

- relevant alerts delivered,
- alert latency,
- false alerts,
- affected-user coverage.

### Field reporting

- report-to-processing time,
- synchronization success,
- duplicate report rate.

### System

- API response time,
- data freshness,
- service availability,
- offline sync success.

---

# 59. Important Reliability Principle

The system should distinguish between:

### Known fact

> Government authority reported road closure at 10:32.

### Observation

> Driver reported obstruction with a photograph.

### Prediction

> Model predicts 72% disruption probability.

### Recommendation

> Route B is recommended based on lower predicted risk.

These are not the same thing.

The UI and backend should preserve this distinction.

---

# 60. Explainability

For important risk and routing decisions, the system should provide a reason.

Example:

> **Why is this route high risk?**

Possible answer:

```text
High rainfall forecast
+
Historical landslide risk
+
Recent field report
+
Current road restriction
```

The goal is not to show complicated ML mathematics to the user.

The goal is to make the decision understandable and auditable.

---

# 61. Future Scalability

The architecture should be extensible to:

### More vehicle types
Heavy trucks, emergency vehicles, etc.

### More states
Beyond the initial pilot geography.

### More data sources
Additional official and commercial feeds.

### Better models
More historical data and advanced models.

### More incident classes
Bridge failures, road erosion, infrastructure damage, etc.

### Advanced computer vision
Better automated image interpretation.

### More operational analytics
Supply chain bottlenecks, district-level shortage prediction, and infrastructure planning.

### Additional government integrations
Where official interfaces are available.

---

# 62. Future Supply-Chain Intelligence

The current core is route safety and accessibility.

Later versions can extend the platform to:

- supply-chain bottleneck detection,
- warehouse and stock visibility,
- demand forecasting,
- essential commodity shortage prediction,
- emergency supply prioritization,
- infrastructure planning,
- and district-level accessibility intelligence.

These are future extensions, not required for the first build.

---

# 63. Multilingual Support

Multilingual notifications are part of the long-term product requirement.

The exact initial language set should be selected based on the deployment geography.

The architecture should separate message content from UI/business logic so that additional languages can be introduced without rebuilding the alert engine.

---

# 64. Security and Data Handling

Because the system handles:

- user identities,
- GPS/location,
- operational reports,
- vehicle information,
- and potentially sensitive incident data,

the platform should include:

- authenticated access,
- role-based permissions,
- secure API communication,
- controlled report access,
- audit logs for important administrative changes,
- and careful retention policies.

Exact security architecture will be defined during implementation.

---

# 65. Important Design Principle: Do Not Fake Intelligence

The TiyraSense platform should never hard-code:

```text
Rain → Risk = 80%
```

just to make the demo look intelligent.

During development, every risk value should clearly originate from either:

- a documented rules engine,
- a validated model,
- a live source,
- a historical calculation,
- or clearly labeled simulated data.

The final SIH demonstration should make the origin of its intelligence explainable.

---

# 66. What Makes the Project Different

The project is not one isolated feature.

Its differentiation comes from the integration of:

```text
Real-time data
+
Historical patterns
+
Field intelligence
+
Conflict resolution
+
AI prediction
+
Road accessibility
+
Risk-aware routing
+
Emergency alerts
+
Offline operation
```

The strongest concept is the feedback loop:

> **People on the road contribute new evidence, and that evidence can change the route intelligence for everyone who may be affected.**

---

# 67. Final Product Concept

The final platform should work like a continuously updating safety layer over the logistics network.

For a route:

```text
CURRENT STATE
     +
PREDICTED STATE
     +
FIELD EVIDENCE
     +
HISTORICAL RISK
     +
GEOGRAPHIC CONTEXT
     ↓
ROUTE INTELLIGENCE
```

For the driver:

```text
Where should I go?
Is my route currently accessible?
What could happen ahead?
How risky is it?
Should I change route?
```

For the field worker:

```text
How do I report what I see quickly,
even without network?
```

For the official:

```text
What is happening?
Where is it happening?
Who is affected?
What is likely to happen next?
Which corridors are at risk?
```

For the administrator:

```text
Is the system operating correctly?
Are data sources functioning?
Are incidents and users managed properly?
```

---

# 68. Final Agreed Project Direction

The current project decisions can be summarized as follows:

| Decision | Selected Direction |
|---|---|
| Primary purpose | Predict route disruption and recommend safer routes |
| Main region | North Eastern Region |
| Geographic scaling | Start controlled, expand across NER, later other regions |
| User types | Driver, Field Worker, Official, Admin |
| Driver interface | Flutter mobile app |
| Field Worker interface | Flutter mobile app |
| Official interface | Web dashboard |
| Admin interface | Web dashboard |
| Vehicle baseline | Four-wheelers |
| Future vehicle support | Yes |
| Current condition analysis | Yes |
| Future risk prediction | Yes |
| Prediction horizon | Current + approximately next 24 hours |
| Disruption output | Probability of future disruption |
| Route output | Safer route + fastest route option |
| Safety principle | Prefer safer route |
| Current accessibility | OPEN / CAUTION / RESTRICTED / HIGH RISK / BLOCKED / UNKNOWN |
| Data sources | Official + field + weather + traffic + GIS + historical + validated additional sources |
| Source reliability | Yes |
| Confidence | Yes |
| Conflict resolution | Yes |
| Field reporting | Yes |
| Photo evidence | Yes |
| AI image analysis | Optional/secondary |
| GPS | Yes |
| Vehicle tracking | Yes |
| Emergency mode | Yes |
| Affected-area alerts | Yes |
| Offline operation | Core requirement |
| Offline report sync | Yes |
| Offline important route data | Yes |
| AI/ML | Actual prediction models, not only UI simulation |
| Learning over time | Yes, through actual outcomes and new historical data |
| Initial development cost | Free-first |
| Future infrastructure | Upgrade after funding |
| Primary SIH demo | Severe weather + landslide + prediction + alert + rerouting |
| Product goal | Real working platform with future scalability |

---

# 69. What Still Needs to Be Finalized

The project concept is now defined, but some **technical selections should not be guessed**.

These should be researched and finalized next:

1. Exact real-time weather APIs and historical weather sources.
2. Exact government/official road and disaster datasets/APIs available for NER.
3. Traffic data availability for NER.
4. Satellite/terrain data sources that are actually usable.
5. Map and routing engine.
6. Backend framework.
7. Database and geospatial database setup.
8. Cloud/free-tier deployment approach.
9. Flutter local database and sync technology.
10. Notification mechanism.
11. Exact historical dataset construction strategy.
12. First pilot geography/corridors.
13. Exact ML features and target definition.
14. Model validation methodology.
15. Risk-score mathematical design.
16. Conflict-resolution algorithm.
17. Authentication and role architecture.
18. Data-refresh and synchronization frequencies.

These are implementation decisions, not unresolved product vision.

---

# 70. Recommended Next Planning Order

Before serious coding, the project should now move through these documents/specifications in order:

```text
1. DATA SOURCE SPECIFICATION
        ↓
2. SYSTEM ARCHITECTURE
        ↓
3. DATABASE / GEO DATA MODEL
        ↓
4. ML DATASET + MODEL SPECIFICATION
        ↓
5. RISK ENGINE SPECIFICATION
        ↓
6. ROUTING / OPTIMIZATION SPECIFICATION
        ↓
7. API SPECIFICATION
        ↓
8. OFFLINE/SYNC SPECIFICATION
        ↓
9. MOBILE APP USER FLOWS
        ↓
10. WEB DASHBOARD USER FLOWS
        ↓
11. UI DESIGN
        ↓
12. IMPLEMENTATION
        ↓
13. TESTING + VALIDATION
```

The most important principle is:

> **Do not build the app UI first and then try to invent the intelligence behind it. Build the data, intelligence, route, and system contracts first, then implement the mobile and web interfaces around them.**

---

# 71. Final Vision

The intended result is a platform where a logistics journey is continuously evaluated rather than planned once.

Instead of:

> "Here is your route."

the platform should be able to say:

> "Here is your route, this is its current accessibility, this is the probability of disruption over the next 12 hours, these are the factors influencing the prediction, this is the safer alternative, and this is why we are recommending it."

Then, when something changes:

> "A new incident has been reported 14 km ahead. The evidence indicates a high likelihood of blockage. Your current route has been re-evaluated. Route B is now recommended."

And when a driver or field worker is offline:

> "Your report is saved locally and will be synchronized when connectivity returns."

The long-term objective is a **scalable regional logistics intelligence layer for the NER**, beginning with a focused, demonstrable, technically credible implementation and expanding as data, funding, and deployment opportunities increase.
