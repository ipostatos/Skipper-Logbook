# 06 — Release Notes Draft

## 0.9.1 (alignment pass) — draft

### New
- **Weather screen** (More → Weather): manual wind/sea observations from the log,
  clearly-labeled Coming Soon forecast & tide cards. No fake live data.
- **Waypoint on the Map**: new add-waypoint mode — tap the chart to set the
  active voyage's destination. Route line, waypoint marker, next-waypoint card,
  ETA and remaining distance now light up during real voyages.
- **MOB from the Map**: hold-to-activate red MOB control among the floating
  map buttons.
- **CSV & GPX export**: share any voyage as a CSV logbook or a GPX track
  (waypoint + track segments) from the voyage detail screen. PDF still Coming Soon.
- **Audio note tags**: tag voice notes Weather / Engine / Sails / Crew / Issue;
  speed & course are now captured alongside position.
- **Voice notes in the timeline**: audio notes appear chronologically inside the
  Logbook day groups.
- **Anchor alarm**: dragging outside the radius now fires haptics, a sound and a
  local notification — not just a red label.
- **Today smart states**: anchored card while anchor watch runs, red MOB banner
  when a MOB is active, location-permission guidance card when access is denied.

### Fixed
- First launch no longer shows demo data ("Sea Breeze" fleet); the app starts
  empty. Demo seed is dev/preview-only (`--seed-demo`).
- MOB triggers and resolutions are always written to the Logbook, from every path.
- Anchor down/up events are logged.
- Background-tracking toggle now actually requests Always authorization and
  honours it; explains itself when denied.
- Unit-system picker no longer pretends to work (Coming Soon until implemented).
- Engine save failures are logged instead of silently ignored.

### Model changes (additive, lightweight migration)
- `VoiceNote`: + `tagsRaw`, `speedKnots`, `courseDegrees`
- `Vessel`: + `waterCapacityLiters`, `notes`
