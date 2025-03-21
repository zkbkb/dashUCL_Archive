/*
 * Core networking layer that handles all HTTP requests to backend services.
 * Implements standardized error handling, request formatting, and response parsing.
 * Supports various request types including GET, POST with automatic JSON encoding/decoding.
 * Integrates with authentication system for secure API access and token management.
 */

import Foundation

// 导入Network模块以解决APIEndpoint引用问题

protocol NetworkServiceProtocol {
    func fetch<T: Codable>(endpoint: APIEndpoint) async throws -> T
    func post<T: Codable, R: Codable>(endpoint: APIEndpoint, body: T) async throws -> R
    func fetchRawData(endpoint: APIEndpoint) async throws -> Data
    func fetchRawData(endpoint: APIEndpoint, additionalQueryItems: [URLQueryItem]) async throws
        -> Data
    func fetchJSON(endpoint: APIEndpoint) async throws -> [String: Any]
    func fetchJSON(endpoint: APIEndpoint, queryParameters: [String: String]) async throws
        -> [String: Any]
}

class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let baseURL = "YOUR_SUPABASE_FUNCTIONS_URL/ucl-proxy"  // Supabase Functions URL
    private let authManager: AuthManager

    // 最大重试次数
    private let maxRetries = 2

    init(session: URLSession = .shared, authManager: AuthManager = .shared) {
        self.session = session
        self.authManager = authManager
    }

    // MARK: - 公共方法

    func fetch<T: Codable>(endpoint: APIEndpoint) async throws -> T {
        // 在测试模式下，不发送真实网络请求，直接抛出错误
        if TestEnvironment.shared.isTestMode {
            print("🔌 NetworkService: 测试模式下跳过API请求: \(endpoint.path)")
            throw NetworkError.testModeEnabled
        }

        print("=== API Request ===")
        print("Endpoint: \(endpoint.path)")

        // 可用于重试的变量
        var currentRetry = 0
        var lastError: Error? = nil

        // 循环重试
        while currentRetry <= maxRetries {
            // 获取token，优先使用测试模式下的模拟token
            let token: String
            if TestEnvironment.shared.isTestMode {
                token = TestConfig.mockToken
                print("Using mock token in test mode: \(token)")
            } else {
                guard let authToken = authManager.accessToken else {
                    print("Token authentication required")
                    throw NetworkError.unauthorized("Authentication required")
                }
                token = authToken
                print("Using token: \(token.prefix(10))..." + (token.count > 10 ? "..." : ""))
            }

            guard var components = URLComponents(string: baseURL + endpoint.path) else {
                print("Failed to create URL components")
                throw NetworkError.invalidURL
            }

            var queryItems = [
                URLQueryItem(name: "token", value: token)
            ]

            if let existingItems = components.queryItems {
                queryItems.append(contentsOf: existingItems)
            }
            components.queryItems = queryItems

            guard let url = components.url else {
                print("Failed to create URL from components")
                throw NetworkError.invalidURL
            }

            print("Making API request to: \(url)")
            print("Query parameters:")
            components.queryItems?.forEach { item in
                print("- \(item.name): \(item.value ?? "nil")")
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // 添加明确的Accept头
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            // 设置超时时间
            request.timeoutInterval = 15

            do {
                print("Sending request... (attempt \(currentRetry + 1)/\(maxRetries + 1))")
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    throw NetworkError.invalidResponse(statusCode: 0)
                }

                print("Response status code: \(httpResponse.statusCode)")
                print("Response headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("- \(key): \(value)")
                }

                // 检查内容类型，确保是JSON
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
                if !contentType.contains("application/json") {
                    print("Warning: Response content type is not JSON: \(contentType)")

                    // 记录响应内容以便调试
                    if let responseText = String(data: data, encoding: .utf8) {
                        let previewLength = min(responseText.count, 500)
                        print("Non-JSON response: \(responseText.prefix(previewLength))")

                        // 检查是否是HTML响应
                        if responseText.contains("<!DOCTYPE") || responseText.contains("<html") {
                            throw NetworkError.unexpectedResponseFormat(
                                "Received HTML instead of JSON. API endpoint may be down or authentication issue."
                            )
                        }
                    }

                    if currentRetry < maxRetries {
                        currentRetry += 1
                        // 添加短暂延迟后重试
                        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))  // 0.5秒
                        continue
                    } else {
                        throw NetworkError.unexpectedResponseFormat(
                            "Response is not JSON: \(contentType)")
                    }
                }

                if let responseString = String(data: data, encoding: .utf8) {
                    // 限制日志输出长度
                    let maxLength = 500
                    let truncated = responseString.count > maxLength
                    let previewText = responseString.prefix(maxLength)
                    print("Response body: \(previewText)\(truncated ? "..." : "")")
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    // 尝试解析错误响应
                    if let errorResponse = try? JSONDecoder().decode(
                        APIErrorResponse.self, from: data)
                    {
                        print("Server error: \(errorResponse.error ?? "Unknown error")")
                        throw NetworkError.serverErrorDetailed(
                            message: errorResponse.error ?? "Unknown error",
                            details: errorResponse.details,
                            statusCode: httpResponse.statusCode
                        )
                    } else if let errorText = String(data: data, encoding: .utf8) {
                        print("Server error: \(httpResponse.statusCode), Response: \(errorText)")
                        throw NetworkError.serverErrorDetailed(
                            message: "Server returned error",
                            details: errorText,
                            statusCode: httpResponse.statusCode
                        )
                    } else {
                        print("Server error: \(httpResponse.statusCode)")
                        throw NetworkError.serverErrorDetailed(
                            message: "Server error",
                            details: nil,
                            statusCode: httpResponse.statusCode
                        )
                    }
                }

                // 对于Codable类型，使用JSONDecoder
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                // 尝试解码
                do {
                    let result = try decoder.decode(T.self, from: data)
                    print("Successfully decoded response to \(T.self)")
                    return result
                } catch {
                    print("Decoding error: \(error)")

                    // 提供更详细的解码错误信息
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            let detailedError =
                                "Type mismatch: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                            print(detailedError)
                            throw NetworkError.decodingFailed(detailedError)

                        case .valueNotFound(let type, let context):
                            let detailedError =
                                "Value not found: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                            print(detailedError)
                            throw NetworkError.decodingFailed(detailedError)

                        case .keyNotFound(let key, let context):
                            let detailedError =
                                "Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                            print(detailedError)
                            throw NetworkError.decodingFailed(detailedError)

                        case .dataCorrupted(let context):
                            let detailedError =
                                "Data corrupted: \(context.debugDescription) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                            print(detailedError)
                            throw NetworkError.decodingFailed(detailedError)

                        @unknown default:
                            throw NetworkError.decodingFailed(error.localizedDescription)
                        }
                    } else {
                        throw NetworkError.decodingFailed(error.localizedDescription)
                    }
                }
            } catch {
                lastError = error

                // 如果是某些特定错误，不重试
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .invalidURL, .unauthorized, .decodingFailed:
                        throw error
                    default:
                        break
                    }
                }

                if currentRetry < maxRetries {
                    currentRetry += 1
                    let delay = pow(Double(2), Double(currentRetry)) * 0.1  // 指数退避策略
                    print("Request failed with error: \(error). Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw lastError!
                }
            }
        }

        // 如果退出循环但没有成功或抛出错误，则抛出最后一个错误
        if let lastError = lastError {
            throw lastError
        } else {
            throw NetworkError.unknown("Request failed after \(maxRetries) retries")
        }
    }

    func post<T: Codable, R: Codable>(endpoint: APIEndpoint, body: T) async throws -> R {
        // 在测试模式下，不发送真实网络请求，直接抛出错误
        if TestEnvironment.shared.isTestMode {
            print("🔌 NetworkService: 测试模式下跳过API请求: \(endpoint.path)")
            throw NetworkError.testModeEnabled
        }

        // 获取token，优先使用测试模式下的模拟token
        let token: String
        if TestEnvironment.shared.isTestMode {
            token = TestConfig.mockToken
            print("Using mock token in test mode: \(token)")
        } else {
            guard let authToken = authManager.accessToken else {
                print("Token authentication required")
                throw NSError(
                    domain: "NetworkService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
            }
            token = authToken
        }

        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        guard let url = urlComponents.url else {
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "NetworkService", code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "NetworkService", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(R.self, from: data)
    }

    func fetchRawData(endpoint: APIEndpoint) async throws -> Data {
        // 在测试模式下，不发送真实网络请求，直接抛出错误
        if TestEnvironment.shared.isTestMode {
            print("🔌 NetworkService: 测试模式下跳过API请求: \(endpoint.path)")
            throw NetworkError.testModeEnabled
        }

        print("=== API Raw Data Request ===")
        print("Endpoint: \(endpoint.path)")

        // 获取token，优先使用测试模式下的模拟token
        let token: String
        if TestEnvironment.shared.isTestMode {
            token = TestConfig.mockToken
            print("Using mock token in test mode: \(token)")
        } else {
            guard let authToken = authManager.accessToken else {
                print("Token authentication required")
                throw NSError(
                    domain: "NetworkService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
            }
            token = authToken
        }

        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            print("Failed to create URL components")
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        if let existingItems = components.queryItems {
            queryItems.append(contentsOf: existingItems)
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            print("Failed to create URL from components")
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        print("Making raw API request to: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw NSError(
                domain: "NetworkService", code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        print("Raw response status code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response: \(responseString)")
            }

            throw NSError(
                domain: "NetworkService", code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Server error with status: \(httpResponse.statusCode)"
                ])
        }

        return data
    }

    func fetchRawData(endpoint: APIEndpoint, additionalQueryItems: [URLQueryItem]) async throws
        -> Data
    {
        // 在测试模式下，不发送真实网络请求，直接抛出错误
        if TestEnvironment.shared.isTestMode {
            print("🔌 NetworkService: 测试模式下跳过API请求: \(endpoint.path)")
            throw NetworkError.testModeEnabled
        }

        print("=== API Raw Data Request with Custom Query ===")
        print("Endpoint: \(endpoint.path)")
        print(
            "Additional Query Parameters: \(additionalQueryItems.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: ", "))"
        )

        // 获取token，优先使用测试模式下的模拟token
        let token: String
        if TestEnvironment.shared.isTestMode {
            token = TestConfig.mockToken
            print("Using mock token in test mode: \(token)")
        } else {
            guard let authToken = authManager.accessToken else {
                print("Token authentication required")
                throw NSError(
                    domain: "NetworkService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
            }
            token = authToken
        }

        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            print("Failed to create URL components")
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        // 添加额外的查询参数
        queryItems.append(contentsOf: additionalQueryItems)

        if let existingItems = components.queryItems {
            queryItems.append(contentsOf: existingItems)
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            print("Failed to create URL from components")
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        print("Making raw API request to: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 添加Accept头，明确要求返回JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // 添加超时设置
        request.timeoutInterval = 15  // 增加超时时间到15秒

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw NSError(
                domain: "NetworkService", code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        print("Raw response status code: \(httpResponse.statusCode)")

        // 如果响应不成功，尝试解析错误消息
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw NSError(
                domain: "NetworkService", code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Server error with status: \(httpResponse.statusCode)"
                ])
        }

        // 返回原始响应数据
        return data
    }

    // 添加一个新方法来获取任意JSON数据，不需要Codable
    func fetchJSON(endpoint: APIEndpoint) async throws -> [String: Any] {
        // 在测试模式下，不发送真实网络请求，直接抛出错误
        if TestEnvironment.shared.isTestMode {
            print("🔌 NetworkService: 测试模式下跳过API请求: \(endpoint.path)")
            throw NetworkError.testModeEnabled
        }

        print("=== API Request (JSON) ===")
        print("Endpoint: \(endpoint.path)")

        // 获取token，优先使用测试模式下的模拟token
        let token: String
        if TestEnvironment.shared.isTestMode {
            token = TestConfig.mockToken
            print("Using mock token in test mode: \(token)")
        } else {
            guard let authToken = authManager.accessToken else {
                print("Token authentication required")
                throw NSError(
                    domain: "NetworkService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
            }
            token = authToken
            print("Using token: \(token)")
        }

        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            print("Failed to create URL components")
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        if let existingItems = components.queryItems {
            queryItems.append(contentsOf: existingItems)
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            print("Failed to create URL from components")
            throw NSError(
                domain: "NetworkService", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        print("Making API request to: \(url)")
        print("Query parameters:")
        components.queryItems?.forEach { item in
            print("- \(item.name): \(item.value ?? "nil")")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("Sending request...")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw NSError(
                domain: "NetworkService", code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        print("Response status code: \(httpResponse.statusCode)")
        print("Response headers:")
        httpResponse.allHeaderFields.forEach { key, value in
            print("- \(key): \(value)")
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("Response body: \(responseString)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("Server error: \(httpResponse.statusCode)")
            throw NSError(
                domain: "NetworkService", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }

        // 使用JSONSerialization解析
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return jsonObject
            } else {
                print("Failed to parse JSON into a dictionary")
                throw NSError(
                    domain: "NetworkService", code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "JSON parsing error"])
            }
        } catch {
            print("JSON serialization error: \(error)")
            throw error
        }
    }

    // 添加支持查询参数的JSON数据获取方法
    func fetchJSON(endpoint: APIEndpoint, queryParameters: [String: String]) async throws
        -> [String: Any]
    {
        // 在测试模式下，不发送真实网络请求，直接抛出错误
        if TestEnvironment.shared.isTestMode {
            print("🔌 NetworkService: 测试模式下跳过API请求: \(endpoint.path)")
            throw NetworkError.testModeEnabled
        }

        print("=== API Request (JSON with parameters) ===")
        print("Endpoint: \(endpoint.path)")
        print("Query parameters: \(queryParameters)")

        // 获取token，优先使用测试模式下的模拟token
        let token: String
        if TestEnvironment.shared.isTestMode {
            token = TestConfig.mockToken
            print("Using mock token in test mode: \(token)")
        } else {
            guard let authToken = authManager.accessToken else {
                print("Token authentication required")
                throw NetworkError.unauthorized("Authentication required")
            }
            token = authToken
            print("Using token: \(token)")
        }

        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            print("Failed to create URL components")
            throw NetworkError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        // 添加自定义查询参数
        for (key, value) in queryParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        if let existingItems = components.queryItems {
            queryItems.append(contentsOf: existingItems)
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            print("Failed to create URL from components")
            throw NetworkError.invalidURL
        }

        print("Making API request to: \(url)")
        print("Query parameters:")
        components.queryItems?.forEach { item in
            print("- \(item.name): \(item.value ?? "nil")")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 添加明确的Accept头
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 设置超时时间
        request.timeoutInterval = 15

        // 用于跟踪重试次数
        var currentRetry = 0
        var lastError: Error? = nil

        while currentRetry <= maxRetries {
            do {
                print("Sending request... (attempt \(currentRetry + 1)/\(maxRetries + 1))")
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    throw NetworkError.invalidResponse(statusCode: 0)
                }

                print("Response status code: \(httpResponse.statusCode)")

                // 检查内容类型，确保是JSON
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
                if !contentType.contains("application/json") {
                    print("Warning: Response content type is not JSON: \(contentType)")

                    // 记录响应内容以便调试
                    if let responseText = String(data: data, encoding: .utf8) {
                        let previewLength = min(responseText.count, 500)
                        print("Non-JSON response: \(responseText.prefix(previewLength))")
                    }

                    if currentRetry < maxRetries {
                        currentRetry += 1
                        // 添加短暂延迟后重试
                        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))  // 0.5秒
                        continue
                    } else {
                        throw NetworkError.unexpectedResponseFormat(
                            "Response is not JSON: \(contentType)")
                    }
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    // 尝试解析错误响应
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data)
                        as? [String: Any],
                        let errorMessage = errorResponse["error"] as? String
                    {
                        print("Server error: \(errorMessage)")
                        throw NetworkError.serverError(
                            statusCode: httpResponse.statusCode, message: errorMessage)
                    } else if let errorText = String(data: data, encoding: .utf8) {
                        print("Server error: \(httpResponse.statusCode), Response: \(errorText)")
                        throw NetworkError.serverError(
                            statusCode: httpResponse.statusCode,
                            message: "Status: \(httpResponse.statusCode), Body: \(errorText)")
                    } else {
                        print("Server error: \(httpResponse.statusCode)")
                        throw NetworkError.serverError(
                            statusCode: httpResponse.statusCode,
                            message: "HTTP \(httpResponse.statusCode)")
                    }
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        return json
                    } else {
                        throw NetworkError.unexpectedResponseFormat("Response is not a JSON object")
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    throw NetworkError.unexpectedResponseFormat(
                        "Failed to parse JSON: \(error.localizedDescription)")
                }
            } catch {
                lastError = error

                // 如果是某些特定错误，不重试
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .invalidURL, .unauthorized:
                        throw error
                    default:
                        break
                    }
                }

                if currentRetry < maxRetries {
                    currentRetry += 1
                    let delay = pow(Double(2), Double(currentRetry)) * 0.1  // 指数退避策略
                    print("Request failed with error: \(error). Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw lastError!
                }
            }
        }

        // 如果退出循环但没有成功或抛出错误，则抛出最后一个错误
        if let lastError = lastError {
            throw lastError
        } else {
            throw NetworkError.unknown("Request failed after \(maxRetries) retries")
        }
    }

    func fetchJSON(endpoint: APIEndpoint, additionalQueryItems: [URLQueryItem]? = nil) async throws
        -> [String: Any]
    {
        let data = try await fetchRawData(
            endpoint: endpoint, additionalQueryItems: additionalQueryItems ?? [])

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                #if DEBUG
                    if endpoint.path == APIEndpoint.workspacesSensorsSummary.path {
                        print("DEBUG: workspacesSensorsSummary原始数据结构：\(json.keys)")
                        if let surveys = json["surveys"] as? [[String: Any]] {
                            if !surveys.isEmpty {
                                let firstSurvey = surveys[0]
                                print("DEBUG: 示例survey数据结构: \(firstSurvey.keys)")
                                print("DEBUG: survey总计: \(surveys.count)")
                            }
                        }
                    }
                #endif
                return json
            }
            throw NetworkError.invalidResponse(statusCode: 0)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
}
