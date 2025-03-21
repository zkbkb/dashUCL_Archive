/*
 * Core service that handles all data operations with UCL's APIs and local storage.
 * Implements caching strategies for offline access and reducing network requests.
 * Manages real-time data for campus facilities, timetables, and user bookings.
 * Uses a singleton pattern with MainActor for thread-safe UI updates.
 */

import Foundation
import SwiftUI

/// UCLDataManager is a singleton class responsible for fetching and managing all data from the UCL API.
/// It handles data fetching, caching, and automatic refresh mechanisms.
@MainActor
class UCLDataManager: ObservableObject {
    static let shared = UCLDataManager()

    // MARK: - Service Dependencies
    private let networkService = NetworkService()
    private let cacheManager = CacheManager.shared

    // MARK: - Status Properties
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Data Properties
    @Published private(set) var librarySpaces: [LibrarySpace] = [] {
        didSet {
            sendDataUpdateNotification()
        }
    }
    @Published private(set) var rooms: [Room] = [] {
        didSet {
            sendDataUpdateNotification()
        }
    }
    @Published private(set) var userBookings: [Booking] = [] {
        didSet {
            sendDataUpdateNotification()
        }
    }

    // Data update time
    @Published private(set) var lastLibraryUpdate: Date? {
        didSet {
            sendDataUpdateNotification()
        }
    }
    @Published private(set) var lastRoomsUpdate: Date? {
        didSet {
            sendDataUpdateNotification()
        }
    }
    @Published private(set) var lastBookingsUpdate: Date? {
        didSet {
            sendDataUpdateNotification()
        }
    }

    // Auto-refresh timer
    private var libraryRefreshTask: Task<Void, Never>?

    // Refresh interval (seconds)
    private let libraryRefreshInterval: TimeInterval = 300  // 5 minutes

    // MARK: - Initialization
    private init() {
        // Load cached data
        Task {
            await loadCachedData()
            await startAutoRefresh()
        }
    }

    deinit {
        // Stop refresh on main thread
        Task { @MainActor [weak self] in
            self?.stopAutoRefresh()
        }
    }

    // MARK: - Notifications
    private func sendDataUpdateNotification() {
        NotificationCenter.default.post(name: .uclDataManagerDidUpdate, object: self)
    }

    // MARK: - Cache Management
    private func loadCachedData() async {
        // Try to load data from cache
        if let cachedSpaces: [LibrarySpace] = try? await cacheManager.retrieve(
            forKey: "librarySpaces")
        {
            self.librarySpaces = cachedSpaces
        }

        if let cachedRooms: [Room] = try? await cacheManager.retrieve(forKey: "rooms") {
            self.rooms = cachedRooms
        }

        if let cachedBookings: [Booking] = try? await cacheManager.retrieve(
            forKey: "userBookings")
        {
            self.userBookings = cachedBookings
        }

        if let lastLibUpdate: Date = try? await cacheManager.retrieve(
            forKey: "lastLibraryUpdate")
        {
            self.lastLibraryUpdate = lastLibUpdate
        }

        if let lastRoomsUpdate: Date = try? await cacheManager.retrieve(
            forKey: "lastRoomsUpdate")
        {
            self.lastRoomsUpdate = lastRoomsUpdate
        }

        if let lastBookingsUpdate: Date = try? await cacheManager.retrieve(
            forKey: "lastBookingsUpdate")
        {
            self.lastBookingsUpdate = lastBookingsUpdate
        }

        // Send cache load completion notification
        sendDataUpdateNotification()
    }

    // MARK: - Auto-refresh Management
    func startAutoRefresh() async {
        stopAutoRefresh()

        // Library auto-refresh
        libraryRefreshTask = Task {
            while !Task.isCancelled {
                await refreshLibrarySpaces()
                try? await Task.sleep(nanoseconds: UInt64(libraryRefreshInterval * 1_000_000_000))
            }
        }
    }

    func stopAutoRefresh() {
        libraryRefreshTask?.cancel()
    }

    // MARK: - Data Fetching Methods

