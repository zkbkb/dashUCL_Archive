import Foundation

protocol DataCleanupServiceProtocol {
    func cleanupAllUserData()
    func cleanupUserDefaults()
    func cleanupKeychain()
    func cleanupDocuments()
    func cleanupCache()
    func cleanupPersistentStorage()
}

class DataCleanupService: DataCleanupServiceProtocol {
    static let shared = DataCleanupService()

    private let storageService: StorageServiceProtocol
    private let persistentStorage: PersistentStorage
    private let userDefaults: UserDefaults

    init(
        storageService: StorageServiceProtocol = StorageService(),
        persistentStorage: PersistentStorage = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.storageService = storageService
        self.persistentStorage = persistentStorage
        self.userDefaults = userDefaults
    }

    func cleanupAllUserData() {
        cleanupUserDefaults()
        cleanupKeychain()
        cleanupDocuments()
        cleanupCache()
        cleanupPersistentStorage()
    }

    func cleanupUserDefaults() {
        // 清理所有 UserDefaults 数据
        storageService.clearAll()

        // 清理额外的 UserDefaults 数据
        let userDefaultsKeys = [
            "accessToken",
            "isAuthenticated",
            "userEmail",
            "userName",
            "userDepartment",
            "userCN",
            "userGivenName",
            "userUPI",
            "userScopeNumber",
            "isStudent",
            "userUCLGroups",
            "lastSyncTimestamp",
        ]

        userDefaultsKeys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }

    func cleanupPersistentStorage() {
        // 清理持久化存储
        persistentStorage.removeAll()

        // 清理安全存储
        persistentStorage.removeAllSecure()
    }

    func cleanupKeychain() {
        // 清理 Keychain 中的敏感数据
        let keychainKeys = [
            "com.Kaibin-Zhang.Dash-UCL.accessToken",
            "com.Kaibin-Zhang.Dash-UCL.refreshToken",
            "com.Kaibin-Zhang.Dash-UCL.userCredentials",
        ]

        keychainKeys.forEach { key in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    func cleanupDocuments() {
        // 清理 Documents 目录中的用户相关文件
        let fileManager = FileManager.default
        guard
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            return
        }

        let userDataPaths = [
            documentsPath.appendingPathComponent("UserData"),
            documentsPath.appendingPathComponent("Bookings"),
            documentsPath.appendingPathComponent("Timetables"),
        ]

        userDataPaths.forEach { path in
            try? fileManager.removeItem(at: path)
        }
    }

    func cleanupCache() {
        // 清理缓存目录
        let fileManager = FileManager.default
        guard let cachePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        else {
            return
        }

        try? fileManager.removeItem(at: cachePath)
        try? fileManager.createDirectory(at: cachePath, withIntermediateDirectories: true)
    }
}
