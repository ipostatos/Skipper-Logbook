# Changelog

All notable changes to Skipper Logbook are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Weather screen** (More → Weather): manual wind/sea observations from the log;
  forecast & tides are labeled Coming soon — no fake live data.
- **Tap-to-set waypoint** on the Map during an active voyage — lights up the route
  line, waypoint marker, next-waypoint card, ETA and remaining distance.
- **Hold-to-activate MOB control** on the Map's floating buttons.
- **CSV & GPX export** per voyage from the voyage detail screen (share sheet).
- **Audio note tags** (Weather / Engine / Sails / Crew / Issue) plus speed & course
  metadata on every note.
- **Voice notes in the Logbook timeline**, interleaved chronologically.
- **Anchor drag alarm**: haptics + alert sound + local notification, once per
  excursion; anchor down/up and drag alarms are logged.
- **Today smart states**: anchored card while the watch runs, red MOB-active banner,
  and a location-permission guidance card when access is denied.
- **Create vessel** flow from the empty Vessel screen.
- Vessel: water tank capacity and free-form notes.
- Manual log entry button in the Logbook toolbar.

### Changed
- **No demo data on first launch** — the app starts empty; the demo fleet is
  dev-only via the `--seed-demo` launch argument (previews/tests unaffected).
- MOB triggers and resolutions are now logged from the engine, identically on all
  paths (Today, Safety, Quick Actions, Map).
- Background-tracking toggle now requests Always authorization and explains itself
  while the upgrade is pending.
- Engine save failures are logged (os.Logger) instead of silently swallowed.

### Fixed
- Unit-system picker no longer pretends to work (disabled + Coming soon until real).
- "Transcribe later" tile in Audio Log is now labeled Coming soon.
- **MOB without a GPS fix** now still records the incident time in the logbook and
  explains the missing position instead of opening an empty search screen.
- **All MOB controls are hold-to-activate** (Today card and Quick Actions tile
  included) with one shared hold duration — no accidental tap can fire an MOB.
- Re-triggering MOB while one is active keeps the original point and writes no
  duplicate logbook entry.
- New `MOB resolved` and `Anchor drag alarm` event types — the Logbook's Safety
  filter now shows the full incident timeline.
- Background-tracking preference persists across launches; while an anchor watch
  or MOB is active, background location stays on regardless of the toggle (with
  Always access), and the watch screen warns when notifications are denied.
- Voyage exports are generated at share time (never a stale view-appear snapshot)
  into unique paths, so same-named voyages can't overwrite each other.
- Voice notes store true course over ground (not heading) and are searchable by
  their tags.
- CI: pinned the XcodeGen project format for Xcode 15.x and corrected
  `SWIFT_VERSION` to a valid language mode (5.0).
- Swift 5.10 actor-isolation: `@MainActor` singletons are now built inside the
  App's `@MainActor` init (not as `@State` default values), and
  `AudioRecorderController` gained a `nonisolated` init.

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
