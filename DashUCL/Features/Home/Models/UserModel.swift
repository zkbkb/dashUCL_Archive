/*
 * User data management models and services for handling authentication data.
 * Defines data structures for user profiles with UCL-specific attributes.
 * Implements observable objects for reactive UI updates on user data changes.
 * Provides centralized user state access throughout the application.
 */

import Foundation
import SwiftUI

// API Response Model
/// Represents user data from the UCL API
struct UserData: Codable {
    /// API response status
    let ok: Bool
    /// User's UCL username
    let cn: String
    /// User's department
    let department: String
    /// User's primary email
    let email: String
    /// User's full name
    let fullName: String
    /// User's given name
    let givenName: String
    /// User's UPI (Universal Personal Identifier)
    let upi: String
    /// User's scope number
    let scopeNumber: Int
    /// Whether the user is a student
    let isStudent: Bool
    /// User's UCL groups
    let uclGroups: [String]
    /// User's surname
    let sn: String?
    /// User's alternative email
    let mail: String?
    /// User's type (e.g., ["U/G"] for undergraduate)
    let userTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case ok
        case cn
        case department
        case email
        case fullName = "full_name"
        case givenName = "given_name"
        case upi
        case scopeNumber = "scope_number"
        case isStudent = "is_student"
        case uclGroups = "ucl_groups"
        case sn
        case mail
        case userTypes = "user_types"
    }

    // Custom decoder initializer to handle potentially missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        ok = try container.decode(Bool.self, forKey: .ok)
        cn = try container.decode(String.self, forKey: .cn)
        department = try container.decode(String.self, forKey: .department)
        email = try container.decode(String.self, forKey: .email)
        givenName = try container.decode(String.self, forKey: .givenName)
        upi = try container.decode(String.self, forKey: .upi)
        scopeNumber = try container.decode(Int.self, forKey: .scopeNumber)
        isStudent = try container.decode(Bool.self, forKey: .isStudent)
        uclGroups = try container.decode([String].self, forKey: .uclGroups)

        // Optional fields
        sn = try container.decodeIfPresent(String.self, forKey: .sn)
        mail = try container.decodeIfPresent(String.self, forKey: .mail)
        userTypes = try container.decodeIfPresent([String].self, forKey: .userTypes)

        // Handle fullName field - if missing, use givenName instead
        if let fullName = try container.decodeIfPresent(String.self, forKey: .fullName) {
            self.fullName = fullName
        } else {
            // If full_name is missing, use givenName or other combinations as fallback
            if let sn = self.sn {
                self.fullName = "\(givenName) \(sn)"
            } else {
                self.fullName = givenName
            }
            // Log error for debugging
            print(
                "Warning: full_name field missing in API response, using \(self.fullName) instead")
        }
    }

    /// Custom encoding method (if needed)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ok, forKey: .ok)
        try container.encode(cn, forKey: .cn)
        try container.encode(department, forKey: .department)
        try container.encode(email, forKey: .email)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(givenName, forKey: .givenName)
        try container.encode(upi, forKey: .upi)
        try container.encode(scopeNumber, forKey: .scopeNumber)
        try container.encode(isStudent, forKey: .isStudent)
        try container.encode(uclGroups, forKey: .uclGroups)
        try container.encodeIfPresent(sn, forKey: .sn)
        try container.encodeIfPresent(mail, forKey: .mail)
        try container.encodeIfPresent(userTypes, forKey: .userTypes)
    }

    /// Regular initializer for creating test data
    init(
        ok: Bool,
        cn: String,
        department: String,
        email: String,
        fullName: String,
        givenName: String,
        upi: String,
        scopeNumber: Int,
        isStudent: Bool,
        uclGroups: [String],
        sn: String?,
        mail: String?,
        userTypes: [String]?
    ) {
        self.ok = ok
        self.cn = cn
        self.department = department
        self.email = email
        self.fullName = fullName
        self.givenName = givenName
        self.upi = upi
        self.scopeNumber = scopeNumber
        self.isStudent = isStudent
        self.uclGroups = uclGroups
        self.sn = sn
        self.mail = mail
        self.userTypes = userTypes
    }

    /// Creates a test user data instance
    static var testUser: UserData {
        UserData(
            ok: true,
            cn: "test123",
            department: "Department of Computer Science",
            email: "test.user@ucl.ac.uk",
            fullName: "Test User",
            givenName: "Test",
            upi: "test123",
            scopeNumber: 0,
            isStudent: true,
            uclGroups: ["cs-ug", "all-students"],
            sn: "User",
            mail: "test.user.alt@ucl.ac.uk",
            userTypes: ["U/G"]
        )
    }
}

@MainActor
class UserModel: ObservableObject {
    static let shared = UserModel()

    // User Profile Data
    @Published var email: String = ""
    @Published var fullName: String = ""
    @Published var department: String = ""
    @Published var cn: String = ""
    @Published var givenName: String = ""
    @Published var upi: String = ""
    @Published var scopeNumber: Int = 0
    @Published var isStudent: Bool = false
    @Published var uclGroups: [String] = []

