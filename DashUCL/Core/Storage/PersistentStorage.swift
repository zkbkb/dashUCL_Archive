/*
 * Persistent storage service for securely saving and retrieving app data.
 * Implements encryption for sensitive information using iOS Keychain services.
 * Provides type-safe access to stored values with automatic serialization/deserialization.
 * Manages keys through a centralized enumeration for better organization and access control.
 */

import Foundation
import SwiftUI

/// Persistent storage key enumeration
/// Used to define all data types that need persistent storage
enum PersistentStorageKey: String, CaseIterable {
    // User authentication related
    case userToken = "persistent.userToken"
    case userProfile = "persistent.userProfile"
    case isAuthenticated = "persistent.isAuthenticated"

    // User data related
    case userEmail = "persistent.userEmail"
    case userFullName = "persistent.userFullName"
    case userDepartment = "persistent.userDepartment"
    case userCN = "persistent.userCN"
    case userGivenName = "persistent.userGivenName"
    case userUPI = "persistent.userUPI"
    case userScopeNumber = "persistent.userScopeNumber"
    case userIsStudent = "persistent.userIsStudent"
    case userGroups = "persistent.userGroups"

    // Application settings related
    case appTheme = "persistent.appTheme"
    case appLanguage = "persistent.appLanguage"
    case appDarkModeEnabled = "persistent.appDarkModeEnabled"
    case appUseSystemTheme = "persistent.appUseSystemTheme"
    case appUseDirectAPI = "persistent.appUseDirectAPI"
    case notificationsEnabled = "persistent.notificationsEnabled"
    case courseRemindersEnabled = "persistent.courseRemindersEnabled"
    case dataRefreshInterval = "persistent.dataRefreshInterval"
    case developerModeEnabled = "persistent.developerModeEnabled"
    case courseReminderTime = "persistent.courseReminderTime"

    // Calendar synchronization related
    case syncWithCalendar = "persistent.syncWithCalendar"
    case autoExport = "persistent.autoExport"
    case syncFrequency = "persistent.syncFrequency"

    // User preferences related
    case favoriteSpaces = "persistent.favoriteSpaces"
    case lastViewedTab = "persistent.lastViewedTab"

    // Cache control related
    case lastDataSyncTimestamp = "persistent.lastDataSyncTimestamp"
    case lastCacheCleanupDate = "persistent.lastCacheCleanupDate"
}

/// Persistent storage error type
enum PersistentStorageError: LocalizedError {
    case saveError(Error)
    case loadError(Error)
    case dataNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .loadError(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .dataNotFound:
            return "Data not found in storage"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

/// Persistent storage protocol
protocol PersistentStorageProtocol {
    /// Save data to persistent storage
    /// - Parameters:
    ///   - value: Value to save
    ///   - key: Storage key
    func save<T: Codable>(_ value: T, forKey key: PersistentStorageKey) throws

    /// Load data from persistent storage
    /// - Parameter key: Storage key
    /// - Returns: Loaded data
    func load<T: Codable>(forKey key: PersistentStorageKey) throws -> T

    /// Check if key exists
    /// - Parameter key: Storage key
    /// - Returns: Whether exists
    func exists(forKey key: PersistentStorageKey) -> Bool

    /// Remove data for specified key
    /// - Parameter key: Storage key
    func remove(forKey key: PersistentStorageKey)

    /// Remove all persistent data
    func removeAll()
}

/// Persistent storage service implementation
/// Uses UserDefaults as the primary storage mechanism, suitable for storing non-sensitive data
class PersistentStorage: PersistentStorageProtocol {
    // Singleton instance
    static let shared = PersistentStorage()

    // UserDefaults instance
    private let userDefaults: UserDefaults

    // JSON encoder/decoder
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Configure encoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        // Configure decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Save data to UserDefaults
    func save<T: Codable>(_ value: T, forKey key: PersistentStorageKey) throws {
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key.rawValue)
        } catch {
            print("Error saving data for key \(key.rawValue): \(error)")
            throw PersistentStorageError.saveError(error)
        }
    }

