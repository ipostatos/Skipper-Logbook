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
- **Safety-critical fix fan-out moved out of the view layer** — a new
  `FixCoordinator` (built in the app's init) routes every accepted GPS fix to
  the recorder, anchor watch and MOB engines and keeps the background-location
  override enforced. Previously this lived in `RootView.onChange`, so the
  anchor alarm depended on a SwiftUI scene being alive.
- **Anchor drag alarm now repeats** every 20 s while the boat stays outside the
  radius (sound + haptic + a fresh time-sensitive notification each time; the
  logbook still gets exactly one entry per excursion), and posts an
  "anchor holding again" notification once the boat is back inside 80% of the
  radius. Notifications use the Time Sensitive interruption level (entitlement
  added) so Focus/silenced delivery can't swallow them.
- **WidgetKit reload budget respected** — the Live Activity still updates on
  every fix (unbudgeted), but the App-Group snapshot + `reloadAllTimelines()`
  now run only on voyage events (start/stop/waypoint) and at most every
  10 minutes, instead of on every fix with three full-table fetches.
- **Track recording no longer degrades over long voyages** — the recorder keeps
  the last point in memory instead of re-sorting the whole track on every fix,
  and batches track-point saves (every 10 points / 12 s; events still save
  immediately; stop flushes).
- **GPS fix quality is now filtered** — fixes with invalid or > 100 m
  horizontal accuracy (or stale cached timestamps) are dropped; only ≤ 50 m
  fixes feed the integrated distance, so a moored boat can't "sail" phantom
  metres out of accuracy noise.
- **No demo data on first launch** — the app starts empty; the demo fleet is
  dev-only via the `--seed-demo` launch argument (previews/tests unaffected).
- MOB triggers and resolutions are now logged from the engine, identically on all
  paths (Today, Safety, Quick Actions, Map).
- Background-tracking toggle now requests Always authorization and explains itself
  while the upgrade is pending.
- Engine save failures are logged (os.Logger) instead of silently swallowed.

### Fixed
- **Live Activity survives force-quits honestly**: on launch the controller
  re-attaches to (or ends) activities that outlived the process — no more
  orphaned/duplicate Lock Screen activities; every update carries a stale date,
  and the Live Activity/Dynamic Island show "NO DATA" instead of presenting a
  frozen speed as live after a dropout.
- **Widgets detect staleness**: the home/lock-screen widgets now read the
  snapshot's `updatedEpoch` and show "No recent data" (speed "—") when the app
  stopped publishing more than 15 minutes ago while still marked recording.
- **Engine state survives a relaunch mid-voyage** — the recorder restores the
  engine-on flag from the logbook, so engine hours keep accruing and the next
  toggle can't write a second consecutive `engineOn`.
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
