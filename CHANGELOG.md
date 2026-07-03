# Changelog

All notable changes to Skipper Logbook are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] — 2026-07-03 · BETA

First public BETA. Native iOS (SwiftUI + SwiftData, iOS 17), "Liquid Nautical"
design language.

### Added
- **Today** — contextual home: start-voyage CTA when idle; live course arc,
  speed/waypoint sparkline cards and recording banner while underway; boat-state
  tiles (engine / sails % / anchor) and one-tap MOB.
- **Live GPS voyage recording** (CoreLocation) — track, speed, heading, distance,
  engine time, ETA.
- **Map** — Apple-Maps-style light nautical map with sailed track (cyan), planned
  route (dashed purple), waypoint & MOB markers, recenter & layer controls.
- **Log** — day-grouped rich entries (position, heading, speed, sail %, wind,
  free-text), category filters, and an **Audio Log** for position-tagged voice notes.
- **Vessel & Crew** — boat profile, crew roster, engine/maintenance log (SwiftData).
- **More** — equipment list, service notes, season log, compass deviation table,
  statistics.
- **Safety** — press-and-hold MOB with a full-screen search (timer, range, bearing,
  homing compass) and an **Anchor Watch** (radius, drift circle, max-deviation alarm).
- **Statistics** — track map, speed chart (Swift Charts), propulsion breakdown donut.
- **Widgets & Live Activity** — Active-Voyage (small/medium/large/Lock Screen),
  Maintenance and Logbook-streak widgets; Dynamic Island Live Activity for the
  active voyage.
- **Themes** — Day / Night / System (neutral Apple-style dark).
- **Localization** — English + Russian (String Catalog), device-default.
- **Unit tests** — navigation math, coordinate formatting, voyage recorder,
  anchor watch, MOB, and seed data.

### Marked "Coming soon" (visible, disabled)
- PDF/CSV logbook export
- Maintenance auto-reminders / scheduling
- CloudKit sync
- Animated route replay

[Unreleased]: https://github.com/ipostatos/Skipper-Logbook/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/ipostatos/Skipper-Logbook/releases/tag/v0.9.0
