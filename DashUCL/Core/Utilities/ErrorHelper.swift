/*
 * Centralized error handling utility that categorizes and processes application errors.
 * Provides detection methods for authentication, network, and other common error types.
 * Implements consistent error messaging and user-friendly error descriptions.
 * Supports test mode error handling with appropriate fallback behaviors.
 */

import Foundation

/// Error handling utility class
class ErrorHelper {

    /// Test mode flag - defaults to true, indicating the app is in test mode
    static let isTestMode = true

    /// Check if error is authentication related
    /// - Parameter error: Error to check
    /// - Returns: Whether it is an authentication error
    static func isAuthError(_ error: Error) -> Bool {
        let errorDescription = error.localizedDescription.lowercased()
        return errorDescription.contains("authentication") || errorDescription.contains("auth")
            || errorDescription.contains("token") || errorDescription.contains("unauthorized")
            || errorDescription.contains("authentication required")
            || errorDescription.contains("access token")
    }

    /// Check if error message is authentication related
    /// - Parameter message: Error message to check
    /// - Returns: Whether it is an authentication error
    static func isAuthErrorMessage(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        return lowerMessage.contains("authentication") || lowerMessage.contains("auth")
            || lowerMessage.contains("token") || lowerMessage.contains("unauthorized")
            || lowerMessage.contains("authentication required")
            || lowerMessage.contains("access token")
    }

    /// In test mode, handle error, do not display if it is an authentication error
    /// - Parameters:
    ///   - error: Error occurred
    ///   - handler: Handler for non-authentication errors
    static func handleErrorInTestMode(_ error: Error, handler: (Error) -> Void) {
        if isTestMode && isAuthError(error) {
            print("Suppressed auth error in test mode: \(error.localizedDescription)")
        } else {
            handler(error)
        }
    }
}
