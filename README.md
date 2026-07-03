# Skipper Logbook ⛵️ `BETA`

> Digital ship's logbook, voyage tracking, maintenance & safety for captains.
> Судовой журнал, трекинг перехода, техучёт и безопасность для капитанов.

Skipper Logbook is a native **iOS** app (SwiftUI + SwiftData) designed to feel like a
built-in iOS app — calm, bright, Apple-native ("Liquid Nautical"): Health/Fitness-style
metrics, an Apple-Maps-style light nautical map, a Voice-Memos-style audio log, and
SF Symbols throughout. It turns the paper logbook into a live digital one.

> **Safety disclaimer.** Skipper Logbook is a digital logbook and voyage tracking
> assistant. It is not a certified navigation system and must not be used as the
> sole source of navigation or safety decisions. It does not replace Navionics/ECDIS,
> paper charts, seamanship or emergency procedures.

---

## What it does

- **Today** — a contextual home: start a voyage, or when recording see live course,
  speed, distance, ETA, boat-state tiles (engine / sails % / anchor) and one-tap MOB.
- **Map** — light nautical map with your sailed track (cyan), planned route (dashed
  purple), waypoint & MOB markers, recenter & layer controls, tap-to-set waypoint
  during a voyage, and a hold-to-activate MOB control.
- **Log** — a day-grouped logbook of rich entries (position, heading, speed, sail %,
  wind, free-text notes) with voice notes interleaved in the timeline, category
  filters, and an **Audio Log** for tagged (Weather/Engine/Sails/Crew/Issue) voice
  notes tied to your position, speed and course.
- **Weather** — manual observations from your own log entries; live forecast and
  tides are honestly labeled Coming soon (no fake live data).
- **Vessel** — boat profile (registration, MMSI, dimensions, engine, tank), crew, and
  the engine/maintenance log.
- **More** — equipment list, service notes, season log, compass deviation table,
  statistics.
- **Safety** — press-and-hold **MOB** with a full-screen search (timer, range, bearing,
  homing compass); every MOB trigger/resolution is written to the logbook. **Anchor
  Watch** (drop anchor, set radius, drift circle) fires a real drag alarm — haptics,
  alert sound and a local notification.
- **Export** — share any voyage as **CSV** (logbook rows) or **GPX 1.1** (track +
  waypoints) from the voyage detail screen.
- **Statistics** — track map, speed chart (Swift Charts), and a propulsion breakdown
  (Engine / Sails / Sails & Engine / Idle) with a donut.
- **Widgets & Live Activity** — Active-Voyage (small / medium / large / Lock Screen),
  Maintenance and Logbook-streak widgets, plus a Dynamic Island Live Activity for the
  active voyage.

---

## Status

**BETA.** Live features are real (GPS recording, logbook, map + waypoints, vessel/crew,
MOB, anchor watch with drag alarm, audio log with tags, CSV/GPX export, statistics,
widgets, Live Activity). Marked **Coming soon** in-UI: PDF export, voice transcription,
unit-system switching, maintenance auto-reminders/scheduling, CloudKit sync, live
weather/tides, animated route replay. The app starts empty — no demo data ships to
real users (developers can seed a demo fleet with the `--seed-demo` launch argument).

Project planning & agent context live in [`hermes/`](hermes/00_project_context.md).

---

## Design language — "Liquid Nautical"

Light, bright, one strong accent per screen; **MOB red is the only alarm colour.**

| Role | Light |
|---|---|
| Background | `#F7F8FB` |
| Card | white / glass |
| Primary Blue | `#3B6CFF` |
| Sea Cyan | `#28C7D8` |
| Route Purple | `#6E6AF8` |
| Sail Green | `#39D98A` |
| Engine Orange | `#FFB340` |
| MOB Red | `#FF3B30` |
| Text | `#111827` / `#8A93A5` |

SF Pro for text/headings, SF Pro Rounded tabular numerals for instruments. Day / Night /
System themes (neutral Apple-style dark).

---

## Preview without a Mac 🖥️→📱

No Mac? A GitHub Actions workflow builds the app, drives an iPhone simulator
through every screen, and uploads **screenshots** plus a **runnable simulator
build** as downloadable artifacts. See **[`PREVIEW.md`](PREVIEW.md)** for exactly
where to download them (and how to open the app in a browser via Appetize.io).

---

## Requirements & getting started

- **macOS** with **Xcode 16+** (iOS 18 SDK — its `View`-is-`@MainActor` isolation
  model is what the code is written against; the app still targets iOS 17.0)
- [XcodeGen](https://github.com/yonyz/XcodeGen)

```bash
brew install xcodegen
cd "Skipper Logbook"
xcodegen generate
open SkipperLogbook.xcodeproj
```

See [`SETUP.md`](SETUP.md) for signing, the App Group / Live Activity setup, and the full
test checklist.

## Tech stack

Swift · SwiftUI · SwiftData · MapKit · CoreLocation · AVFoundation · WidgetKit ·
ActivityKit · Swift Charts · String Catalog (EN + RU)

## Architecture

MVVM-ish SwiftUI. Under `SkipperLogbook/`: `App/` (entry, router, root shell), `Core/`
(Location, NavigationMath, Persistence, Theme, Widget, Permissions, Export — CSV/GPX),
`Shared/` (SwiftData Models, DesignSystem, Components, Extensions, Widget snapshot),
`Features/` (one folder per screen). `SkipperWidgets/` is the widget extension; the two
`Shared/Widget/*.swift` snapshot/attributes files are shared with it via an App Group.
