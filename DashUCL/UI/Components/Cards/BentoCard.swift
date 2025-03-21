import SwiftUI

/// A modern card component that adapts to both light and dark modes
/// following Apple's Human Interface Guidelines for iOS 18
struct BentoCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                colorScheme == .dark
                    ? Color(uiColor: UIColor(white: 0.18, alpha: 1.0))
                    : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.4)
                    : .black.opacity(0.05),
                radius: colorScheme == .dark ? 12 : 8,
                x: 0,
                y: colorScheme == .dark ? 6 : 4
            )
    }
}

#Preview {
    Group {
        BentoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample Card")
                    .font(.title2)
                    .bold()
                Text("This is a sample card to demonstrate the BentoCard component.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .preferredColorScheme(.light)

        BentoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample Card")
                    .font(.title2)
                    .bold()
                Text("This is a sample card to demonstrate the BentoCard component.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}
