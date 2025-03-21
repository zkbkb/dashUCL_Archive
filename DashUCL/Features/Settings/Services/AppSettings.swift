import Foundation
import SwiftUI

/// Application Global Settings
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // 持久化存储
    private let persistentStorage = PersistentStorage.shared

    // MARK: - User Interface Settings

    /// Whether to use dark mode
    @Published var darkModeEnabled: Bool {
        didSet {
            persistentStorage.saveValue(darkModeEnabled, forKey: .appDarkModeEnabled)
        }
    }

    /// Whether to enable notifications
    @Published var notificationsEnabled: Bool {
        didSet {
            persistentStorage.saveValue(notificationsEnabled, forKey: .notificationsEnabled)
        }
    }

    /// Whether to enable course reminders specifically
    @Published var courseRemindersEnabled: Bool {
        didSet {
            persistentStorage.saveValue(courseRemindersEnabled, forKey: .courseRemindersEnabled)
        }
    }

    /// Course reminder time in minutes before class
    @Published var courseReminderTime: Int {
        didSet {
            persistentStorage.saveValue(courseReminderTime, forKey: .courseReminderTime)
        }
    }

    /// Whether developer mode is enabled
    @Published var developerModeEnabled: Bool {
        didSet {
            persistentStorage.saveValue(developerModeEnabled, forKey: .developerModeEnabled)
        }
    }

    // MARK: - API Settings

    /// Whether to directly access UCL API (bypassing Supabase proxy)
    /// Note: This only applies to certain read-only APIs, such as workstation status
    @Published var useDirectAPI: Bool {
        didSet {
            persistentStorage.saveValue(useDirectAPI, forKey: .appUseDirectAPI)
        }
    }

    /// Data refresh interval (seconds)
    @Published var dataRefreshInterval: TimeInterval {
        didSet {
            persistentStorage.saveValue(dataRefreshInterval, forKey: .dataRefreshInterval)
        }
    }

    // MARK: - Initialization

    private init() {
        // 先初始化所有存储属性，避免在初始化过程中访问self
        let loadedDarkMode = persistentStorage.loadBool(forKey: .appDarkModeEnabled)
        let loadedNotifications = persistentStorage.loadBool(forKey: .notificationsEnabled)
        let loadedCourseReminders = persistentStorage.loadBool(forKey: .courseRemindersEnabled)
        let loadedDevMode = persistentStorage.loadBool(forKey: .developerModeEnabled)
        _ =
            persistentStorage.exists(forKey: .appUseDirectAPI)
            ? persistentStorage.loadBool(forKey: .appUseDirectAPI) : true
        let loadedRefreshInterval = persistentStorage.loadDouble(forKey: .dataRefreshInterval)

        // 加载课程提醒时间，如果不存在则使用默认值
        var loadedReminderTime = persistentStorage.loadInt(forKey: .courseReminderTime)
        if loadedReminderTime == 0 {
            loadedReminderTime = AppConfiguration.NotificationConfig.defaultReminderTime
            persistentStorage.saveValue(loadedReminderTime, forKey: .courseReminderTime)
        }

        // 初始化所有@Published属性
        self.darkModeEnabled = loadedDarkMode
        self.notificationsEnabled = loadedNotifications
        self.courseRemindersEnabled = loadedCourseReminders != false  // 默认为true
        self.courseReminderTime = loadedReminderTime
        self.developerModeEnabled = loadedDevMode
        self.useDirectAPI = true  // 强制设为true，见下方注释
        self.dataRefreshInterval = loadedRefreshInterval > 0 ? loadedRefreshInterval : 300

        // 由于当前UCL API /resources/desktops端点的解析问题，强制启用直接API访问模式
        // 这绕过了Supabase代理层，减少了潜在的错误来源
        // 临时解决方案，直到UCL API问题解决，强制启用直接API访问
        persistentStorage.saveValue(true, forKey: .appUseDirectAPI)

        // 如果刷新间隔为0，设置默认值
        if self.dataRefreshInterval == 0 {
            self.dataRefreshInterval = 300  // 5分钟
            persistentStorage.saveValue(self.dataRefreshInterval, forKey: .dataRefreshInterval)
        }
    }

    // MARK: - Helper Methods

    /// Reset all settings to defaults
    func resetToDefaults() {
        darkModeEnabled = false
        notificationsEnabled = true
        courseRemindersEnabled = true
        courseReminderTime = AppConfiguration.NotificationConfig.defaultReminderTime
        useDirectAPI = true  // 默认启用直接API访问
        dataRefreshInterval = 300  // 5分钟
        developerModeEnabled = false  // 开发者模式默认关闭
    }
}
