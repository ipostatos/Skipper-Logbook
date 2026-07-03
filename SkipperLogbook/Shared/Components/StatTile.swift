import SwiftUI

/// A labelled instrument value with an SF Symbol — the atom of the stats grid
/// ("LOGGED DISTANCE / 21m 22s", "ENGINE HOURS / 39.7 h"). Value uses rounded
/// tabular numerals so columns line up.
struct StatTile: View {
    @Environment(\.appTheme) private var theme

    let symbol: String
    let label: LocalizedStringKey
    let value: String
    var unit: String? = nil
    var tint: Color? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(tint ?? theme.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .instrumentLabel(theme.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(AppFont.statNumeral)
                        .foregroundStyle(theme.ink)
                    if let unit {
                        Text(unit)
                            .font(AppFont.footnote)
                            .foregroundStyle(theme.inkSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A responsive grid of `StatTile`s (three columns like the mockups).
struct StatGrid: View {
    let tiles: [StatTileData]
    var columns: Int = 3

    var body: some View {
        let layout = Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: columns)
        LazyVGrid(columns: layout, alignment: .leading, spacing: Spacing.lg) {
            ForEach(tiles) { tile in
                StatTile(symbol: tile.symbol, label: tile.label,
                         value: tile.value, unit: tile.unit, tint: tile.tint)
            }
        }
    }
}

struct StatTileData: Identifiable {
    let id = UUID()
    let symbol: String
    let label: LocalizedStringKey
    let value: String
    var unit: String? = nil
    var tint: Color? = nil
}

#Preview("Stat grid") {
    StatGrid(tiles: [
        .init(symbol: "point.topleft.down.to.point.bottomright.curvepath", label: "Logged", value: "21.4", unit: "nm"),
        .init(symbol: "clock", label: "Underway", value: "10d 2h"),
        .init(symbol: "circle.dashed", label: "Remaining", value: "186.2", unit: "nm"),
        .init(symbol: "water.waves", label: "Avg speed", value: "7.2", unit: "kn"),
        .init(symbol: "engine.combustion", label: "Engine", value: "39.7", unit: "h"),
        .init(symbol: "drop", label: "Fuel", value: "198.6", unit: "L")
    ])
    .padding()
    .environment(\.appTheme, .paper)
}
