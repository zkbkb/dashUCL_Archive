import SwiftUI
import UIKit

/// UI Theme Manager
/// Provides theme management functionality for the application, working together with ThemeConstants
/// Singleton instance
/// Theme Manager - using internal access level
/// Private initialization method
// Try to get ThemeManager instance
/// Get current color scheme
/// Check if using system theme
/// Check if in dark mode
// MARK: - Background Modifiers
/// Apply main background
/// Apply grouped background
/// Apply secondary background
/// Apply secondary grouped background
public class UITheme: ObservableObject {
    /// Singleton instance
    public static let shared = UITheme()

    /// Theme Manager - using internal access level
    @Published var themeManager: ThemeManager?

    /// Private initialization method
    private init() {
        // Try to get ThemeManager instance
        if let themeManager = (NSClassFromString("ThemeManager") as? ThemeManager.Type)?.shared {
            self.themeManager = themeManager
        }
    }

    /// Get current color scheme
    public var currentColorScheme: ColorScheme? {
        return themeManager?.colorScheme
    }

    /// Check if using system theme
    public var usesSystemTheme: Bool {
        return themeManager?.useSystemTheme ?? true
    }

    /// Check if in dark mode
    public var isDarkMode: Bool {
        return themeManager?.isDarkMode ?? (UITraitCollection.current.userInterfaceStyle == .dark)
    }
}

// MARK: - Background Modifiers
extension View {
    /// Apply main background
    public func withPrimaryBackground() -> some View {
        self.background(ThemeConstants.primaryBackground.ignoresSafeArea())
    }

    /// Apply grouped background
    public func withGroupedBackground() -> some View {
        self.background(ThemeConstants.groupedBackground.ignoresSafeArea())
    }

    /// Apply secondary background
    public func withSecondaryBackground() -> some View {
        self.background(ThemeConstants.secondaryBackground)
    }

    /// Apply secondary grouped background
    public func withSecondaryGroupedBackground() -> some View {
        self.background(ThemeConstants.secondaryGroupedBackground)
    }
}

// MARK: - View Modifiers
extension View {
    /// Apply theme status bar style
    public func themeStatusBar(showDivider: Bool = true) -> some View {
        self.modifier(ThemeStatusBarModifier(showDivider: showDivider))
    }
}

/// Theme status bar modifier
public struct ThemeStatusBarModifier: ViewModifier {
    let showDivider: Bool

    public func body(content: Content) -> some View {
        content
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay(alignment: .top) {
                if showDivider {
                    Divider()
                        .offset(y: 0)
                        .ignoresSafeArea(.all, edges: .top)
                }
            }
    }
}