    /// Load data from UserDefaults
    func load<T: Codable>(forKey key: PersistentStorageKey) throws -> T {
        guard let data = userDefaults.data(forKey: key.rawValue) else {
            throw PersistentStorageError.dataNotFound
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error loading data for key \(key.rawValue): \(error)")
            throw PersistentStorageError.loadError(error)
        }
    }

    /// Check if key exists
    func exists(forKey key: PersistentStorageKey) -> Bool {
        return userDefaults.object(forKey: key.rawValue) != nil
    }

    /// Remove data for specified key
    func remove(forKey key: PersistentStorageKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }

    /// Remove all persistent data
    func removeAll() {
        PersistentStorageKey.allCases.forEach { key in
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }

    // MARK: - Convenient methods

    /// Convenient method for saving simple types (non-Codable)
    func saveValue(_ value: Any, forKey key: PersistentStorageKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    /// Convenient method for loading strings
    func loadString(forKey key: PersistentStorageKey) -> String? {
        return userDefaults.string(forKey: key.rawValue)
    }

    /// Convenient method for loading booleans
    func loadBool(forKey key: PersistentStorageKey) -> Bool {
        return userDefaults.bool(forKey: key.rawValue)
    }

    /// Convenient method for loading integers
    func loadInt(forKey key: PersistentStorageKey) -> Int {
        return userDefaults.integer(forKey: key.rawValue)
    }

    /// Convenient method for loading doubles
    func loadDouble(forKey key: PersistentStorageKey) -> Double {
        return userDefaults.double(forKey: key.rawValue)
    }

    /// Convenient method for loading dates
    func loadDate(forKey key: PersistentStorageKey) -> Date? {
        return userDefaults.object(forKey: key.rawValue) as? Date
    }
}

// MARK: - Secure storage extension
// Used for storing sensitive data, using Keychain
extension PersistentStorage {
    /// Save sensitive data to Keychain
    func saveSecure(_ value: String, forKey key: PersistentStorageKey) {
        let keychainKey = key.rawValue

        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrService as String: "com.Kaibin-Zhang.Dash-UCL",  // Add service identifier
            kSecAttrSynchronizable as String: false,  // Do not sync to iCloud
        ]

        // Try to delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving secure data for key \(keychainKey): \(status)")
        } else {
            print("Successfully saved secure data for key \(keychainKey)")
        }
    }

    /// Read sensitive data from Keychain
    func readSecure(forKey key: PersistentStorageKey) -> String? {
        let keychainKey = key.rawValue

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrService as String: "com.Kaibin-Zhang.Dash-UCL",  // Add service identifier
            kSecAttrSynchronizable as String: false,  // Do not sync to iCloud
        ]

        // Execute query
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            let value = String(data: data, encoding: .utf8)
            print("Successfully loaded secure data for key \(keychainKey)")
            return value
        } else {
            if status != errSecItemNotFound {
                print("Error loading secure data for key \(keychainKey): \(status)")
            } else {
                print("No secure data found for key \(keychainKey)")
            }
            return nil
        }
    }

    /// Remove specific data from Keychain
    func removeSecure(forKey key: PersistentStorageKey) {
        let keychainKey = key.rawValue

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecAttrService as String: "com.Kaibin-Zhang.Dash-UCL",  // Add service identifier
            kSecAttrSynchronizable as String: false,  // Do not sync to iCloud
        ]

        // Delete item
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error removing secure data for key \(keychainKey): \(status)")
        } else {
            print("Successfully removed secure data for key \(keychainKey)")
        }
    }

    /// Remove all sensitive data from Keychain
    func removeAllSecure() {
        // Create query dictionary to match all items
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.Kaibin-Zhang.Dash-UCL",
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error removing all secure data: \(status)")
        } else {
            print("Successfully removed all secure data")
        }
    }
}
