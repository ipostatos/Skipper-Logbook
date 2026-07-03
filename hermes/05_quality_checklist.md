# 05 — Quality Checklist

Run before merging any milestone. (CI: build + tests on macos-14 + SwiftLint.)

## Build & tests
- [ ] `xcodegen generate` succeeds; project opens clean
- [ ] App target + widget extension build without warnings that matter
- [ ] All unit tests green (`SkipperLogbookTests`)
- [ ] SwiftLint clean (`swiftlint --strict`)

## Product principles
- [ ] No dead buttons: every enabled control does something; unfinished = `.comingSoon()`
- [ ] No fake data in production path (seed only via `--seed-demo`, previews, tests)
- [ ] Red used only for MOB / emergency / danger
- [ ] One main accent per screen; tabular numerals for metrics
- [ ] New strings localized in `Localizable.xcstrings` (EN + RU)

## State matrix (each screen)
- [ ] Empty state
- [ ] Location permission denied → app still usable, guidance shown (PermissionCard)
- [ ] Microphone permission denied → Audio Log explains, doesn't crash
- [ ] No active voyage / active voyage / anchored / MOB-active on Today
- [ ] Data survives app restart (voyage, events, notes, MOB, anchor session)

## Safety
- [ ] MOB reachable from Today, Safety, Quick Actions, Map — long press or
      explicit red control, haptic on trigger
- [ ] Every MOB trigger/resolve appears in the Logbook
- [ ] Anchor drag fires haptic + sound + local notification (once per excursion)
- [ ] Disclaimer visible in Onboarding + README

## Manual smoke (simulator, Freeway Drive / City Run)
- [ ] Start voyage → track draws on Map, Today shows live speed/course
- [ ] Set waypoint on Map → route line + NextWaypointCard + Today ETA appear
- [ ] Record voice note with tags → appears in Audio Log and Logbook timeline
- [ ] Trigger MOB (hold) → full-screen search, range/bearing update, resolve logs
- [ ] Drop anchor, walk outside radius → alarm fires
- [ ] Stop voyage → Voyage detail shows stats; CSV + GPX share sheet works
- [ ] Widgets/Live Activity show live data during recording
