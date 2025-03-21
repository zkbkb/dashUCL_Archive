import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    private let authManager: AuthManager
    @Published var isLoading = false
    private var loginTask: Task<Void, Error>?

    init(authManager: AuthManager = .shared) {
        self.authManager = authManager
    }

    func login() async throws {
        isLoading = true
        defer { isLoading = false }

        // Cancel previous login task (if any)
        loginTask?.cancel()

        // Create new login task
        loginTask = Task {
            try await authManager.signIn()
        }

        // Wait for login completion or cancellation
        do {
            try await loginTask?.value
        } catch {
            loginTask = nil
            throw error
        }

        loginTask = nil
    }

    deinit {
        // Ensure login task is cancelled when view disappears
        loginTask?.cancel()
    }
}