    /// Refresh all data
    func refreshAll() async {
        isLoading = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshLibrarySpaces() }
            group.addTask { await self.fetchRooms() }
            group.addTask { await self.fetchUserBookings() }
        }

        isLoading = false
        sendDataUpdateNotification()
    }

    /// Get library space data
    /// API endpoint: /workspaces/sensors/summary
    func refreshLibrarySpaces() async {
        do {
            isLoading = true

            // Check if task is cancelled
            try Task.checkCancellation()

            print("Starting to fetch library space data...")

            // Fetch raw data from API
            let rawData = try await networkService.fetchRawData(endpoint: .studySpaces)

            // Check if task is cancelled
            try Task.checkCancellation()

            // Record API response
            if let jsonString = String(data: rawData, encoding: .utf8) {
                print("Raw API response length: \(jsonString.count) characters")
                let preview = String(jsonString.prefix(200))
                print("Response preview: \(preview)...")
            }

            // Configure decoder
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            // Try different decoding methods
            let summaries: [StudySpaceSummary]

            do {
                // Decode directly as array
                summaries = try decoder.decode([StudySpaceSummary].self, from: rawData)
                print("Successfully decoded array directly")
            } catch {
                print("Direct array decoding failed: \(error)")

                // Check if task is cancelled
                try Task.checkCancellation()

                // Try decoding from wrapper structure
                do {
                    let wrapper = try decoder.decode(StudySpaceResponse.self, from: rawData)
                    if let surveys = wrapper.surveys {
                        summaries = surveys
                        print("Decoded from surveys wrapper")
                    } else if let data = wrapper.data, let spaces = data.spaces {
                        summaries = spaces
                        print("Decoded from data.spaces wrapper")
                    } else if let data = wrapper.data, let surveys = data.surveys {
                        summaries = surveys
                        print("Decoded from data.surveys wrapper")
                    } else {
                        throw NSError(
                            domain: "UCLDataManager",
                            code: -4,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Could not find study spaces in response"
                            ]
                        )
                    }
                } catch {
                    print("Wrapper decoding failed: \(error)")

                    // Check if task is cancelled
                    try Task.checkCancellation()

                    // Finally try using network service's fetch method
                    print("Attempting to use NetworkService fetch method as fallback...")
                    summaries = try await networkService.fetch(endpoint: .studySpaces)
                }
            }

            // Sort by name
            let sortedSummaries = summaries.sorted { $0.name < $1.name }

            // Convert to application model
            var spaces = [LibrarySpace]()
            for summary in sortedSummaries {
                // Ensure data is valid
                let availableSeats = max(0, summary.sensorsTotal - summary.sensorsOccupied)
                let totalCapacity = max(1, summary.sensorsTotal)

                let space = LibrarySpace(
                    id: String(summary.id),
                    name: summary.name,
                    availableSeats: availableSeats,
                    totalCapacity: totalCapacity,
                    lastUpdated: Date(),
                    location: "UCL Campus",
                    isAccessible: true,
                    averageOccupancy: Double(summary.sensorsOccupied) / Double(totalCapacity)
                )
                spaces.append(space)
            }

            print("Processed \(spaces.count) library spaces with real data")

            // Update data and timestamp
            self.librarySpaces = spaces
            self.lastLibraryUpdate = Date()

            // Cache data
            try await cacheManager.cache(spaces, forKey: "librarySpaces")
            try await cacheManager.cache(self.lastLibraryUpdate!, forKey: "lastLibraryUpdate")

            print("Library space data updated and cached")

        } catch _ as CancellationError {
            print("Library space fetch was cancelled")
        } catch let decodingError as DecodingError {
            // Log decoding error in detail
            print("Decoding error: \(decodingError)")

            // Extract main error message
            let errorMessage = decodingError.localizedDescription

            self.errorMessage = "Error parsing library space data: \(errorMessage)"
            self.showError = true
            sendDataUpdateNotification()
        } catch {
            print("Failed to fetch library space data: \(error)")

            var errorMsg = error.localizedDescription
            if let range = errorMsg.range(of: "Error creating the CFMessagePort") {
                errorMsg = String(errorMsg[..<range.lowerBound])
            }

            if !errorMsg.contains("cancelled") {
                self.errorMessage = "Unable to load library spaces: \(errorMsg)"
                self.showError = true
                sendDataUpdateNotification()
            }
        }

        isLoading = false
        sendDataUpdateNotification()
    }

    /// Get meeting room data
    /// API endpoint: /roombookings/rooms
    func fetchRooms() async {
        isLoading = true

        do {
            // Check if task is cancelled
            try Task.checkCancellation()

            print("Starting to fetch room data...")

            // Use updated API endpoint
            let roomData = try await networkService.fetchRawData(endpoint: .rooms)

            // Print raw JSON for debugging
            if let jsonString = String(data: roomData, encoding: .utf8) {
                print("Raw room data: \(jsonString.prefix(500))...")  // Print first 500 characters for debugging
            }

            // Parse room data
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                // First try parsing as RoomResponse format
                let response = try decoder.decode(RoomResponse.self, from: roomData)
                print("Successfully decoded room response with ok=\(response.ok ?? false)")

                if let rooms = response.rooms {
                    self.rooms = rooms
                    self.lastRoomsUpdate = Date()

                    // Cache data
                    try await cacheManager.cache(rooms, forKey: "rooms")
                    try await cacheManager.cache(self.lastRoomsUpdate!, forKey: "lastRoomsUpdate")

                    print("Successfully processed \(rooms.count) rooms")
                } else {
                    // If rooms is nil, try parsing as another possible format
                    print("No rooms in response, trying alternative format...")

                    do {
                        // Try parsing as [Room] format
                        let rooms = try decoder.decode([Room].self, from: roomData)
                        self.rooms = rooms
                        self.lastRoomsUpdate = Date()

                        // Cache data
                        try await cacheManager.cache(rooms, forKey: "rooms")
                        try await cacheManager.cache(
                            self.lastRoomsUpdate!, forKey: "lastRoomsUpdate")

                        print("Successfully processed \(rooms.count) rooms from alternative format")
                    } catch {
                        errorMessage = "Failed to parse room data: \(error.localizedDescription)"
                        showError = true
                        print("Failed to parse room data in alternative format: \(error)")
                    }
                }
            } catch {
                print("Failed to decode room data as RoomResponse: \(error)")

                // Try parsing directly as [Room]
                do {
                    let rooms = try decoder.decode([Room].self, from: roomData)
                    self.rooms = rooms
                    self.lastRoomsUpdate = Date()

                    // Cache data
                    try await cacheManager.cache(rooms, forKey: "rooms")
                    try await cacheManager.cache(self.lastRoomsUpdate!, forKey: "lastRoomsUpdate")

                    print("Successfully processed \(rooms.count) rooms directly")
                } catch let secondError {
                    print("Failed to parse room data directly: \(secondError)")
                    errorMessage = "Failed to load rooms: \(error.localizedDescription)"
                    showError = true

                    // If API call fails, try loading from cache
                    if self.rooms.isEmpty,
                        let cachedRooms: [Room] = try? await cacheManager.retrieve(forKey: "rooms")
                    {
                        self.rooms = cachedRooms
                        if let lastUpdate: Date = try? await cacheManager.retrieve(
                            forKey: "lastRoomsUpdate")
                        {
                            self.lastRoomsUpdate = lastUpdate
                            errorMessage = "Using cached room data from \(lastUpdate.formatted())"
                        }
                    }
                }
            }
        } catch _ as CancellationError {
            print("Room data fetch was cancelled")
        } catch {
            print("Failed to fetch room data: \(error)")
            errorMessage = "Failed to load rooms: \(error.localizedDescription)"
            showError = true

            // If API call fails, try loading from cache
            if self.rooms.isEmpty,
                let cachedRooms: [Room] = try? await cacheManager.retrieve(forKey: "rooms")
            {
                self.rooms = cachedRooms
                if let lastUpdate: Date = try? await cacheManager.retrieve(
                    forKey: "lastRoomsUpdate")
                {
                    self.lastRoomsUpdate = lastUpdate
                    errorMessage = "Using cached room data from \(lastUpdate.formatted())"
                }
            }
        }

        isLoading = false
        sendDataUpdateNotification()
    }

    /// Get user booking data
    /// API endpoint: /libcal/space/bookings
    func fetchUserBookings() async {
        isLoading = true

        // Check if in test mode
        if TestEnvironment.shared.isTestMode {
            print("Using mock bookings data in test mode")
            self.userBookings = TestUserData.bookings
            self.lastBookingsUpdate = Date()
            isLoading = false
            sendDataUpdateNotification()
            return
        }

        do {
            // Check if task is cancelled
            try Task.checkCancellation()

            print("Starting to fetch user bookings...")

            // Get user booking data
            let bookingData = try await networkService.fetchRawData(endpoint: .bookings)

            // Print raw JSON for debugging
            if let jsonString = String(data: bookingData, encoding: .utf8) {
                print("Raw booking data: \(jsonString.prefix(500))...")  // Print first 500 characters for debugging
            }

            // Parse booking data
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            // Try parsing in standard format
            do {
                let response = try decoder.decode(BookingResponse.self, from: bookingData)

                if let bookings = response.bookings, !bookings.isEmpty {
                    self.userBookings = bookings
                    self.lastBookingsUpdate = Date()

                    // Cache data
                    try await cacheManager.cache(bookings, forKey: "userBookings")
                    try await cacheManager.cache(
                        self.lastBookingsUpdate!, forKey: "lastBookingsUpdate")

                    print("Successfully processed \(bookings.count) bookings")
                } else {
                    // Check if there is an error message
                    if let error = response.error {
                        print("API returned error: \(error)")
                        errorMessage = error
                    } else {
                        print("No bookings found")
                        // This might be normal - user might have no bookings
                        self.userBookings = []
                        self.lastBookingsUpdate = Date()
                    }

                    // Try loading from cache
                    loadBookingsFromCache()
                }
            } catch {
                print("Standard format parsing failed: \(error), trying alternative format...")

                // Try parsing as alternative format (e.g., LibCal format)
                do {
                    // Use full type name
                    let alternativeData =
                        try JSONSerialization.jsonObject(with: bookingData, options: [])
                        as? [String: Any]

                    // Manually extract needed data
                    if let bookingData = alternativeData?["data"] as? [[String: Any]],
                        let firstBooking = bookingData.first
                    {

                        let id = firstBooking["booking_id"] as? String ?? UUID().uuidString
                        let eid = firstBooking["eid"] as? Int ?? 0
                        let lid = firstBooking["lid"] as? Int ?? 0

                        // Parse date
                        let dateFormatter = ISO8601DateFormatter()
                        let fromDateStr = firstBooking["from_date"] as? String ?? ""
                        let toDateStr = firstBooking["to_date"] as? String ?? ""
                        let fromDate = dateFormatter.date(from: fromDateStr) ?? Date()
                        let toDate = dateFormatter.date(from: toDateStr) ?? Date()

                        let status = firstBooking["status"] as? String ?? ""
                        let cancelledStr = firstBooking["cancelled"] as? String
                        let cancelled =
                            cancelledStr != nil ? dateFormatter.date(from: cancelledStr!) : nil

                        // Create booking
                        let booking = Booking(
                            id: id,
                            resourceId: "\(lid)_\(eid)",
                            resourceType: .librarySpace,
                            startTime: fromDate,
                            endTime: toDate,
                            status: cancelled != nil
                                ? .cancelled : (status == "confirmed" ? .confirmed : .pending),
                            notes: nil
                        )

                        self.userBookings = [booking]
                        self.lastBookingsUpdate = Date()

                        // Cache data
                        try await cacheManager.cache(self.userBookings, forKey: "userBookings")
                        try await cacheManager.cache(
                            self.lastBookingsUpdate!, forKey: "lastBookingsUpdate")

                        print("Successfully processed a booking manually")
                    } else {
                        print("No booking data found in alternative format")
                        errorMessage = "No booking data available"
                        showError = true

                        // Try loading from cache
                        loadBookingsFromCache()
                    }
                } catch let alternativeError {
                    print("Alternative format parsing also failed: \(alternativeError)")
                    errorMessage = "Failed to parse booking data: \(error.localizedDescription)"
                    showError = true

                    // Try loading from cache
                    loadBookingsFromCache()
                }
            }

        } catch _ as CancellationError {
            print("Booking data fetch was cancelled")
        } catch {
            print("Failed to fetch booking data: \(error)")
            errorMessage = "Failed to load bookings: \(error.localizedDescription)"
            showError = true

            // If API call fails, try loading from cache
            loadBookingsFromCache()
        }

        isLoading = false
        sendDataUpdateNotification()
    }

    // Helper function to load bookings from cache
    private func loadBookingsFromCache() {
        Task {
            if let cachedBookings: [Booking] = try? await cacheManager.retrieve(
                forKey: "userBookings")
            {
                await MainActor.run {
                    self.userBookings = cachedBookings
                }

                if let lastUpdate: Date = try? await cacheManager.retrieve(
                    forKey: "lastBookingsUpdate")
                {
                    await MainActor.run {
                        self.lastBookingsUpdate = lastUpdate
                        self.errorMessage =
                            "Using cached booking data from \(lastUpdate.formatted())"
                    }
                }
            }
        }
    }

    // MARK: - Booking related methods

    /// Create resource booking
    /// API endpoint: /libcal/space/book
    func bookResource(
        type: ResourceType,
        resourceId: String,
        startTime: Date,
        endTime: Date,
        notes: String? = nil
    ) async -> Bool {
        isLoading = true

        do {
            // Create booking request
            let request = BookingRequest(
                resourceId: resourceId,
                startTime: startTime,
                endTime: endTime,
                notes: notes
            )

            // Directly declare return type, let compiler infer generic parameters
            let response: BookingResponse = try await networkService.post(
                endpoint: .createBooking,
                body: request
            )

            // Handle response
            if let newBooking = response.bookings?.first {
                // Add new booking to local data
                userBookings.append(newBooking)

                // Cache updated booking list
                try await cacheManager.cache(userBookings, forKey: "userBookings")

                isLoading = false
                return true
            } else {
                errorMessage = "Booking created but no confirmation received"
                showError = true
            }
        } catch {
            errorMessage = "Failed to create booking: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
        return false
    }

    /// Cancel booking
    /// API endpoint: /libcal/space/cancel/{id}
    func cancelBooking(_ booking: Booking) async -> Bool {
        isLoading = true

        do {
            // Call cancel booking API
            // Need to explicitly specify return type to avoid generic inference error
            let _: EmptyResponse = try await networkService.fetch(
                endpoint: .cancelBooking(id: booking.id))

            // If API call is successful, remove booking from local data
            userBookings.removeAll { $0.id == booking.id }

            // Update cache
            try await cacheManager.cache(userBookings, forKey: "userBookings")

            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to cancel booking: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
        return false
    }

    /// Get available booking slots
    /// API endpoint: /libcal/space/item/{resourceId}/availability/{date}
    func getAvailableSlots(
        for resourceId: String,
        type: ResourceType,
        date: Date
    ) async -> [BookingSlot] {
        isLoading = true

        do {
            // Format date as YYYY-MM-DD
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)

            // Call API to get available slots
            // Need to explicitly specify return type to avoid generic inference error
            let slots: [BookingSlot] = try await networkService.fetch(
                endpoint: .availableSlots(resourceId: resourceId, date: dateString)
            )

            isLoading = false
            return slots
        } catch {
            errorMessage = "Failed to fetch available slots: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
        return []
    }

    // MARK: - Helper methods

    /// Clear all errors
    func clearErrors() {
        errorMessage = nil
        showError = false
        sendDataUpdateNotification()
    }

    /// Clear all cache
    func clearCache() async {
        do {
            try await cacheManager.clearAll()
            librarySpaces = []
            rooms = []
            userBookings = []
            lastLibraryUpdate = nil
            lastRoomsUpdate = nil
            lastBookingsUpdate = nil

            print("Successfully cleared all cache")
            sendDataUpdateNotification()
        } catch {
            print("Failed to clear cache: \(error)")
            errorMessage = "Failed to clear cache: \(error.localizedDescription)"
            showError = true
            sendDataUpdateNotification()
        }
    }
}

// MARK: - API response models

/// Meeting room API response
struct RoomResponse: Codable {
    let ok: Bool?
    let rooms: [Room]?

    enum CodingKeys: String, CodingKey {
        case ok
        case rooms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ok = try container.decodeIfPresent(Bool.self, forKey: .ok)

        // Try to decode rooms array
        do {
            rooms = try container.decodeIfPresent([Room].self, forKey: .rooms)
        } catch {
            print("Error decoding rooms array: \(error)")

            // If that fails, it might be because the response has a different structure
            // The API might return rooms directly without wrapping them in a "rooms" field
            if let roomsNestedContainer = try? container.nestedUnkeyedContainer(forKey: .rooms) {
                // Parse each room from the nested container
                var roomsArray: [Room] = []
                var nestedContainer = roomsNestedContainer

                while !nestedContainer.isAtEnd {
                    if let room = try? nestedContainer.decode(Room.self) {
                        roomsArray.append(room)
                    } else {
                        // Skip invalid entries
                        _ = try? nestedContainer.decode(EmptyDecodable.self)
                    }
                }

                rooms = roomsArray.isEmpty ? nil : roomsArray
            } else {
                rooms = nil
            }
        }
    }
}

/// Helper for skipping invalid entries in arrays
struct EmptyDecodable: Decodable {}

/// Define extended Room model to match UCL API
extension Room {
    // Alternative key names
    enum AlternativeKeys: String, CodingKey {
        case roomid
        case roomname
        case roomclass
        case capacity
        case sitename
        case address1, address2, address3, address4
        case bookabletype
    }

    init(from decoder: Decoder) throws {
        // Function to map roomclass string to RoomType enum (defined locally to avoid using self)
        func mapRoomClass(_ roomClass: String) -> RoomType {
            let lowercased = roomClass.lowercased()
            if lowercased.contains("lecture") || lowercased.contains("lt") {
                return .lectureTheatre
            } else if lowercased.contains("lab") {
                return .laboratory
            } else if lowercased.contains("computer") || lowercased.contains("cluster") {
                return .computerCluster
            } else if lowercased.contains("social") {
                return .socialSpace
            } else {
                return .classroom
            }
        }

        // Function to extract floor from room name (defined locally to avoid using self)
        func extractFloor(from roomName: String) -> String {
            if let firstChar = roomName.first, firstChar.isLetter {
                return String(firstChar)
            } else if roomName.count >= 1, roomName.first!.isNumber {
                return String(roomName.first!)
            }
            return "G"
        }

        // Get primary container
        let container = try decoder.container(keyedBy: Room.CodingKeys.self)
        var id: String

        // Try to decode ID (required field)
        do {
            id = try container.decode(String.self, forKey: .id)
        } catch {
            // Try alternative container if primary fails
            let altContainer = try decoder.container(keyedBy: AlternativeKeys.self)
            id = try altContainer.decode(String.self, forKey: .roomid)
        }

        // Decode other fields with defaults
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Room"

        // Decode room type
        let type: RoomType
        if let typeString = try container.decodeIfPresent(String.self, forKey: .type) {
            type = RoomType(rawValue: typeString) ?? .classroom
        } else {
            // Try alternative container
            let altContainer = try? decoder.container(keyedBy: AlternativeKeys.self)
            if let roomClass = try altContainer?.decodeIfPresent(String.self, forKey: .roomclass) {
                type = mapRoomClass(roomClass)
            } else {
                type = .classroom
            }
        }

        // Decode capacity
        let capacity: Int
        if let capacityValue = try container.decodeIfPresent(Int.self, forKey: .capacity) {
            capacity = capacityValue
        } else {
            let altContainer = try? decoder.container(keyedBy: AlternativeKeys.self)
            if let doubleCapacity = try altContainer?.decodeIfPresent(
                Double.self, forKey: .capacity)
            {
                capacity = Int(doubleCapacity)
            } else {
                capacity = 0
            }
        }

        // Decode building
        let building: String
        if let buildingValue = try container.decodeIfPresent(String.self, forKey: .building) {
            building = buildingValue
        } else {
            let altContainer = try? decoder.container(keyedBy: AlternativeKeys.self)
            if let siteName = try altContainer?.decodeIfPresent(String.self, forKey: .sitename) {
                building = siteName
            } else {
                building = "Unknown Building"
            }
        }

        // Decode remaining fields with defaults
        let floor =
            try container.decodeIfPresent(String.self, forKey: .floor) ?? extractFloor(from: name)
        let equipment =
            try container.decodeIfPresent([RoomEquipment].self, forKey: .equipment) ?? []
        let isAccessible = try container.decodeIfPresent(Bool.self, forKey: .isAccessible) ?? false
        let images = try container.decodeIfPresent([URL].self, forKey: .images) ?? []

        // Initialize all properties
        self.id = id
        self.name = name
        self.type = type
        self.capacity = capacity
        self.building = building
        self.floor = floor
        self.equipment = equipment
        self.isAccessible = isAccessible
        self.images = images
    }
}

/// Booking API response
struct BookingResponse: Codable {
    let ok: Bool?
    let bookings: [Booking]?
    let error: String?
}

/// Booking request
struct BookingRequest: Codable {
    let resourceId: String
    let startTime: Date
    let endTime: Date
    let notes: String?
}

/// Type for empty response
struct EmptyResponse: Codable {
    let ok: Bool?
}
