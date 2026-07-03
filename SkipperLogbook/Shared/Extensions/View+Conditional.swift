import SwiftUI

extension View {
    /// Applies a transform only when `condition` is true.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Marks a feature as not-yet-available: dims + disables it and overlays a
    /// "Coming soon" badge in the top-trailing corner. Used for export, sync, etc.
    func comingSoon(_ on: Bool = true, alignment: Alignment = .topTrailing) -> some View {
        self
            .disabled(on)
            .opacity(on ? 0.5 : 1)
            .overlay(alignment: alignment) {
                if on { ComingSoonBadge() }
            }
    }
}
