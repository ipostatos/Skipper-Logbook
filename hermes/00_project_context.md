# 00 — Project Context & Current State Report

> Hermes context folder. Read this first. Updated: 2026-07-03 (full repo audit).

Skipper Logbook is a native iOS 17 app (SwiftUI + SwiftData, XcodeGen, no external
dependencies) implementing a captain's digital logbook in the **Liquid Nautical
Minimalism** design language. Solo-developer project; prefer boring, maintainable
solutions over clever abstractions.

## Current State Report

### What exists (real, working)

- **Architecture** — clean feature-folder layout: `App/` (entry, router, root tab
  shell), `Core/` (Location, NavigationMath, Persistence, Export, Permissions,
  Theme, Widget), `Shared/` (Models, DesignSystem, Components, Extensions),
  `Features/` (one folder per screen), `SkipperWidgets/` extension,
  `SkipperLogbookTests/`. No file exceeds ~310 lines.
- **Persistence** — SwiftData, on-disk container (`PersistenceController`),
  13 `@Model` types. Data persists across restarts.
- **Location stack** — real `CLLocationManager` (`LocationManager`), one live fix
  stream fanned out from `RootView` to three engines:
  `VoyageRecorder` (track points, distance integration with jitter/teleport
  rejection, engine time, ETA/remaining/bearing), `AnchorWatchEngine` (drift,
  max deviation, dragging flag), `MOBEngine` (persisted point, live range/bearing).
- **Navigation math** — pure, unit-tested haversine/bearing/cross-track/ETA/
  destination + DMS/DDM coordinate formatting. Nautical units correct (1852 m/NM).
- **Screens** — Today (start CTA / recording states), Map (MapKit, track polyline,
  MOB marker, layers/recenter), Logbook (day-grouped timeline, filters, manual
  entry), Audio Log (real AVAudioRecorder + playback + waveform + GPS metadata),
  Vessel/Crew (full CRUD), Maintenance (read-only), Statistics (Swift Charts),
  Safety (hold-to-MOB + full-screen search, anchor watch), Settings, Onboarding,
  More references (equipment/deviation/service notes/season log).
- **Widgets & Live Activity** — real WidgetKit + ActivityKit (small/medium/large/
  lock screen + Dynamic Island), data via App Group `VoyageSnapshot`.
- **Design system** — `AppTheme` light/dark; light palette matches the approved
  hexes exactly. Typography (SF rounded tabular numerals), Spacing tokens,
  ~20 reusable components.
- **Tests** — 21 XCTests: navigation math, coordinate formatting, recorder,
  anchor watch, MOB, seed data. CI on GitHub Actions (macos-15, Xcode 16.x,
  xcodegen → xcodebuild test, SwiftLint).
- **Docs** — README (with safety disclaimer), SETUP, CHANGELOG, templates.

### What was missing / broken at audit time (2026-07-03)

Fixed in the alignment pass (see `04_mvp_execution_plan.md` for details):

1. **Fake seed data in the production launch path** — a fabricated vessel, crew,
   voyages and MOB point were inserted into the real store on first launch.
2. **Waypoint/route subsystem unreachable** — nothing ever set
   `Voyage.destinationLat/Lon`, so the Map route line, waypoint marker,
   NextWaypointCard, Today ETA and "to waypoint" were permanently dead code.
3. **Anchor watch had no alarm** — `isDragging` only turned a label red.
4. **MOB logged to the logbook on only 1 of 3 trigger paths**; anchor down/up
   never logged.
5. **Dead controls** — background-tracking toggle could never activate
   (`.always` auth was never requested); unit-system picker had no effect.
6. **Audio Log** — no tags, no speed/course metadata, voice notes not interleaved
   in the Logbook timeline; "transcribe later" implied without a Coming Soon label.
7. **No Weather screen** at all.
8. **Export was a throwing stub** (MVP scope calls for basic CSV/GPX).
9. **No permission guidance** — location denied left dashes with no explanation.

### Still missing / deferred (honest Coming Soon)

- PDF export, CloudKit sync, transcription, maintenance add/auto-reminders,
  route replay, unit-system switching (imperial/metric), live weather API,
  tides, multi-waypoint routes, Vessel↔Voyage / MOB↔Voyage relationships,
  background GPS UX polish (blue-bar explanation), Apple Watch.

### What is fragile

- **SwiftData migrations** — no `VersionedSchema`/`SchemaMigrationPlan`;
  `PersistenceController` `fatalError`s on container failure. All model changes
  MUST stay lightweight-migratable (additive, **optional** properties only)
  until a versioned schema is introduced. See `04_mvp_execution_plan.md` §Migrations.
- **Anchor alarm with the phone locked** needs Always location — the safety
  override keeps fixes flowing only with that permission; the watch sheet says so.
- **Toolchain** — building requires the Xcode 16+ SDK (`View` is `@MainActor`
  there; view helper members rely on it). CI: macos-15 / Xcode 16.x /
  iPhone 16 simulator. The objectVersion normalization keeps the generated
  project readable by older Xcode, but sources won't compile below 16.
- Dev builds seeded before the `--seed-demo` gate keep their demo data
  (reinstall to reset); no real users existed before the gate.
- Engine `save()` failures are logged (os.Logger) but not surfaced to the UI.
- `DashboardReadout.toWaypointSpeedKn` is speed-over-ground, not true VMG
  (self-documented BETA shortcut).
- CI uses an iPhone 16 simulator without an OS pin (picks the newest runtime).

### What can be reused (don't reinvent)

- `Card`, `StatTile`, `StatusChip`, `RingGauge`/`ArcGauge`, `CompassDial`,
  `CourseArc`, `WaveformView`, `Sparkline`, `EmptyStateView`, `BetaBadge`,
  `ComingSoonBadge` + `.comingSoon()`, `PrimaryButton`, `QuickActionButton`,
  `AppHeader`, `CustomTabBar`/`FloatingActionButton`, `PermissionCard`.
- `NavigationMath`, `Units`, `CoordinateFormatting`, `Date+Formatting`.
- The `.comingSoon()` pattern is the ONLY sanctioned way to show unfinished
  features.

### What should not be touched yet

- The App Group / widget snapshot contract (`VoyageSnapshot`) — widgets and Live
  Activity depend on its Codable shape.
- `PersistenceController` schema list ordering & the two `fatalError`s — replace
  only together with a real versioned-migration plan.
- Theme structure (`AppTheme.light/.dark`) — palette is approved; don't fork it.
- Localization keys already in `Localizable.xcstrings` (EN + RU).

### Recommended implementation order (forward)

1. Versioned SwiftData schema + migration plan (before ANY release).
2. Unit-system support (thread `AppState.unitSystem` through formatters).
3. Maintenance add/edit UI + local-notification reminders.
4. PDF export (share-sheet, A5 logbook layout).
5. Background GPS UX (always-auth education screen) + battery profiling.
6. WeatherKit forecast behind the existing Weather screen (clearly labeled).
7. CloudKit sync (schema must be stable first).
