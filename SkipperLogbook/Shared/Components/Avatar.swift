import SwiftUI

/// A circular crew avatar: photo if present, otherwise a tinted monogram.
struct Avatar: View {
    @Environment(\.appTheme) private var theme

    var imageData: Data?
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.accentSoft)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(theme.hairline, lineWidth: 0.5))
    }
}

#Preview("Avatars") {
    HStack {
        Avatar(imageData: nil, initials: "АБ")
        Avatar(imageData: nil, initials: "МК", size: 56)
    }
    .padding()
    .environment(\.appTheme, .paper)
}
