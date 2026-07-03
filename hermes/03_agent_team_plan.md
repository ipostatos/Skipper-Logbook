# 03 — Hermes Agent Team Plan

How work on this repo is split when delegating to internal agents (or when the
solo developer wears these hats himself). Each agent's scope maps to concrete
folders so two agents never edit the same file blindly.

## 1. Hermes Coordinator
- Owns `hermes/04_mvp_execution_plan.md` (task order, dependencies, acceptance
  criteria) and this folder.
- Gatekeeps scope: anything not in the MVP plan goes to the roadmap, not the diff.
- Reviews every change against `01_product_direction.md` non-negotiables.

## 2. Product / UX Agent
- Scope: screen flows and state matrices for Today, Audio Log, Map, Logbook,
  Vessel, Weather, Safety/MOB, Settings/More.
- Deliverable: every screen defines empty / loading / permission-denied / error
  states before implementation starts.

## 3. Design System Agent
- Scope: `Shared/DesignSystem/`, `Shared/Components/`.
- Owns tokens and the component inventory (`02_design_system.md`). Rejects
  screen-local styling that duplicates a component.

## 4. iOS Architecture Agent
- Scope: `App/` (entry, `AppRouter`, `RootView`), dependency wiring
  (`@Observable` engines injected via `.environment`).
- Guards: no view > ~350 lines, feature folders, engines never import SwiftUI.

## 5. Data / Persistence Agent
- Scope: `Shared/Models/`, `Core/Persistence/`.
- Rules: SwiftData changes must be additive & lightweight-migratable until a
  `VersionedSchema` exists; seed/demo data only via `--seed-demo` launch arg,
  previews (`PreviewData`) and tests; every new model registered in
  `PersistenceController.schema`.

## 6. Location / Navigation Agent
- Scope: `Core/Location/`, `Core/NavigationMath/`.
- Rules: nautical units by default; missing GPS degrades gracefully (nil, not 0);
  manual logbook must work with location denied.

## 7. Map Agent
- Scope: `Features/Map/`.
- Owns: position, track (cyan), route (dashed purple), waypoint, MOB marker (red),
  NextWaypointCard, floating controls (center / layers / add-waypoint / MOB).
- Visual rule: Apple-Maps-light-nautical, never Navionics.

## 8. Audio Log Agent
- Scope: `Features/Voice/`, `VoiceNote` model.
- Owns: recording, playback, waveform, tags (Weather/Engine/Sails/Crew/Issue),
  GPS+speed+course metadata, timeline integration. Transcription stays
  `.comingSoon()` until real.

## 9. MOB / Safety Agent
- Scope: `Features/Safety/`, `Core/Location/MOBEngine.swift`,
  `AnchorWatchEngine.swift`.
- Rules: long-press + haptic activation; every MOB trigger/resolve writes a
  logbook event (enforced in the engine, not in views); anchor watch alarms with
  haptic + sound + local notification; MOB never hidden.

## 10. Widgets / Live Activity Agent
- Scope: `SkipperWidgets/`, `Shared/Widget/`, `Core/Widget/`.
- Contract: widgets read only `VoyageSnapshot` via the App Group; never SwiftData.

## 11. QA / Testing Agent
- Scope: `SkipperLogbookTests/`, `.github/workflows/ci.yml`.
- Required coverage: navigation math, voyage/log-entry creation, audio metadata,
  MOB event creation + logbook logging, persistence restart, export formats,
  permission-denied states.

## 12. Documentation Agent
- Scope: `README.md`, `SETUP.md`, `CHANGELOG.md`, `hermes/`.
- Keeps the safety disclaimer in README + onboarding; updates known limitations
  and roadmap after every milestone.
