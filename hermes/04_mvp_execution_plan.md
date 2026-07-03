# 04 — MVP Execution Plan

Master plan for the alignment pass (2026-07-03) and the follow-up milestones.
Owner: Hermes Coordinator. Status legend: ✅ done in alignment pass · ⏳ next ·
🔮 roadmap.

## Alignment pass (this milestone)

Ordered by dependency; each item lists its acceptance criterion.

| # | Task | Files | Accept when | Status |
|---|---|---|---|---|
| 1 | Remove fake seed data from production launch; keep for previews/tests + `--seed-demo` dev launch arg | `App/SkipperLogbookApp.swift` | First real launch shows empty states, not "Sea Breeze" | ✅ |
| 2 | Fix background-tracking toggle (request `.always` when enabling) | `Core/Location/LocationManager.swift`, `Features/Settings/SettingsView.swift` | Toggle triggers the always-auth prompt; setting honoured when granted; hint shown when denied | ✅ |
| 3 | MOB always writes a logbook event (trigger + resolve), from the engine | `Core/Location/MOBEngine.swift`, `Features/Today/TodayView.swift` | All three MOB paths (Today, Safety, Quick Actions) produce exactly one `.mob` entry; resolve logs too | ✅ |
| 4 | Anchor watch: real alarm (haptic + sound + local notification) + `.anchorDown`/`.anchorUp` log events | `Core/Location/AnchorWatchEngine.swift` | Drag transition fires alarm once per excursion; start/stop logged | ✅ |
| 5 | Waypoint reachability: Map add-waypoint mode (tap to set destination) + MOB hold control on Map | `Features/Map/MapView.swift` | Route line, waypoint marker, NextWaypointCard, Today ETA all reachable in real use | ✅ |
| 6 | Audio Log tags (Weather/Engine/Sails/Crew/Issue) + speed/course metadata | `Shared/Models/VoiceNote.swift`, `Features/Voice/AudioLogView.swift` | Tags selectable at record time, persisted, shown in list | ✅ |
| 7 | Voice notes interleaved chronologically in Logbook timeline | `Features/Logs/LogbookView.swift` | Audio rows appear in day groups among events; Audio filter still works | ✅ |
| 8 | Today smart states: anchored card, MOB-active banner, live anchor chip, permission card | `Features/Today/TodayView.swift`, `Shared/Components/PermissionCard.swift` | Chip reflects real anchor watch; anchored card while watch active; red MOB banner reopens search; denied location shows guidance card | ✅ |
| 9 | Weather screen (manual observations + clearly-labeled Coming Soon forecast/tide) | `Features/Weather/WeatherView.swift`, `App/AppRouter.swift`, `App/RootView.swift`, `Features/More/MoreMenuView.swift` | Weather reachable from More; nothing fakes live data | ✅ |
| 10 | Real CSV + GPX export per voyage (PDF stays Coming Soon) | `Core/Export/ExportService.swift`, `Features/Voyage/VoyageDetailView.swift` | Share sheet delivers valid CSV of events + GPX 1.1 of track/waypoints | ✅ |
| 11 | Honest controls: unit-system picker → Coming Soon; transcribe tile → Coming Soon badge | `Features/Settings/SettingsView.swift`, `Features/Voice/AudioLogView.swift` | No control without effect remains enabled | ✅ |
| 12 | Vessel model completion: water capacity + notes (surfaced in edit/profile) | `Shared/Models/Vessel.swift`, `Features/Vessel/*` | Fields editable & persisted; additive migration only | ✅ |
| 13 | Engine save errors logged via `os.Logger` (no more silent `catch {}`) | 3 engine files | Failures visible in Console | ✅ |
| 14 | Tests for export, MOB/anchor logging, voice tags | `SkipperLogbookTests/` | New tests pass in CI | ✅ |
| 15 | CI runs on `claude/**` branches too | `.github/workflows/ci.yml` | Push to feature branch triggers build+test | ✅ |
| 16 | Docs: README/CHANGELOG reflect reality; Hermes folder committed | root, `hermes/` | This folder + updated docs in repo | ✅ |

## Migrations policy (critical, read before touching models)

There is no `VersionedSchema` yet. Until one exists:
- Only **additive** model changes: new properties must be optional or have
  default values; new relationships must be optional.
- Never rename or retype an existing stored property.
- `PersistenceController` crashes (`fatalError`) on container failure — a
  breaking schema change bricks existing installs.
- ⏳ Before the first public TestFlight: introduce `SchemaV1` +
  `SchemaMigrationPlan` and replace the `fatalError`s with a recovery path.

## Next milestone (⏳)

1. Versioned schema + migration plan (above).
2. Unit-system support end-to-end (kill the Coming Soon on the picker).
3. Maintenance add/edit + local-notification service reminders.
4. PDF export.
5. Always-authorization education flow for background GPS.

## Roadmap (🔮)

WeatherKit forecast + tides · multi-waypoint routes · Vessel↔Voyage and
MOB↔Voyage relationships · transcription (Speech framework) · CloudKit sync ·
Apple Watch · crew sharing · fleet/school mode · route replay animation ·
paid tier / StoreKit.
