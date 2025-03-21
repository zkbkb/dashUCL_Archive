import SwiftUI

/// 应用主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    // 持久化存储
    private let persistentStorage = PersistentStorage.shared

    // 使用@Published替代@AppStorage
    @Published private(set) var isDarkMode: Bool = false
    @Published private(set) var useSystemTheme: Bool = true
    @Published private(set) var currentTheme: ThemeOption = .system

    private init() {
        // 从持久化存储加载设置
        isDarkMode = persistentStorage.loadBool(forKey: .appDarkModeEnabled)

        // 检查系统主题设置是否存在
        if persistentStorage.exists(forKey: .appUseSystemTheme) {
            useSystemTheme = persistentStorage.loadBool(forKey: .appUseSystemTheme)
        } else {
            // 默认使用系统主题
            useSystemTheme = true
            persistentStorage.saveValue(true, forKey: .appUseSystemTheme)
        }

        // 设置当前主题
        if useSystemTheme {
            currentTheme = .system
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        } else {
            currentTheme = isDarkMode ? .dark : .light
        }
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
        useSystemTheme = false
        currentTheme = isDarkMode ? .dark : .light

        // 保存到持久化存储
        persistentStorage.saveValue(isDarkMode, forKey: .appDarkModeEnabled)
        persistentStorage.saveValue(useSystemTheme, forKey: .appUseSystemTheme)
    }

    func setDarkMode(enabled: Bool) {
        isDarkMode = enabled
        useSystemTheme = false
        currentTheme = isDarkMode ? .dark : .light

        // 保存到持久化存储
        persistentStorage.saveValue(isDarkMode, forKey: .appDarkModeEnabled)
        persistentStorage.saveValue(useSystemTheme, forKey: .appUseSystemTheme)
    }
    
    func setTheme(_ theme: ThemeOption) {
        currentTheme = theme
        
        switch theme {
        case .light:
            isDarkMode = false
            useSystemTheme = false
        case .dark:
            isDarkMode = true
            useSystemTheme = false
        case .system:
            useSystemTheme = true
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        // 保存到持久化存储
        persistentStorage.saveValue(isDarkMode, forKey: .appDarkModeEnabled)
        persistentStorage.saveValue(useSystemTheme, forKey: .appUseSystemTheme)
    }

    func toggleSystemTheme() {
        useSystemTheme = false
        // 保持当前的深色/浅色模式不变

        // 保存到持久化存储
        persistentStorage.saveValue(useSystemTheme, forKey: .appUseSystemTheme)
    }

    func useSystemSettings() {
        useSystemTheme = true
        isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark

        // 保存到持久化存储
        persistentStorage.saveValue(useSystemTheme, forKey: .appUseSystemTheme)
        persistentStorage.saveValue(isDarkMode, forKey: .appDarkModeEnabled)
    }

    var colorScheme: ColorScheme? {
        useSystemTheme ? nil : (isDarkMode ? .dark : .light)
    }
}
