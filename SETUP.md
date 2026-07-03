# Setup — Skipper Logbook

This project is authored as source + an [XcodeGen](https://github.com/yonyz/XcodeGen)
spec. You generate the `.xcodeproj` on a Mac and open it in Xcode 16+ (iOS 18 SDK; the app targets iOS 17.0).

## 1. Generate & open

```bash
brew install xcodegen           # once
cd "Skipper Logbook"
xcodegen generate               # creates SkipperLogbook.xcodeproj
open SkipperLogbook.xcodeproj
```

This creates three targets:

- **SkipperLogbook** — the app
- **SkipperWidgets** — WidgetKit extension (home/lock-screen widgets + Live Activity)
- **SkipperLogbookTests** — unit tests

## 2. Signing & capabilities (once)

1. Select the **SkipperLogbook** target → *Signing & Capabilities* → set your **Team**.
2. Do the same for **SkipperWidgets**.
3. Both targets already declare the **App Group** `group.com.skipperlogbook.app`
   (via `.entitlements` files). In *Signing & Capabilities* confirm the App Group is
   checked on **both** targets. If Xcode complains the group doesn't exist, click **+**
   under App Groups and add `group.com.skipperlogbook.app` (it will be created on your
   account), then make sure both targets reference the same one.
4. The app declares `NSSupportsLiveActivities = YES` (Info.plist) so Live Activities work.

> If you use your own bundle prefix, change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`,
> the App Group id in the two `.entitlements` files, and `AppGroup.identifier` in
> `SkipperLogbook/Shared/Widget/VoyageSnapshot.swift` — then re-run `xcodegen generate`.

## 3. Run

- Pick an **iPhone 16 (iOS 17+)** simulator, select the **SkipperLogbook** scheme, ⌘R.
- Grant location when prompted. In the simulator, drive movement with
  **Features ▸ Location ▸ Freeway Drive** to see the track, speed and heading update.

## 4. Manual test checklist

- [ ] **Today** shows the Start-voyage CTA when idle; after starting, it flips to the
      live course arc + speed/waypoint sparkline cards + recording banner.
- [ ] **Start / Stop recording** creates a voyage, accrues distance while "driving".
- [ ] **Map** draws the cyan track + dashed purple route to the waypoint; recenter & the
      layers button work; the map is the light nautical style (not dark).
- [ ] **Log** groups entries by day; the filter chips (All/Nav/Engine/Sails/Safety/Audio)
      filter; the mic button opens **Audio Log**; recording a note requires mic permission
      and the note appears in the Audio filter.
- [ ] **Vessel** shows the seeded "Sea Breeze"; Edit persists across relaunch; links to
      Crew & Engine log work.
- [ ] **More** tiles open Equipment, Service notes, Season log, Deviation, Statistics.
- [ ] **MOB**: tapping MOB on Today saves a point and opens the full-screen search
      (timer, distance, bearing, homing arrow). "Recovered" ends it.
- [ ] **Anchor watch** (via + or Safety): drop anchor, set radius, drift circle updates,
      max deviation tracked, alarm state when outside radius.
- [ ] **Themes**: Settings ▸ Appearance switches Day / Night / System live.
- [ ] **Localization**: set the simulator to Russian → UI switches to RU.
- [ ] **Widgets**: while a voyage records, add the **Active Voyage** widget (small/medium/
      large) and confirm it shows live speed/course/distance; add the Lock-Screen
      rectangular widget; the **Maintenance** and **Logbook** widgets show data.
- [ ] **Live Activity**: while recording, the Dynamic Island / Lock Screen shows the
      active voyage (route, speed, course, ETA, progress). Stopping ends it.
- [ ] **⌘U** runs the unit tests (NavigationMath, coordinate formatting, recorder,
      anchor watch, MOB, seeding) — all green.

## No-XcodeGen fallback

If you'd rather not install XcodeGen: create a new **iOS App** in Xcode (SwiftUI, iOS 17),
delete its template files, drag the `SkipperLogbook/` groups in, add a **Widget Extension**
target, drag the `SkipperWidgets/` files + the two `Shared/Widget/*.swift` files into it,
then set the Info.plist keys and App Group capability listed above. The XcodeGen path is
strongly recommended — it wires all of this deterministically.

## Assumptions

- Deployment target **iOS 17.0**, Swift language mode 5, **Xcode 16+** (the SDK's `View`-is-`@MainActor` isolation is assumed by the code).
- Language mode 5 (strict concurrency off) to compile cleanly on first build.
- CloudKit is intentionally **off** for BETA (models stay simple).