    private let storageService: StorageServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let persistentStorage: PersistentStorage
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300  // 5 minutes sync interval

    init(
        storageService: StorageServiceProtocol = StorageService(),
        networkService: NetworkServiceProtocol = NetworkService(),
        persistentStorage: PersistentStorage = .shared
    ) {
        self.storageService = storageService
        self.networkService = networkService
        self.persistentStorage = persistentStorage
        loadUserData()
        setupSyncTimer()

        // Listen for user logout notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserSignOut),
            name: .userDidSignOut,
            object: nil
        )

        // Listen for user login notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserSignIn),
            name: .userDidSignIn,
            object: nil
        )
    }

    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupSyncTimer() {
        Task { @MainActor in
            syncTimer?.invalidate()
            syncTimer = Timer.scheduledTimer(
                withTimeInterval: syncInterval,
                repeats: true
            ) { [weak self] _ in
                Task {
                    try? await self?.syncUserData()
                }
            }
        }
    }

    func syncUserData() async throws {
        print("Starting user data sync...")
        guard let token = AuthManager.shared.accessToken else {
            print("Token authentication required")
            throw NSError(
                domain: "UserModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
            )
        }

        do {
            print("Fetching user data with token: \(String(token.prefix(10)))...")
            let userData: UserData = try await networkService.fetch(endpoint: .userInfo)

            // Ensure updates are made on the main actor
            await MainActor.run {
                print("Updating user data on main actor")
                update(with: userData)
                // Save sync timestamp
                persistentStorage.saveValue(
                    Date().timeIntervalSince1970, forKey: .lastDataSyncTimestamp)
                // Send data update notification
                NotificationCenter.default.post(name: .userDataDidUpdate, object: nil)
            }

            print("User data sync completed")
        } catch {
            print("Failed to sync user data: \(error)")
            throw error
        }
    }

    @objc private func handleUserSignOut() {
        Task { @MainActor in
            syncTimer?.invalidate()
            syncTimer = nil
            clearUserData()
        }
    }

    @objc private func handleUserSignIn() {
        Task {
            try? await syncUserData()
        }
    }

    @MainActor
    func update(with userData: UserData) {
        print("UserModel.update called with data: \(userData)")
        email = userData.email
        fullName = userData.fullName
        department = userData.department
        cn = userData.cn
        givenName = userData.givenName
        upi = userData.upi
        scopeNumber = userData.scopeNumber
        isStudent = userData.isStudent
        uclGroups = userData.uclGroups

        print("Updated UserModel properties:")
        print("fullName: \(fullName)")
        print("department: \(department)")
        print("email: \(email)")

        saveUserData()
        print("UserModel data saved to persistent storage")
    }

    @MainActor
    private func loadUserData() {
        // Load user data from persistent storage
        email = persistentStorage.loadString(forKey: .userEmail) ?? ""
        fullName = persistentStorage.loadString(forKey: .userFullName) ?? ""
        department = persistentStorage.loadString(forKey: .userDepartment) ?? ""
        cn = persistentStorage.loadString(forKey: .userCN) ?? ""
        givenName = persistentStorage.loadString(forKey: .userGivenName) ?? ""
        upi = persistentStorage.loadString(forKey: .userUPI) ?? ""
        scopeNumber = persistentStorage.loadInt(forKey: .userScopeNumber)
        isStudent = persistentStorage.loadBool(forKey: .userIsStudent)

        // Load array type data
        if let groups = try? persistentStorage.load(forKey: .userGroups) as [String] {
            uclGroups = groups
        } else {
            uclGroups = []
        }
    }

    @MainActor
    private func saveUserData() {
        // Save user data to persistent storage
        persistentStorage.saveValue(email, forKey: .userEmail)
        persistentStorage.saveValue(fullName, forKey: .userFullName)
        persistentStorage.saveValue(department, forKey: .userDepartment)
        persistentStorage.saveValue(cn, forKey: .userCN)
        persistentStorage.saveValue(givenName, forKey: .userGivenName)
        persistentStorage.saveValue(upi, forKey: .userUPI)
        persistentStorage.saveValue(scopeNumber, forKey: .userScopeNumber)
        persistentStorage.saveValue(isStudent, forKey: .userIsStudent)

        // Save array type data
        try? persistentStorage.save(uclGroups, forKey: .userGroups)
    }

    @MainActor
    func clearUserData() {
        email = ""
        fullName = ""
        department = ""
        cn = ""
        givenName = ""
        upi = ""
        scopeNumber = 0
        isStudent = false
        uclGroups = []

        // Clear user data from persistent storage
        persistentStorage.remove(forKey: .userEmail)
        persistentStorage.remove(forKey: .userFullName)
        persistentStorage.remove(forKey: .userDepartment)
        persistentStorage.remove(forKey: .userCN)
        persistentStorage.remove(forKey: .userGivenName)
        persistentStorage.remove(forKey: .userUPI)
        persistentStorage.remove(forKey: .userScopeNumber)
        persistentStorage.remove(forKey: .userIsStudent)
        persistentStorage.remove(forKey: .userGroups)
    }
}
