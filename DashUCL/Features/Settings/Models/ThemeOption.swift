import SwiftUI

/// Theme options for the app
enum ThemeOption: String, CaseIterable {
    case light
    case dark
    case system
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    /// Color representation for UI
    var color: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        case .system:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}
