import SwiftUI

/// The bottom navigation bar: Today · Map · [ + ] · Log · Vessel · More, with a
/// center gap where the floating + sits. Light glass with a hairline top edge.
struct CustomTabBar: View {
    @Environment(\.appTheme) private var theme
    @Binding var selection: AppTab

    // Split the five tabs so the center + sits between Map and Log.
    private var leading: [AppTab] { [.today, .map] }
    private var trailing: [AppTab] { [.log, .vessel, .more] }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leading) { tabButton($0) }
            Spacer().frame(width: 64)   // room for the floating +
            ForEach(trailing) { tabButton($0) }
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            theme.surfaceElevated
                .overlay(Rectangle().frame(height: 0.5).foregroundStyle(theme.hairline), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.snappy(duration: 0.2)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(tab.titleKey)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? theme.accent : theme.inkSecondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab.\(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// The round + button that floats above the tab bar to open quick actions.
struct FloatingActionButton: View {
    @Environment(\.appTheme) private var theme
    var symbol: String = "plus"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(
                        LinearGradient(colors: [theme.blue, theme.purple],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: theme.blue.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick actions")
    }
}

#Preview("Tab bar") {
    struct Demo: View {
        @State var sel: AppTab = .today
        var body: some View {
            VStack {
                Spacer()
                CustomTabBar(selection: $sel)
            }
            .environment(\.appTheme, .light)
        }
    }
    return Demo()
}
