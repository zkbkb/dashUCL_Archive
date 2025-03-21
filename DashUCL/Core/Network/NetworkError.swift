/*
 * Comprehensive error types for network operations with detailed failure information.
 * Implements LocalizedError for consistent error message presentation across the app.
 * Provides specific error cases for different network failure scenarios.
 * Includes detailed debugging information for development and error reporting.
 */

import Foundation

/// Network error types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(String)
    case serverError(statusCode: Int, message: String? = nil)
    case serverErrorDetailed(message: String, details: String?, statusCode: Int)
    case connectionFailed
    case unauthorized(String)
    case noData(String)
    case parseError(String)
    case unexpectedResponseFormat(String)
    case unknown(String)
    case testModeEnabled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse(let statusCode):
            return "Invalid response with status code: \(statusCode)"
        case .decodingFailed(let message):
            return "Failed to decode response: \(message)"
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error with status code: \(statusCode)"
        case .serverErrorDetailed(let message, let details, let statusCode):
            if let details = details {
                return "Server error (\(statusCode)): \(message). Details: \(details)"
            }
            return "Server error (\(statusCode)): \(message)"
        case .connectionFailed:
            return "Connection failed"
        case .unauthorized(let message):
            return message
        case .noData(let message):
            return message
        case .parseError(let message):
            return message
        case .unexpectedResponseFormat(let message):
            return "Unexpected response format: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .testModeEnabled:
            return "Network requests are disabled in test mode"
        }
    }

    static func decodingError(_ message: String) -> NetworkError {
        return .decodingFailed(message)
    }
}

/// API错误响应模型
struct APIErrorResponse: Codable {
    let ok: Bool?
    let error: String?
    let details: String?
    let endpoint: String?
    let status: Int?
}
