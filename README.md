# Skipper Logbook ⛵️ `BETA`

> Digital ship's logbook, voyage tracking, maintenance & safety for captains.
> Судовой журнал, трекинг перехода, техучёт и безопасность для капитанов.

Skipper Logbook is a native **iOS** app (SwiftUI + SwiftData) designed to feel like a
built-in iOS app — calm, bright, Apple-native ("Liquid Nautical"): Health/Fitness-style
metrics, an Apple-Maps-style light nautical map, a Voice-Memos-style audio log, and
SF Symbols throughout. It turns the paper logbook into a live digital one.

It is a **helper logbook**, not a certified navigation system — it does not replace
Navionics/ECDIS.

---

## What it does

- **Today** — a contextual home: start a voyage, or when recording see live course,
  speed, distance, ETA, boat-state tiles (engine / sails % / anchor) and one-tap MOB.
- **Map** — light nautical map with your sailed track (cyan), planned route (dashed
  purple), waypoint & MOB markers, recenter & layer controls.
- **Log** — a day-grouped logbook of rich entries (position, heading, speed, sail %,
  wind, free-text notes), category filters, and an **Audio Log** for voice notes tied
  to your position.
- **Vessel** — boat profile (registration, MMSI, dimensions, engine, tank), crew, and
  the engine/maintenance log.
- **More** — equipment list, service notes, season log, compass deviation table,
  statistics.
- **Safety** — press-and-hold **MOB** with a full-screen search (timer, range, bearing,
  homing compass) and an **Anchor Watch** (drop anchor, set radius, drift circle,
  max-deviation alarm).
- **Statistics** — track map, speed chart (Swift Charts), and a propulsion breakdown
  (Engine / Sails / Sails & Engine / Idle) with a donut.
- **Widgets & Live Activity** — Active-Voyage (small / medium / large / Lock Screen),
  Maintenance and Logbook-streak widgets, plus a Dynamic Island Live Activity for the
  active voyage.

---

## Status

**BETA.** Live features are real (GPS recording, logbook, map, vessel/crew, MOB, anchor
watch, audio log, statistics, widgets, Live Activity). Marked **Coming soon** in-UI:
PDF/CSV export, maintenance auto-reminders/scheduling, CloudKit sync, animated route
replay.

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

## Requirements & getting started

- **macOS** with **Xcode 15+** (Swift 5.9, iOS 17 SDK)
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
(Location, NavigationMath, Persistence, Theme, Widget, Permissions, Export-stub),
`Shared/` (SwiftData Models, DesignSystem, Components, Extensions, Widget snapshot),
`Features/` (one folder per screen). `SkipperWidgets/` is the widget extension; the two
`Shared/Widget/*.swift` snapshot/attributes files are shared with it via an App Group.
