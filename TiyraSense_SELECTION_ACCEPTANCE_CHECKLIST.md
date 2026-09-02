# TiyraSense — Selection Demo Acceptance Checklist

Use this checklist on Day 7.

## Core Journey

- [ ] Driver can authenticate
- [ ] Driver can select destination
- [ ] Current location works
- [ ] Map renders correctly
- [ ] Candidate route(s) render
- [ ] ETA and distance display
- [ ] Current accessibility displays
- [ ] Route risk displays
- [ ] Recommendation explains safer vs fastest route

## Real-Time Intelligence

- [ ] Weather data is available or clearly labeled
- [ ] Risk updates when relevant inputs change
- [ ] Data source/status is visible where needed
- [ ] Simulated/test values are clearly labeled

## Incident Intelligence

- [ ] Driver/field worker can report incident
- [ ] GPS is captured
- [ ] Severity is captured
- [ ] Incident type is captured
- [ ] Description is captured
- [ ] Photo handling works or is clearly deferred
- [ ] Report maps to road segment
- [ ] Conflicting evidence can be represented
- [ ] Road accessibility/risk can change

## Alert and Emergency Flow

- [ ] Affected journey can be identified
- [ ] Targeted alert is produced
- [ ] Alternate route is generated
- [ ] Updated recommendation appears to driver
- [ ] Official dashboard reflects the change

## Offline

- [ ] Incident can be created offline
- [ ] Report is stored locally
- [ ] Report has PENDING state
- [ ] Reconnect triggers sync
- [ ] SYNCED state is confirmed
- [ ] Stale cached data is timestamped

## Security

- [ ] Role restrictions enforced server-side
- [ ] Sensitive endpoints are authenticated
- [ ] No secrets in repository
- [ ] Upload validation is present
- [ ] Debug endpoints are not exposed publicly
- [ ] Test accounts do not bypass authorization

## Demo Quality

- [ ] No dead buttons on the demo path
- [ ] No broken navigation
- [ ] No misleading AI claims
- [ ] No fake data presented as live
- [ ] Demo can run from a clean start
- [ ] Complete scenario works without manual DB editing
- [ ] Screenshots/presentation claims match actual implementation

## Final Status

Selection build status:

```text
NOT STARTED
PARTIALLY COMPLETE
COMPLETE
BLOCKED
```
