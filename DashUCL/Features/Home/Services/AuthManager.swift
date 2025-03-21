/*
 * Authentication service managing user login, OAuth flow, and session state.
 * Handles token acquisition, refresh, and validation with UCL authentication provider.
 * Maintains user profile data and authentication status across app restarts.
 * Provides notification mechanisms for auth state changes throughout the app.
 */

//
//  AuthManager.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/02/2025.
//

import AuthenticationServices
import Foundation
import SwiftUI

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidURL
    case networkError
    case authenticationFailed
    case tokenExchangeFailed
    case userDataFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials"
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error"
        case .authenticationFailed:
            return "Authentication failed"
        case .tokenExchangeFailed:
            return "Token exchange failed"
        case .userDataFailed:
            return "Failed to fetch user data"
        }
    }
}

class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    private let testEnvironment = TestEnvironment.shared
    private let persistentStorage = PersistentStorage.shared

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: UserProfile?

    // MARK: - Internal Properties
    internal var accessToken: String? {
        get {
            // Get token from secure storage
            let token = persistentStorage.readSecure(forKey: PersistentStorageKey.userToken)
            return token
        }
        set {
            if let newValue = newValue {
                // Save token to secure storage
                persistentStorage.saveSecure(newValue, forKey: PersistentStorageKey.userToken)
            } else {
                // If nil, delete token
                persistentStorage.removeSecure(forKey: PersistentStorageKey.userToken)
            }
            // Update authentication state
            isAuthenticated = newValue != nil
            // Save authentication state
            persistentStorage.saveValue(
                isAuthenticated, forKey: PersistentStorageKey.isAuthenticated)
        }
    }

    internal let clientID =
        Bundle.main.object(forInfoDictionaryKey: "UCL_CLIENT_ID") as? String ?? ""
    internal let clientSecret =
        Bundle.main.object(forInfoDictionaryKey: "UCL_CLIENT_SECRET") as? String ?? ""

    // MARK: - Private Properties
    private let supabaseURL = "YOUR_SUPABASE_URL"  // Supabase URL
    private var authSession: ASWebAuthenticationSession?
    private var continuationHandler: CheckedContinuation<Void, Error>?

    private override init() {
        super.init()

        print("======= AuthManager Initialization Started =======")

        if testEnvironment.isTestMode {
            print("Test mode activated, using mock user data")
            self.isAuthenticated = true
            self.currentUser = testEnvironment.mockUserProfile
        } else {
            // Load authentication state and token from persistent storage
            let savedToken = persistentStorage.readSecure(forKey: PersistentStorageKey.userToken)
            print("Token loaded from Keychain: \(savedToken != nil ? "exists" : "does not exist")")

            let storedAuthState = persistentStorage.loadBool(
                forKey: PersistentStorageKey.isAuthenticated)
            print("Authentication state loaded from UserDefaults: \(storedAuthState)")

            // Initialize authentication state based on token existence
            self.isAuthenticated = savedToken != nil
            print("Based on token existence, initial authentication state: \(self.isAuthenticated)")

            // Ensure isAuthenticated and accessToken state consistency
            if savedToken != nil && !storedAuthState {
                print(
                    "Detected token exists but authentication state is false, updating authentication state"
                )
                // If there's a token but isAuthenticated is false, update isAuthenticated
                persistentStorage.saveValue(true, forKey: PersistentStorageKey.isAuthenticated)
            } else if savedToken == nil && storedAuthState {
                print(
                    "Detected token does not exist but authentication state is true, updating authentication state"
                )
                // If there's no token but isAuthenticated is true, update isAuthenticated
                persistentStorage.saveValue(false, forKey: PersistentStorageKey.isAuthenticated)
            }

            // Update authentication state
            self.isAuthenticated = persistentStorage.loadBool(
                forKey: PersistentStorageKey.isAuthenticated)
            print("Final authentication state: \(self.isAuthenticated)")

            // Try to load user configuration file
            let userProfileExists = persistentStorage.exists(
                forKey: PersistentStorageKey.userProfile)
            print("User configuration file exists: \(userProfileExists)")

            if isAuthenticated {
                if userProfileExists {
                    do {
                        let userData =
                            try persistentStorage.load(forKey: PersistentStorageKey.userProfile)
                            as UserProfile
                        self.currentUser = userData
                        print("Successfully loaded user profile: \(userData.fullName)")
                    } catch {
                        print("Failed to load user profile: \(error.localizedDescription)")
                        self.isAuthenticated = false
                        persistentStorage.saveValue(
                            false, forKey: PersistentStorageKey.isAuthenticated)
                    }
                } else {
                    print(
                        "User is authenticated but user profile not found, resetting authentication state"
                    )
                    self.isAuthenticated = false
                    persistentStorage.saveValue(false, forKey: PersistentStorageKey.isAuthenticated)
                }
            }
        }

        // Store user data in test mode
        if testEnvironment.isTestMode {
            if let currentUser = currentUser {
                try? persistentStorage.save(currentUser, forKey: PersistentStorageKey.userProfile)
                print("Test mode: Saved mock user profile")
            }
            persistentStorage.saveValue(
                isAuthenticated, forKey: PersistentStorageKey.isAuthenticated)
            print("Test mode: Saved authentication state")
        }

        // Check if credentials are loaded correctly
        print("Loaded credentials:")
        print("Client ID: \(clientID)")
        print("Client Secret: \(clientSecret.prefix(10))...")
        print("Supabase URL: \(supabaseURL)")

        // Print authentication state
        print("Loaded authentication state: isAuthenticated = \(isAuthenticated)")
        print("Access token exists: \(accessToken != nil)")

        // If authenticated, notify system that user has logged in
        if isAuthenticated && currentUser != nil {
            print("User is authenticated and user data exists, sending login notification")
            NotificationCenter.default.post(name: .userDidSignIn, object: nil)
            NotificationCenter.default.post(name: .userDataDidUpdate, object: nil)
        } else if isAuthenticated {
            print("Warning: User is authenticated but user data does not exist")
        }

        print("======= AuthManager Initialization Completed =======")
    }

    @MainActor
    func signIn() async throws {
        guard !clientID.isEmpty else {
            print("Error: Missing client ID")
            throw AuthError.invalidCredentials
        }

        guard var urlComponents = URLComponents(string: "https://uclapi.com/oauth/authorise") else {
            throw AuthError.invalidURL
        }

        let state = UUID().uuidString
        let redirectUri = "YOUR_SUPABASE_AUTH_URL"  // Placeholder for Supabase Auth URL

        urlComponents.queryItems = [
            URLQueryItem(
                name: "client_id",
                value: clientID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "client_type", value: "web"),
        ]

        guard let url = urlComponents.url else {
            throw AuthError.invalidURL
        }

        print("=== Authorization Request ===")
        print("URL: \(url.absoluteString)")
        print("Query Items:")
        urlComponents.queryItems?.forEach { item in
            print("- \(item.name): \(item.value ?? "nil")")
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuationHandler = continuation

            authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "dashucl"
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }

                Task { @MainActor in
                    self.handleAuthCallback(callbackURL: callbackURL, error: error)
                }
            }

            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = true

            if !authSession!.start() {
                print("Failed to start auth session")
                continuation.resume(throwing: AuthError.authenticationFailed)
            }
        }
    }

    @MainActor
    private func handleAuthCallback(callbackURL: URL?, error: Error?) {
        if let error = error {
            print("Auth Error: \(error)")
            self.continuationHandler?.resume(throwing: AuthError.authenticationFailed)
            return
        }

        guard let callbackURL = callbackURL else {
            print("No callback URL received")
            self.continuationHandler?.resume(throwing: AuthError.authenticationFailed)
            return
        }

        guard callbackURL.scheme?.lowercased() == "dashucl" else {
            print("Invalid callback URL scheme: \(callbackURL.scheme ?? "nil")")
            self.continuationHandler?.resume(throwing: AuthError.authenticationFailed)
            return
        }

        guard
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)
        else {
            print("Failed to parse callback URL")
            self.continuationHandler?.resume(throwing: AuthError.authenticationFailed)
            return
        }

        // Check error
        if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
            print("Auth Error from callback: \(error)")
            self.continuationHandler?.resume(throwing: AuthError.authenticationFailed)
            return
        }

        // Parse data returned from Edge Function
        guard let encodedData = components.queryItems?.first(where: { $0.name == "data" })?.value,
            let jsonString = encodedData.removingPercentEncoding,
            let jsonData = jsonString.data(using: .utf8),
            let response = try? JSONDecoder().decode(AuthResponse.self, from: jsonData)
        else {
            print("Failed to parse response data")
            self.continuationHandler?.resume(throwing: AuthError.authenticationFailed)
            return
        }

        // Update authentication state and user data
        self.accessToken = response.token
        self.isAuthenticated = true

        // Save authentication state and token to UserDefaults
        persistentStorage.saveValue(true, forKey: PersistentStorageKey.isAuthenticated)
        persistentStorage.saveSecure(response.token, forKey: PersistentStorageKey.userToken)

        // Save basic user information to UserDefaults
        persistentStorage.saveValue(response.user.email, forKey: PersistentStorageKey.userEmail)
        persistentStorage.saveValue(
            response.user.full_name, forKey: PersistentStorageKey.userFullName)
        persistentStorage.saveValue(
            response.user.department, forKey: PersistentStorageKey.userDepartment)
        persistentStorage.saveValue(response.user.cn, forKey: PersistentStorageKey.userCN)
        persistentStorage.saveValue(
            response.user.given_name, forKey: PersistentStorageKey.userGivenName)
        persistentStorage.saveValue(response.user.upi, forKey: PersistentStorageKey.userUPI)
        persistentStorage.saveValue(
            response.user.scope_number, forKey: PersistentStorageKey.userScopeNumber)
        persistentStorage.saveValue(
            response.user.is_student, forKey: PersistentStorageKey.userIsStudent)
        try? persistentStorage.save(
            response.user.ucl_groups, forKey: PersistentStorageKey.userGroups)

        // Create user profile object
        // Use correct constructor for UserProfile
        let userProfile = UserProfile(
            ok: true,
            cn: response.user.cn,
            department: response.user.department,
            email: response.user.email,
            fullName: response.user.full_name,
            givenName: response.user.given_name,
            upi: response.user.upi,
            scopeNumber: response.user.scope_number,
            isStudent: response.user.is_student,
            uclGroups: response.user.ucl_groups,
            sn: "",  // Use empty string as default value
            mail: response.user.email,  // Use primary email as mail
            userTypes: ["U/G"]  // Default to undergraduate
        )

        // Save user profile object to persistent storage
        self.currentUser = userProfile
        try? persistentStorage.save(userProfile, forKey: PersistentStorageKey.userProfile)
        print("User profile saved to persistent storage")

        // Update user model
        let userData = UserData(
            ok: true,
            cn: response.user.cn,
            department: response.user.department,
            email: response.user.email,
            fullName: response.user.full_name,
            givenName: response.user.given_name,
            upi: response.user.upi,
            scopeNumber: response.user.scope_number,
            isStudent: response.user.is_student,
            uclGroups: response.user.ucl_groups,
            sn: "",
            mail: response.user.email,  // Use primary email as backup email
            userTypes: ["U/G"]  // Default to undergraduate
        )
        UserModel.shared.update(with: userData)

        // Send login success notification
        NotificationCenter.default.post(name: .userDidSignIn, object: nil)
        NotificationCenter.default.post(name: .userDataDidUpdate, object: nil)

        // Login successful, initiate API testing
        print("===== UCL API TESTING INITIATED =====")
        print("Login successful. Starting tests for all available UCL API endpoints...")
        // Note: APITestService will automatically run tests by listening to .userDidSignIn notification

        self.continuationHandler?.resume()
    }

    func signOut() {
        Task { @MainActor in
            // Check if in test mode
            if testEnvironment.isTestMode {
                // In test mode, call TestEnvironment's handleSignOut method
                testEnvironment.handleSignOut()
            }

            // First update authentication state to avoid UI flicker during cleanup
            self.isAuthenticated = false
            self.currentUser = nil

            // Clear authentication token
            self.accessToken = nil

            // Use data cleanup service to clear all user data
            DataCleanupService.shared.cleanupAllUserData()

            // Notify other components that user has logged out
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)

            print("User signed out successfully")
        }
    }
}

// MARK: - Models
private struct AuthResponse: Codable {
    let ok: Bool
    let token: String
    let state: String
    let user: UCLUserResponse
}

private struct UCLUserResponse: Codable {
    let ok: Bool
    let email: String
    let full_name: String
    let department: String
    let cn: String
    let given_name: String
    let upi: String
    let scope_number: Int
    let is_student: Bool
    let ucl_groups: [String]
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first ?? ASPresentationAnchor()
    }
}
