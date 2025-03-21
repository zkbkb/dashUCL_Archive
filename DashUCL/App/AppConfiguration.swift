/*
 * Central configuration manager for the DashUCL app with environment-specific settings.
 * Defines app parameters including API endpoints, notification settings, and cache policies.
 * Implements a singleton pattern for consistent access throughout the application.
 * Provides configuration values that adapt based on the current build environment.
 */

import Foundation
import SwiftUI
import UserNotifications

enum AppEnvironment {
    case development
    case testing
    case production

    static var current: AppEnvironment {
        #if DEBUG
            return .development
        #else
            // Can be determined based on build configuration or other conditions
            return .production
        #endif
    }
}

struct AppConfiguration {
    // Singleton instance
    static let shared = AppConfiguration()

    // Private initialization method
    private init() {}

    // MARK: - Basic App Information

    let appName = "DashUCL"
    let appVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

    // MARK: - API Configuration

    var apiBaseURL: URL {
        switch AppEnvironment.current {
        case .development:
            return URL(string: "https://dev-api.ucl.ac.uk")!
        case .testing:
            return URL(string: "https://test-api.ucl.ac.uk")!
        case .production:
            return URL(string: "https://api.ucl.ac.uk")!
        }
    }

    // MARK: - Push Notification Configuration

    struct NotificationConfig {
        // Notification category identifiers
        static let classReminderCategory = "CLASS_REMINDER"

        // Notification action identifiers
        static let viewClassAction = "VIEW_CLASS_ACTION"
        static let dismissAction = "DISMISS_ACTION"

        // Course reminder time (minutes)
        static let defaultReminderTime: Int = 15

        // User selectable reminder time options (minutes)
        static let reminderTimeOptions: [Int] = [5, 10, 15, 30, 60]

        // Notification sound
        static let defaultSound = UNNotificationSound.default

        // Show notifications in foreground
        static let showInForeground = true
    }

    // MARK: - Widget Configuration

    struct WidgetConfig {
        // Widget refresh frequency (seconds)
        static let refreshInterval: TimeInterval = 1800  // 30 minutes

        // Widget data cache TTL (seconds)
        static let dataCacheTTL: TimeInterval = 3600  // 1 hour

        // Widget display maximum number of classes
        static let maxClassesShown: Int = 3

        // Widget display date range (days)
        static let dayRange: Int = 1
    }

    // MARK: - Cache Configuration

    // Cache maximum size (bytes)
    let maxCacheSize: Int = 50 * 1024 * 1024  // 50 MB

    // Cache TTL (seconds)
    let cacheTTL: TimeInterval = 7 * 24 * 60 * 60  // 7 days

    // MARK: - Network Configuration

    // Network request timeout interval (seconds)
    let networkTimeoutInterval: TimeInterval = 30.0

    // Network retry count
    let networkMaxRetries: Int = 3

    // MARK: - Debug Configuration

    // Whether to enable debug logging
    var isDebugLoggingEnabled: Bool {
        AppEnvironment.current != .production
    }

    // Whether to enable test mode
    var isTestModeAvailable: Bool {
        AppEnvironment.current != .production
    }
}
