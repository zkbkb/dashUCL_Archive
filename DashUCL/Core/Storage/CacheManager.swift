/*
 * High-performance caching system for API responses and application data.
 * Implements a two-level cache (memory and disk) with automatic expiration.
 * Uses Swift's actor model to ensure thread-safe concurrent access.
 * Provides automatic cleanup mechanisms to prevent excessive storage usage.
 */

import Foundation

actor CacheManager {
    static let shared = CacheManager()

    private let memoryCache = NSCache<NSString, CacheEntryClass>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private class CacheEntryClass: NSObject {
        let data: Data
        let timestamp: Date
        let expirationInterval: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) >= expirationInterval
        }

        init(data: Data, timestamp: Date, expirationInterval: TimeInterval) {
            self.data = data
            self.timestamp = timestamp
            self.expirationInterval = expirationInterval
            super.init()
        }
    }

    private struct CacheEntryStruct: Codable {
        let data: Data
        let timestamp: Date
        let expirationInterval: TimeInterval
    }

    private init() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cacheURL.appendingPathComponent("com.Kaibin-Zhang.Dash-UCL.cache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // 设置内存缓存限制
        memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50MB

        // 启动定期清理
        Task {
            await startCacheCleanup()
        }
    }

    func cache<T: Encodable>(_ object: T, forKey key: String) async throws {
        let data = try JSONEncoder().encode(object)
        let entry = CacheEntryClass(
            data: data,
            timestamp: Date(),
            expirationInterval: 24 * 60 * 60  // 24小时
        )

        // 存储到内存缓存
        memoryCache.setObject(entry, forKey: key as NSString)

        // 存储到磁盘
        let diskEntry = CacheEntryStruct(
            data: data,
            timestamp: entry.timestamp,
            expirationInterval: entry.expirationInterval
        )
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try JSONEncoder().encode(diskEntry).write(to: fileURL)
    }

    func retrieve<T: Decodable>(forKey key: String) async throws -> T {
        // 检查内存缓存
        if let entry = memoryCache.object(forKey: key as NSString) {
            if !entry.isExpired {
                return try JSONDecoder().decode(T.self, from: entry.data)
            }
        }

        // 检查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL),
            let entry = try? JSONDecoder().decode(CacheEntryStruct.self, from: data),
            Date().timeIntervalSince(entry.timestamp) < entry.expirationInterval
        else {
            throw CacheError.notFound
        }

        // 更新内存缓存
        let memoryEntry = CacheEntryClass(
            data: entry.data,
            timestamp: entry.timestamp,
            expirationInterval: entry.expirationInterval
        )
        memoryCache.setObject(memoryEntry, forKey: key as NSString)

        return try JSONDecoder().decode(T.self, from: entry.data)
    }

    private func startCacheCleanup() async {
        while true {
            cleanExpiredCache()
            try? await Task.sleep(nanoseconds: 3600 * 1_000_000_000)  // 每小时清理一次
        }
    }

    private func cleanExpiredCache() {
        // 清理内存缓存
        memoryCache.removeAllObjects()

        // 清理磁盘缓存
        guard
            let contents = try? fileManager.contentsOfDirectory(
                at: cacheDirectory, includingPropertiesForKeys: nil)
        else { return }

        for url in contents {
            guard let data = try? Data(contentsOf: url),
                let entry = try? JSONDecoder().decode(CacheEntryStruct.self, from: data),
                Date().timeIntervalSince(entry.timestamp) >= entry.expirationInterval
            else { continue }

            try? fileManager.removeItem(at: url)
        }
    }

    func clearAll() async throws {
        // 清理内存缓存
        memoryCache.removeAllObjects()

        // 清理磁盘缓存
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }
}

enum CacheError: Error {
    case notFound
    case expired
    case invalidData
}

// 为CacheManager添加向后兼容的接口
extension CacheManager {
    /// 向后兼容的缓存保存方法
    func save<T: Encodable>(_ object: T, forKey key: String) {
        Task {
            try? await cache(object, forKey: key)
        }
    }

    /// 向后兼容的缓存加载方法
    func load<T: Decodable>(forKey key: String) -> T? {
        // 创建一个同步获取异步结果的工具
        let semaphore = DispatchSemaphore(value: 0)
        var result: T? = nil

        Task {
            do {
                result = try await retrieve(forKey: key)
                semaphore.signal()
            } catch {
                print("Failed to load cached data: \(error)")
                semaphore.signal()
            }
        }

        // 等待异步操作完成，超时设为1秒
        _ = semaphore.wait(timeout: .now() + 1.0)

        return result
    }
}
