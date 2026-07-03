# 02 — Design System

Source of truth in code: `SkipperLogbook/Shared/DesignSystem/` (+ `Shared/Components/`).
The mockups in `docs/design/` are references only.

## Tokens

### Color (light theme — matches approved palette exactly)

| Role | Token (`AppTheme.light`) | Value |
|---|---|---|
| Background | `background` | `#F7F8FB` |
| Card | `surface` / `surfaceElevated` | `#FFFFFF` |
| Ocean Blue (accent) | `blue` | `#3B6CFF` |
| Sea Cyan (track) | `cyan` | `#28C7D8` |
| Route Purple | `purple` | `#6E6AF8` |
| Sail Green | `green` | `#39D98A` |
| Engine Orange | `orange` | `#FFB340` |
| MOB Red | `danger` | `#FF3B30` |
| Text Main | `ink` | `#111827` |
| Text Secondary | `inkSecondary` | `#8A93A5` |
| Hairline stroke | `hairline` | `#ECEEF3` |

Dark theme (`AppTheme.dark`) uses brightened accents for contrast — intentional,
neutral Apple-style dark, NOT a marine cockpit. Day/Night/System via `ThemeManager`.

### Typography (`AppFont`)

SF Pro; SF Pro Rounded + tabular/monospaced numerals for instruments:
`display`, `numeral`, `headingNumeral` (56pt), `gaugeNumeral` (30pt),
`statNumeral` (22pt), `mono` (coordinates), `instrumentLabel` (uppercase tracked).
All respect Dynamic Type.

### Spacing & shape (`Spacing`, theme radii)

xxs 4 · xs 8 · sm 12 · md 16 · lg 20 · xl 24 · xxl 32; `pageMargin` 20;
`tabBarClearance` 96. Corner radius 22 (cards) / 16 (small). `CardShadow` = the
soft "liquid glass" shadow — never deep shadows.

## Component inventory (requested name → actual)

| Concept | Component in code |
|---|---|
| GlassCard | `Card` (`Components/Card.swift`) |
| MetricCard | `StatTile` / `StatGrid` |
| CircularMetric | `RingGauge`, `ArcGauge`, `CompassDial`, `CourseArc` |
| StatusPill | `StatusChip` (+ `StatusChipRow`) |
| BetaBadge | `BetaBadge` (`Components/Badges.swift`) |
| EventButton | `QuickActionButton` |
| MOBButton | `MOBButton` (`Features/Safety/SafetyView.swift`) — hold 0.7 s + haptic |
| TimelineRow | `LogEventRow` |
| AudioWaveformPreview | `WaveformView` |
| MapFloatingButton | `mapButton(_:action:)` in `MapView` |
| PermissionCard | `PermissionCard` (`Components/PermissionCard.swift`) |
| EmptyStateView | `EmptyStateView` |
| ComingSoonBadge | `ComingSoonBadge` + `.comingSoon()` modifier |

When adding a screen, compose from these before writing anything new.

## Rules

- One main accent per screen; MOB red **only** for emergency/danger/recording-stop.
- Thin `hairline` strokes on cards for sunlight readability; avoid low-contrast
  text on glass.
- Tabular numerals for every metric; units in `instrumentLabel` style.
- Empty, loading, permission-denied and error states are part of every screen's
  definition — use `EmptyStateView` / `PermissionCard`.
- Unfinished = `.comingSoon()`. No exceptions.
- New user-facing strings go into `Resources/Localizable.xcstrings` (EN + RU).
