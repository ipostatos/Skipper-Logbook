import SwiftUI

extension Binding {
    /// Unwraps an optional binding to a non-optional one, substituting `defaultValue`
    /// for `nil`. Handy for editing optional model fields in `TextField`s.
    static func unwrap<T>(_ source: Binding<T?>, default defaultValue: T) -> Binding<T> {
        Binding<T>(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}

extension Binding where Value == String {
    /// Bridges an optional `String?` model field to a `TextField`-friendly binding,
    /// treating empty input as `nil`.
    static func optionalText(_ source: Binding<String?>) -> Binding<String> {
        Binding<String>(
            get: { source.wrappedValue ?? "" },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
