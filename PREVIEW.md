# Preview without a Mac 🖥️→📱

You don't need Xcode or a Mac to see the app. A GitHub Actions workflow
([`.github/workflows/preview.yml`](.github/workflows/preview.yml)) builds
Skipper Logbook on a macOS runner, drives an **iPhone 16 simulator** through
every headline screen, captures screenshots, and uploads them — together with a
runnable simulator build — as downloadable artifacts.

## How to run it

The workflow runs automatically on every push to `main` (and `preview/**` /
`claude/**` branches). You can also start it by hand:

1. Open the repo on GitHub → **Actions** tab.
2. In the left sidebar pick **“Preview (screenshots & simulator build)”**.
3. Click **Run workflow** → choose a branch → **Run workflow**.

Each run takes roughly 10–15 minutes.

## Where to download the results

1. GitHub → **Actions** → open the latest **“Preview (screenshots & simulator
   build)”** run.
2. Scroll to the **Artifacts** box at the bottom of the run summary page.
3. Download either artifact:

| Artifact | Contents |
|---|---|
| **`screenshots`** | PNGs of all eight screens (see list below) |
| **`simulator-app`** | `SkipperLogbook-Simulator.zip` — a zipped iOS-Simulator `.app` |

The run's **Summary** page also lists every captured screenshot filename and the
download instructions inline.

> Artifacts are retained for **30 days**. Re-run the workflow any time to refresh.

## The eight screenshots

| File | Screen |
|---|---|
| `01-Today.png` | Today / Smart Dashboard |
| `02-AudioLog.png` | Audio Log |
| `03-Map.png` | Map & Route |
| `04-Logbook.png` | Logbook Timeline |
| `05-Vessel.png` | Vessel |
| `06-Weather.png` | Weather |
| `07-MOB-Emergency.png` | Emergency MOB search |
| `08-Settings.png` | Settings / More |

The app is launched with demo data (`--seed-demo`) so the screens have realistic
content, and with `--seed-mob-active` so the emergency MOB search renders without
a live GPS fix. These flags are **development-only** — real users always start
with an empty logbook.

## Open it in a browser (Appetize.io)

The `simulator-app` artifact is an Appetize-compatible zipped simulator build.

**Automatic (recommended).** The workflow uploads the build to Appetize on every
run **when a repository secret named `APPETIZE_API_TOKEN` is set** — then the run's
**Summary** page shows an *Open in browser (Appetize)* link. To enable it:

1. Get an API token from Appetize → *Account → API*.
2. In GitHub: **Settings → Secrets and variables → Actions → New repository
   secret**, name it exactly `APPETIZE_API_TOKEN`, paste the token.
3. Re-run the workflow. Without the secret, this step is skipped and the run
   still succeeds (screenshots + artifact only).

> 🔒 Never paste the token into code, chat, or commits — only into GitHub
> Secrets. If it's ever exposed, regenerate it in Appetize.

**Manual.** You can always upload the artifact yourself: download
`SkipperLogbook-Simulator.zip`, go to <https://appetize.io/upload>, and upload it
as **Platform: iOS**, **Type: Simulator**.

## How the screenshots are captured (for maintainers)

- `SkipperUITests/ScreenshotTests.swift` is a UI-test target that taps through
  the app using stable **accessibility identifiers** (`tab.today`, `tab.map`,
  `more.tile.weather`, `today.mob_active_banner`, …) and attaches each
  `XCUIScreenshot` with `.keepAlways`.
- The `SkipperScreenshots` scheme runs only that target.
- `scripts/extract-screenshots.sh` pulls the named PNGs out of the
  `.xcresult` bundle (via `xcparse`, with an `xcresulttool` fallback).

If you add or rename a screen, update the identifiers and the test's navigation
steps accordingly.
