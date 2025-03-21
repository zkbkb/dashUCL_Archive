// Import error handling tools
import Foundation
import SwiftUI

// MARK: - ViewMode enum
enum ViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

// MARK: - ModuleDetails struct
struct ModuleDetails: Identifiable, Codable {
    var id: String
    var name: String
    var departmentId: String
    var departmentName: String
    var moduleCode: String

    // Optional information
    var description: String?
    var lecturerName: String?
    var lecturerEmail: String?
}

@MainActor
class TimetableViewModel: ObservableObject {
    // Published properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var allEvents: [TimetableEvent] = []
    @Published var currentEvents: [TimetableEvent] = []
    @Published var lastUpdated: Date?
    @Published var selectedDate: Date = Date()
    @Published var weekStartDate: Date?
    @Published var viewMode: ViewMode = .week
    @Published var currentModule: ModuleDetails?

    // Test mode flag - Don't show authentication errors in test mode
    let isTestMode = true  // Set to true to ignore authentication errors in test mode

    // Data storage
    var eventsByDate: [Date: [TimetableEvent]] = [:]  // Events indexed by date
    @Published var selectedDateEvents: [TimetableEvent] = []  // Events for the selected date

    // Debounce control variables
    private var updateEventsTask: Task<Void, Never>? = nil
    private var lastUpdateTime: Date? = nil
    private let updateThrottleInterval: TimeInterval = 0.3  // 300ms debounce interval

