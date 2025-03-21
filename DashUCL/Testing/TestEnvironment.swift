import Foundation
import SwiftUI

class TestEnvironment: ObservableObject {
    static let shared = TestEnvironment()
    private let persistentStorage = PersistentStorage.shared

    private init() {
        // Register notification observer for app entering foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)

        // Restore test mode state from storage
        self.isTestMode = TestConfig.isTestMode

        // If in test mode, ensure test data is initialized
        if isTestMode {
            setupTestEnvironment()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @Published var isTestMode: Bool = false {
        didSet {
            TestConfig.isTestMode = isTestMode

            // When test mode is enabled, initialize test data and save mock token to secure storage
            if isTestMode {
                // Initialize test data
                TestDataManager.shared.initializeTestData()
                setupTestEnvironment()
            }

            // Post test mode change notification
            postTestModeChangeNotification()
        }
    }

    var mockUserProfile: UserProfile {
        TestConfig.mockUserProfile
    }

    var isAuthenticated: Bool {
        isTestMode
    }

    func toggleTestMode() {
        isTestMode.toggle()
    }

    // Post test mode change notification
    private func postTestModeChangeNotification() {
        NotificationCenter.default.post(name: .init("TestModeDidChange"), object: nil)
    }

    // Handle app entering foreground event
    @objc private func handleAppWillEnterForeground() {
        print("App entering foreground, checking test mode status...")

        // If in test mode, reinitialize test data
        if isTestMode {
            print("In test mode, reinitialize test data...")
            reinitializeTestData()
        }
    }

    // Reinitialize test data
    private func reinitializeTestData() {
        // Clear cache to ensure reloading latest data
        TestDataManager.shared.clearCache()

        // Initialize test data
        TestDataManager.shared.initializeTestData()

        // Post data update notification
        NotificationCenter.default.post(name: .userDataDidUpdate, object: nil)
        print("Test data reinitialized")
    }

    // Set up test environment, including saving mock token
    private func setupTestEnvironment() {
        // Initialize test data
        TestDataManager.shared.initializeTestData()

        // Save mock token to secure storage
        persistentStorage.saveSecure(TestConfig.mockToken, forKey: .userToken)

        // Save authentication status
        persistentStorage.saveValue(true, forKey: .isAuthenticated)

        // Save user profile file
        try? persistentStorage.save(mockUserProfile, forKey: .userProfile)

        // Save basic user information to UserDefaults
        persistentStorage.saveValue(mockUserProfile.email, forKey: .userEmail)
        persistentStorage.saveValue(mockUserProfile.fullName, forKey: .userFullName)
        persistentStorage.saveValue(mockUserProfile.department, forKey: .userDepartment)
        persistentStorage.saveValue(mockUserProfile.cn, forKey: .userCN)
        persistentStorage.saveValue(mockUserProfile.givenName, forKey: .userGivenName)
        persistentStorage.saveValue(mockUserProfile.upi, forKey: .userUPI)
        persistentStorage.saveValue(mockUserProfile.scopeNumber, forKey: .userScopeNumber)
        persistentStorage.saveValue(mockUserProfile.isStudent, forKey: .userIsStudent)
        try? persistentStorage.save(mockUserProfile.uclGroups, forKey: .userGroups)

        // Post login notification
        NotificationCenter.default.post(name: .userDidSignIn, object: nil)
        NotificationCenter.default.post(name: .userDataDidUpdate, object: nil)
    }

    // Handle sign out operation
    func handleSignOut() {
        isTestMode = false

        // Clear authentication status and token
        persistentStorage.removeSecure(forKey: .userToken)
        persistentStorage.saveValue(false, forKey: .isAuthenticated)
    }
}
