import SwiftUI
import UIKit

/// Application Theme Constants
/// Provides unified colors, backgrounds and button styles
public struct ThemeConstants {
    // MARK: - Background Colors

    /// Main background color - Used for main view background
    public static var primaryBackground: Color {
        Color(.systemBackground)
    }

    /// Secondary background color - Used for cards, list items and other elements
    public static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }

    /// Group background color - Used for grouped list background
    public static var groupedBackground: Color {
        Color(.systemGroupedBackground)
    }

    /// Secondary group background color - Used for items within grouped lists
    public static var secondaryGroupedBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

    // MARK: - Button Styles

    /// Primary button style
    public struct PrimaryButtonStyle: ButtonStyle {
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }

    /// Secondary button style
    public struct SecondaryButtonStyle: ButtonStyle {
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(Color.accentColor)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }

    /// Danger button style (for delete, logout, etc.)
    public struct DangerButtonStyle: ButtonStyle {
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(configuration.isPressed ? 0.8 : 1.0))
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }

    /// Icon button style
    public struct IconButtonStyle: ButtonStyle {
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }

    // MARK: - Card Styles

    /// Standard card style modifier
    public static func standardCardModifier() -> some ViewModifier {
        return CardModifier(cornerRadius: 12)
    }

    /// Card modifier
    public struct CardModifier: ViewModifier {
        let cornerRadius: CGFloat

        public func body(content: Content) -> some View {
            content
                .background(ThemeConstants.secondaryBackground)
                .cornerRadius(cornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard card style
    public func standardCard() -> some View {
        self.modifier(ThemeConstants.standardCardModifier())
    }

    /// Apply primary button style
    public func primaryButtonStyle() -> some View {
        self.buttonStyle(ThemeConstants.PrimaryButtonStyle())
    }

    /// Apply secondary button style
    public func secondaryButtonStyle() -> some View {
        self.buttonStyle(ThemeConstants.SecondaryButtonStyle())
    }

    /// Apply danger button style
    public func dangerButtonStyle() -> some View {
        self.buttonStyle(ThemeConstants.DangerButtonStyle())
    }

    /// Apply icon button style
    public func iconButtonStyle() -> some View {
        self.buttonStyle(ThemeConstants.IconButtonStyle())
    }
}