    // Refresh rate control - Add minimum refresh interval to prevent frequent refreshes
    private let minimumRefreshInterval: TimeInterval = 300  // 5 minutes
    private var canRefresh: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) >= minimumRefreshInterval
    }

    // Service dependencies
    private let networkService: NetworkService
    private let cacheManager: CacheManager

    // Add date string cache to avoid repeated calculations
    private var dateStringCache: [Date: String] = [:]
    private var normalizedDateCache: [Date: Date] = [:]
    private var dateStringToEventsCache: [String: [TimetableEvent]]? = nil

    init(networkService: NetworkService = .init(), cacheManager: CacheManager = .shared) {
        self.networkService = networkService
        self.cacheManager = cacheManager

        // Try to load data from cache
        Task {
            await loadCachedData()
        }

        // Add notification observer for app entering foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Add notification observer for user data updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDataDidUpdate),
            name: .userDataDidUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Handle app entering foreground event
    @objc private func handleAppWillEnterForeground() {
        print("📅 TimetableViewModel: App entered foreground, checking if data refresh is needed")

        // If in test mode, reload data
        if TestEnvironment.shared.isTestMode {
            print("📅 TimetableViewModel: Reloading data in test mode")
            Task {
                try? await self.fetchTimetable()
            }
        }
    }

    // Handle user data update notification
    @objc private func handleUserDataDidUpdate() {
        print("📅 TimetableViewModel: Received user data update notification")

        // Reload data in test mode
        if TestEnvironment.shared.isTestMode {
            print("📅 TimetableViewModel: Reloading data in test mode")
            Task {
                try? await self.fetchTimetable()
            }
        }
    }

    // Load cached data
    private func loadCachedData() async {
        if let cachedEvents: [TimetableEvent] = try? await cacheManager.retrieve(
            forKey: "timetableEvents")
        {
            await MainActor.run {
                self.allEvents = cachedEvents
                self.processEvents()
            }

            // Load last update time
            if let lastUpdateTime: Date = try? await cacheManager.retrieve(
                forKey: "timetableLastUpdate")
            {
                await MainActor.run {
                    self.lastUpdated = lastUpdateTime
                }
            }
        }
    }

    // Save data to cache
    private func saveToCache() async {
        // Save event data
        await cacheManager.save(allEvents, forKey: "timetableEvents")

        // Save update time
        if let lastUpdated = lastUpdated {
            await cacheManager.save(lastUpdated, forKey: "timetableLastUpdate")
        }

        print("Timetable events saved to cache")
    }

    // Fetch timetable data from API
    func fetchTimetable() async throws {
        // Check if allowed to refresh, if not and there's cached data, return early
        if !canRefresh && !allEvents.isEmpty {
            print(
                "📅 Timetable: Refresh frequency limit: Less than 5 minutes since last refresh, using cached data"
            )
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        print("📅 Timetable: Starting to get timetable data...")

        // Check if in test mode
        if TestEnvironment.shared.isTestMode {
            print("📅 Timetable: Test mode, using test data")

            // Use cached test data, this can avoid repeated conversion and potential issues
            let testEvents = TestDataManager.shared.cachedTimetableEvents

            print("📅 Timetable: Loaded \(testEvents.count) test courses")

            // Check if test data is valid
            if testEvents.isEmpty {
                print("⚠️ Warning: Test course data is empty! Trying to regenerate...")
                // Clear cache and try to regenerate
                TestDataManager.shared.clearCache()
                let regeneratedEvents = TestDataManager.shared.cachedTimetableEvents

                print("📅 Timetable: Regenerated \(regeneratedEvents.count) test courses")

                await MainActor.run {
                    self.allEvents = regeneratedEvents
                    self.processEvents()
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.allEvents = testEvents
                    self.processEvents()
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            }

            // Print information of the first event for debugging
            if let firstEvent = testEvents.first {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                print("Test mode - First course example:")
                print("- Name: \(firstEvent.module.name)")
                print("- Start time: \(dateFormatter.string(from: firstEvent.startTime))")
                print("- End time: \(dateFormatter.string(from: firstEvent.endTime))")
                print("- Type: \(firstEvent.sessionTypeStr)")
                print("- Location: \(firstEvent.location.name)")
            }

            await saveToCache()
            return
        }

        do {
            print("Starting timetable fetch...")

            // First try to fetch and process the raw data
            do {
                let data = try await networkService.fetchRawData(endpoint: .timetable)

                // Try to parse JSON manually for better debugging
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Raw JSON has \(json.count) top-level keys: \(json.keys)")

                    if let ok = json["ok"] as? Bool {
                        print("JSON contains 'ok' field with value: \(ok)")
                    }

                    // Check for timetable field
                    if let timetable = json["timetable"] as? [String: [[String: Any]]] {
                        print("Found timetable with \(timetable.count) dates")

                        // Process the timetable data manually
                        var allParsedEvents: [TimetableEvent] = []

                        // Process each date and its events
                        for (dateString, rawEvents) in timetable {
                            print("Processing \(rawEvents.count) events for date \(dateString)")

                            // Create ISO8601 date string for the decoder context
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            if let date = dateFormatter.date(from: dateString) {
                                // Add 'T00:00:00Z' to make it a full ISO8601 date
                                let isoDateString = dateFormatter.string(from: date) + "T00:00:00Z"

                                // Create decoder with the date context
                                let decoder = JSONDecoder()
                                decoder.userInfo[.contextDate] = isoDateString

                                // Process each event with the date context
                                for rawEvent in rawEvents {
                                    do {
                                        let eventData = try JSONSerialization.data(
                                            withJSONObject: rawEvent)
                                        let event = try decoder.decode(
                                            TimetableEvent.self, from: eventData)
                                        allParsedEvents.append(event)
                                    } catch {
                                        print("Failed to parse event: \(error)")
                                    }
                                }
                            } else {
                                // Fallback if date parsing fails
                                let decoder = JSONDecoder()
                                for rawEvent in rawEvents {
                                    do {
                                        let eventData = try JSONSerialization.data(
                                            withJSONObject: rawEvent)
                                        let event = try decoder.decode(
                                            TimetableEvent.self, from: eventData)
                                        allParsedEvents.append(event)
                                    } catch {
                                        print("Failed to parse event: \(error)")
                                    }
                                }
                            }
                        }

                        print("Successfully manually parsed \(allParsedEvents.count) events")

                        // Create a local copy to avoid capturing the mutable variable in concurrent code
                        let parsedEvents = allParsedEvents

                        // Update the view model with the parsed events
                        await MainActor.run {
                            self.allEvents = parsedEvents
                            self.processEvents()
                            self.lastUpdated = Date()
                            self.isLoading = false
                        }
                        await saveToCache()

                        // Return early as we've successfully processed the data
                        return
                    }
                }
            } catch let error as CancellationError {
                print("Timetable fetch was cancelled")
                throw error
            } catch {
                print("Failed to process raw timetable data: \(error)")
                // Continue with standard approach
            }

            // Standard approach as fallback
            let response: APIResponse<TimetableData> = try await networkService.fetch(
                endpoint: .timetable)

            print("Received timetable response: \(response.ok)")

            if let timetableData = response.data {
                print(
                    "Successfully parsed timetable data with \(timetableData.events.count) events")

                if timetableData.events.isEmpty {
                    print("Timetable contains zero events")
                } else {
                    // Print first event for debugging
                    let firstEvent = timetableData.events.first!
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                    print("First event example:")
                    print("- Title: \(firstEvent.module.name)")
                    print("- Start time: \(dateFormatter.string(from: firstEvent.startTime))")
                    print("- End time: \(dateFormatter.string(from: firstEvent.endTime))")
                    print(
                        "- Session type: \(firstEvent.sessionType) (\(firstEvent.sessionTypeStr))")
                    print(
                        "- Location: \(firstEvent.location.name), \(firstEvent.location.siteName)")
                }

                await MainActor.run {
                    self.allEvents = timetableData.events
                    self.processEvents()
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
                await saveToCache()
            } else if let error = response.error {
                print("Error in timetable response: \(error)")
                await MainActor.run {
                    self.errorMessage = error
                    self.isLoading = false
                }
            } else {
                print("No data and no error in response")
                await MainActor.run {
                    self.errorMessage = "No timetable data received"
                    self.isLoading = false
                }
            }
        } catch let error as CancellationError {
            // Task cancelled, don't show error message as this could be normal navigation behavior
            print("Timetable fetch was cancelled")
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        } catch {
            print("Exception while fetching timetable: \(error)")

            // Check if it's an authentication related error, if so, don't show in test mode
            let errorDescription = error.localizedDescription
            let isAuthError =
                errorDescription.contains("Authentication required")
                || errorDescription.contains("Unauthorized") || errorDescription.contains("Token")
                || errorDescription.contains("access token")

            await MainActor.run {
                // Only show error if it's not an auth error or not in test mode
                if !isAuthError || !isTestMode {
                    self.errorMessage = errorDescription
                } else {
                    print("Suppressed auth error in test mode: \(errorDescription)")
                }
                self.isLoading = false
            }
            throw error
        }
    }

    // Force refresh (for pull-to-refresh functionality)
    func forceRefresh() async throws {
        // Reset last update time, force refresh
        await MainActor.run {
            lastUpdated = nil
            print("📅 Timetable: Force refresh: Reset last update time")
        }
        try await fetchTimetable()
    }

    // Process event data, group by date
    private func processEvents() {
        print("Processing \(allEvents.count) events...")

        // Clear cache, ensure using latest data
        clearCaches()

        // Create date formatter for grouping by date (date only, not including time)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current  // Ensure using current timezone

        // Reset data
        eventsByDate = [:]

        // Group events by date
        for event in allEvents {
            // Extract the date part only (without time)
            let dateString = dateFormatter.string(from: event.startTime)

            // Debug output for first few events
            if eventsByDate.isEmpty || eventsByDate.count < 3 {
                print("Event date: \(dateString) from timestamp: \(event.startTime)")
            }

            // Convert back to Date for consistent keys
            if let dateKey = dateFormatter.date(from: dateString) {
                // Ensure date key is normalized (no time component)
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: dateKey)
                if let normalizedDate = calendar.date(from: components) {
                    if eventsByDate[normalizedDate] == nil {
                        eventsByDate[normalizedDate] = []
                    }
                    eventsByDate[normalizedDate]?.append(event)
                }
            }
        }

        // Sort events for each date by start time
        for (date, events) in eventsByDate {
            eventsByDate[date] = events.sorted { $0.startTime < $1.startTime }
        }

        // Debug log for date grouping
        print("Grouped events by \(eventsByDate.count) dates:")
        for (date, events) in eventsByDate {
            print("- \(dateFormatter.string(from: date)): \(events.count) events")
        }

        // Update events to display today's events
        updateEventsToToday()
    }

    // Update to display today's events
    private func updateEventsToToday() {
        let today = Date()
        updateEventsForDate(today)
    }

    // Update events for selected date
    func updateEventsForDate(_ date: Date) {
        // Cancel previous update task
        updateEventsTask?.cancel()

        // Check if debounce is needed
        let now = Date()
        if let lastUpdate = lastUpdateTime,
            now.timeIntervalSince(lastUpdate) < updateThrottleInterval
        {
            // Create new delayed task
            updateEventsTask = Task { @MainActor in
                do {
                    // Wait for debounce interval
                    try await Task.sleep(
                        nanoseconds: UInt64(updateThrottleInterval * 1_000_000_000))

                    // Check if task is cancelled
                    if Task.isCancelled { return }

                    // Execute actual update
                    performEventsUpdate(for: date)

                    // Update last update time
                    lastUpdateTime = Date()
                } catch {
                    // Task cancelled, do nothing
                }
            }
        } else {
            // Execute update directly
            performEventsUpdate(for: date)
            lastUpdateTime = now
        }
    }

    // Method to actually execute event update
    private func performEventsUpdate(for date: Date) {
        // Get normalized date, use cache for performance
        let normalizedDate = getNormalizedDate(date)

        // Get date string, use cache for performance
        let dateString = getDateString(for: normalizedDate)

        // Reduce log output
        #if DEBUG
            print("📅 updateEventsForDate: \(dateString)")
        #endif

        // Reset selected date events
        selectedDateEvents = []

        // Try direct match with normalized date
        if let events = eventsByDate[normalizedDate] {
            selectedDateEvents = events
            return
        }

        // If direct match fails, try string comparison
        // Use cached string mapping to avoid repeated calculations
        if dateStringToEventsCache == nil {
            rebuildDateStringCache()
        }

        // Directly find matching date string
        if let events = dateStringToEventsCache?[dateString] {
            selectedDateEvents = events
        }
    }

    // Get normalized date, use cache for performance
    private func getNormalizedDate(_ date: Date) -> Date {
        if let cachedDate = normalizedDateCache[date] {
            return cachedDate
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: components) else {
            return date
        }

        // Cache result
        normalizedDateCache[date] = normalizedDate

        // Limit cache size to avoid memory leak
        if normalizedDateCache.count > 100 {
            // Create a new dictionary, only keep the latest 50 entries
            let sortedKeys = normalizedDateCache.keys.sorted(by: >).prefix(50)
            let newCache = normalizedDateCache.filter { sortedKeys.contains($0.key) }
            normalizedDateCache = newCache
        }

        return normalizedDate
    }

    // Get date string, use cache for performance
    private func getDateString(for date: Date) -> String {
        if let cachedString = dateStringCache[date] {
            return cachedString
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        // Cache result
        dateStringCache[date] = dateString

        // Limit cache size to avoid memory leak
        if dateStringCache.count > 100 {
            // Create a new dictionary, only keep the latest 50 entries
            let sortedKeys = dateStringCache.keys.sorted(by: >).prefix(50)
            let newCache = dateStringCache.filter { sortedKeys.contains($0.key) }
            dateStringCache = newCache
        }

        return dateString
    }

    // Rebuild date string to event mapping cache
    private func rebuildDateStringCache() {
        var cache: [String: [TimetableEvent]] = [:]

        for (storedDateKey, events) in eventsByDate {
            let normalizedDate = getNormalizedDate(storedDateKey)
            let dateString = getDateString(for: normalizedDate)
            cache[dateString] = events
        }

        dateStringToEventsCache = cache
    }

    // Clear cache, call when data is updated
    private func clearCaches() {
        dateStringCache = [:]
        normalizedDateCache = [:]
        dateStringToEventsCache = nil
    }

    // Check if a specific date has events
    func hasEvents(on date: Date) -> Bool {
        // Get normalized date, use cache for performance
        let normalizedDate = getNormalizedDate(date)

        // Check direct match
        if let events = eventsByDate[normalizedDate], !events.isEmpty {
            return true
        }

        // Get date string, use cache for performance
        let dateString = getDateString(for: normalizedDate)

        // Use cached string mapping to avoid repeated calculations
        if dateStringToEventsCache == nil {
            rebuildDateStringCache()
        }

        // Check string match
        return (dateStringToEventsCache?[dateString]?.isEmpty == false)
    }

    // Get color for event type
    func colorForEventType(_ type: String, sessionTypeStr: String = "") -> Color {
        // Check sessionType and sessionTypeStr for specific keywords
        let typeLower = type.lowercased()
        let sessionTypeStrLower = sessionTypeStr.lowercased()

        // Check sessionType and sessionTypeStr for specific keywords
        if typeLower.contains("workshop") || sessionTypeStrLower.contains("workshop")
            || typeLower == "w" || sessionTypeStrLower == "w"
        {
            return .teal
        } else if typeLower.contains("lecture") || sessionTypeStrLower.contains("lecture")
            || typeLower == "l" || sessionTypeStrLower == "l"
        {
            return .blue
        } else if typeLower.contains("practical")
            || sessionTypeStrLower.contains("practical") || typeLower.contains("lab")
            || sessionTypeStrLower.contains("lab") || typeLower == "p"
            || sessionTypeStrLower == "p"
        {
            return .green
        } else if typeLower.contains("tutorial") || sessionTypeStrLower.contains("tutorial")
            || typeLower == "t" || sessionTypeStrLower == "t"
        {
            return .orange
        } else if typeLower.contains("seminar") || sessionTypeStrLower.contains("seminar")
            || typeLower == "s" || sessionTypeStrLower == "s"
        {
            return .purple
        } else if typeLower.contains("field") || sessionTypeStrLower.contains("field")
            || typeLower.contains("trip") || sessionTypeStrLower.contains("trip")
            || typeLower == "f" || sessionTypeStrLower == "f"
        {
            return .pink
        } else if typeLower.contains("meeting") || sessionTypeStrLower.contains("meeting")
            || typeLower == "m" || sessionTypeStrLower == "m"
        {
            return .cyan
        } else if typeLower.contains("exam") || sessionTypeStrLower.contains("exam")
            || typeLower == "e" || sessionTypeStrLower == "e"
        {
            return .red
        } else {
            return .brown
        }
    }

    // Debug function to examine raw timetable data
    func fetchTimetableDebug() async throws {
        print("🔍 Starting timetable debug fetch...")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Fetch raw data for debugging
            let data = try await networkService.fetchRawData(endpoint: .timetable)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Raw timetable JSON:\n\(jsonString)")

                // Try to print the structure in a more readable way
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("🔍 JSON structure breakdown:")

                    if let ok = json["ok"] as? Bool {
                        print("- ok: \(ok)")
                    }

                    if let timetable = json["timetable"] as? [String: Any] {
                        print("- timetable contains \(timetable.count) dates:")

                        for (date, events) in timetable {
                            if let eventsArray = events as? [[String: Any]] {
                                print("  - \(date): \(eventsArray.count) events")

                                // Print details of first event for sample
                                if let firstEvent = eventsArray.first {
                                    print("    Sample event:")
                                    if let startTime = firstEvent["start_time"] as? String {
                                        print("    - start_time: \(startTime)")
                                    }
                                    if let endTime = firstEvent["end_time"] as? String {
                                        print("    - end_time: \(endTime)")
                                    }
                                    if let type = firstEvent["session_type"] as? String {
                                        print("    - session_type: \(type)")
                                    }
                                    if let module = firstEvent["module"] as? [String: Any],
                                        let name = module["name"] as? String
                                    {
                                        print("    - module: \(name)")
                                    }
                                    if let location = firstEvent["location"] as? [String: Any],
                                        let name = location["name"] as? String
                                    {
                                        print("    - location: \(name)")
                                    }
                                }
                            }
                        }
                    } else {
                        print("- No timetable field found in response")
                    }

                    if let error = json["error"] as? String {
                        print("- error: \(error)")
                    }
                }
            }

            // Now try the normal parsing
            try await fetchTimetable()

        } catch {
            print("🔍 Debug fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = "Debug Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// Event type enum
enum EventType: String {
    case lecture = "Lecture"
    case lab = "Laboratory"
    case tutorial = "Tutorial"
    case seminar = "Seminar"
    case fieldTrip = "Field Trip"
    case workshop = "Workshop"
    case meeting = "Meeting"
    case exam = "Exam"
    case other = "Other"

    var color: Color {
        switch self {
        case .lecture: return .blue
        case .lab: return .green
        case .tutorial: return .orange
        case .seminar: return .purple
        case .fieldTrip: return .pink
        case .workshop: return .teal
        case .meeting: return .cyan
        case .exam: return .red
        case .other: return .primary
        }
    }
}
