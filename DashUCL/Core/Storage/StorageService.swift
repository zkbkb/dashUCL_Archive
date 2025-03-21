import Foundation

protocol StorageServiceProtocol {
    func save<T: Codable>(_ data: T, for key: StorageKey) throws
    func load<T: Codable>(for key: StorageKey) throws -> T
    func clear(for key: StorageKey)
    func clearAll()
}

class StorageService: StorageServiceProtocol {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save<T: Codable>(_ data: T, for key: StorageKey) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: key.rawValue)
        } catch {
            throw StorageError.saveFailed(error)
        }
    }

    func load<T: Codable>(for key: StorageKey) throws -> T {
        guard let data = userDefaults.data(forKey: key.rawValue) else {
            throw StorageError.notFound
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.loadFailed(error)
        }
    }

    func clear(for key: StorageKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }

    func clearAll() {
        StorageKey.allCases.forEach { clear(for: $0) }
    }
}

enum StorageError: LocalizedError {
    case notFound
    case saveFailed(Error)
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Data not found in storage"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        }
    }
}

enum StorageKey: String, CaseIterable {
    case studySpaces
    case bookings
    case userProfile
    case timetable
}
