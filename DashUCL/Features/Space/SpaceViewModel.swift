import Combine
import Foundation
import SwiftUI

enum StudySpaceCategory: String, CaseIterable {
    case library = "Libraries"
    case computerLab = "Computer Labs"
    case all = "All Spaces"

    var iconName: String {
        switch self {
        case .library:
            return "books.vertical.fill"
        case .computerLab:
            return "desktopcomputer"
        case .all:
            return "building.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .library:
            return .blue
        case .computerLab:
            return .purple
        case .all:
            return .gray
        }
    }
}

/// Space availability filter options
enum SpaceAvailabilityFilter: String, CaseIterable {
    case all = "All"
    case highAvailability = "High Availability"
    case mediumAvailability = "Medium Availability"
    case lowAvailability = "Low Availability"

    var description: String {
        switch self {
        case .all:
            return "Show all spaces"
        case .highAvailability:
            return "More than 66% available"
        case .mediumAvailability:
            return "33-66% available"
        case .lowAvailability:
            return "Less than 33% available"
        }
    }

    var iconName: String {
        switch self {
        case .all:
            return "list.bullet"
        case .highAvailability:
            return "checkmark.circle.fill"
        case .mediumAvailability:
            return "exclamationmark.triangle.fill"
        case .lowAvailability:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Statistical Models

/// Space statistics information
struct SpaceStatistics {
    let totalSpaces: Int
    let totalSeats: Int
    let availableSeats: Int
    let occupiedSeats: Int
    let occupancyPercentage: Double
    let lastUpdated: Date

    var availabilityPercentage: Double {
        return 100 - occupancyPercentage
    }
}

/// Location statistics information
struct LocationStatistics {
    let locationName: String
    let totalSpaces: Int
    let totalSeats: Int
    let availableSeats: Int
    let occupiedSeats: Int
    let occupancyPercentage: Double

    var availabilityPercentage: Double {
        return 100 - occupancyPercentage
    }
}

/// Category statistics information
struct CategoryStatistics {
    let category: StudySpaceCategory
    let totalSpaces: Int
    let totalSeats: Int
    let availableSeats: Int
    let occupiedSeats: Int
    let occupancyPercentage: Double

    var availabilityPercentage: Double {
        return 100 - occupancyPercentage
    }
}

/// Study space management view model
@MainActor
class SpaceViewModel: ObservableObject {
    // Add singleton instance
    static let shared = SpaceViewModel()

    // MARK: - Published Properties
    @Published var allSpaces: [SpaceResult] = []
    @Published var filteredSpaces: [SpaceResult] = []
    @Published var spacesByCategory: [StudySpaceCategory: [SpaceResult]] = [:]
    @Published var spacesByLocation: [String: [SpaceResult]] = [:]

    // Statistics information
    @Published var overallStatistics: SpaceStatistics?
    @Published var categoryStatistics: [StudySpaceCategory: CategoryStatistics] = [:]
    @Published var locationStatistics: [String: LocationStatistics] = [:]

    @Published var isLoading = false
    @Published var selectedCategory: StudySpaceCategory = .all
    @Published var availabilityFilter: SpaceAvailabilityFilter = .all
    @Published var searchText = ""

    // Whether to use cached data
    var cacheEnabled: Bool = true

    // Update time
    @Published var lastUpdated: Date?
    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Private Properties
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        setupBindings()

        // Add test mode notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDataDidUpdate),
            name: .userDataDidUpdate,
            object: nil
        )
    }

    // User data update notification handler
    @objc private func handleUserDataDidUpdate() {
        print("SpaceViewModel: Received user data update notification")

        // In test mode, reload data again
        if TestEnvironment.shared.isTestMode {
            print("SpaceViewModel: Test mode, reload data again")
            Task {
                await loadSpaces()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Load initial data
    func loadInitialData() async {
        // If cache is enabled and data is already loaded, do not re-request
        if cacheEnabled && !allSpaces.isEmpty {
            print("SpaceViewModel: Using cached data, skip API request")
            return
        }

        await loadSpaces()
    }

    /// Refresh space data
    func refreshSpacesData() async {
        // If already loading, avoid repeated requests
        if isLoading {
            print("SpaceViewModel: Data is being loaded, skip repeated request")
            return
        }

        await loadSpaces()
    }

    /// Load space data
    func loadSpaces() async {
        isLoading = true

        // Check if in test mode
        if TestEnvironment.shared.isTestMode {
            print("SpaceViewModel: Test mode, use test data")

            // Use TestDataManager to get test space data
            let testSpaces = TestDataManager.shared.allSpaces
            print("SpaceViewModel: Loaded \(testSpaces.count) test spaces")

            // Process test data
            processSpacesData(testSpaces)

            // Update last updated time
            lastUpdated = Date()
            isLoading = false
            return
        }

        // Non-test mode, load data from API
        do {
            // 1. Get workspace sensor data
            let workspacesData = try await networkService.fetchJSON(
                endpoint: .workspacesSensorsSummary)
            let workspaces = parseWorkspaceData(workspacesData)

            // 2. Get library location data, but only for supplementing workspace information
            let locationsData = try await networkService.fetchJSON(endpoint: .libCalLocations)
            let locations = parseLocationData(locationsData)

            // 3. Only retain spaces with workspace data
            let workspaceLocations = Set(
                workspaces.map { $0.name.components(separatedBy: " - ").first ?? $0.name })
            let relevantLocations = locations.filter { location in
                let locationName = location.name.replacingOccurrences(of: "Library: ", with: "")
                return workspaceLocations.contains { $0.contains(locationName) }
            }

            // 4. Merge results, only include spaces with seat data
            let combinedSpaces = workspaces + relevantLocations
            processSpacesData(combinedSpaces)

            // 5. Update last updated time
            lastUpdated = Date()
            print(
                "🏢 SpaceViewModel: Successfully loaded space data from API: \(combinedSpaces.count) spaces"
            )
        } catch {
            print("🏢 SpaceViewModel: Failed to load space data: \(error)")
        }
        isLoading = false
    }

    /// Set category filter
    func setCategory(_ category: StudySpaceCategory) {
        withAnimation {
            selectedCategory = category
            applyFilters()
        }
    }

    /// Set availability filter
    func setAvailabilityFilter(_ filter: SpaceAvailabilityFilter) {
        withAnimation {
            availabilityFilter = filter
            applyFilters()
        }
    }

    /// Search spaces
    func searchSpaces(query: String) {
        withAnimation {
            searchText = query
            applyFilters()
        }
    }

    /// Get space count for specific category
    func spaceCount(for category: StudySpaceCategory) -> Int {
        spacesByCategory[category]?.count ?? 0
    }

    // MARK: - Private Methods

    /// Set data bindings
    private func setupBindings() {
        // Listen for search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // Listen for category selection changes
        $selectedCategory
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // Listen for availability filter changes
        $availabilityFilter
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Statistical Calculation Methods

    /// Calculate overall statistics information
    private func calculateOverallStatistics(spaces: [SpaceResult]) -> SpaceStatistics {
        let totalSeats = spaces.reduce(0) { $0 + $1.totalSeats }
        let availableSeats = spaces.reduce(0) { $0 + $1.freeSeats }
        let occupiedSeats = totalSeats - availableSeats
        let occupancyPercentage =
            totalSeats > 0 ? Double(occupiedSeats) / Double(totalSeats) * 100 : 0

        return SpaceStatistics(
            totalSpaces: spaces.count,
            totalSeats: totalSeats,
            availableSeats: availableSeats,
            occupiedSeats: occupiedSeats,
            occupancyPercentage: occupancyPercentage,
            lastUpdated: Date()
        )
    }

    /// Calculate category statistics information
    private func calculateCategoryStatistics(category: StudySpaceCategory, spaces: [SpaceResult])
        -> CategoryStatistics
    {
        let totalSeats = spaces.reduce(0) { $0 + $1.totalSeats }
        let availableSeats = spaces.reduce(0) { $0 + $1.freeSeats }
        let occupiedSeats = totalSeats - availableSeats
        let occupancyPercentage =
            totalSeats > 0 ? Double(occupiedSeats) / Double(totalSeats) * 100 : 0

        return CategoryStatistics(
            category: category,
            totalSpaces: spaces.count,
            totalSeats: totalSeats,
            availableSeats: availableSeats,
            occupiedSeats: occupiedSeats,
            occupancyPercentage: occupancyPercentage
        )
    }

    /// Calculate location statistics information
    private func calculateLocationStatistics(locationName: String, spaces: [SpaceResult])
        -> LocationStatistics
    {
        let totalSeats = spaces.reduce(0) { $0 + $1.totalSeats }
        let availableSeats = spaces.reduce(0) { $0 + $1.freeSeats }
        let occupiedSeats = totalSeats - availableSeats
        let occupancyPercentage =
            totalSeats > 0 ? Double(occupiedSeats) / Double(totalSeats) * 100 : 0

        return LocationStatistics(
            locationName: locationName,
            totalSpaces: spaces.count,
            totalSeats: totalSeats,
            availableSeats: availableSeats,
            occupiedSeats: occupiedSeats,
            occupancyPercentage: occupancyPercentage
        )
    }

    /// Group spaces by category
    private func groupSpacesByCategory(_ spaces: [SpaceResult]) -> [StudySpaceCategory:
        [SpaceResult]]
    {
        var result: [StudySpaceCategory: [SpaceResult]] = [:]

        // All spaces
        result[.all] = spaces

        // Library
        result[.library] = spaces.filter { space in
            space.name.lowercased().contains("library")
                || space.description.lowercased().contains("library")
                || space.name.lowercased().contains("[lib]")
        }

        // Computer laboratory
        result[.computerLab] = spaces.filter { space in
            space.name.lowercased().contains("computer")
                || space.description.lowercased().contains("computer")
                || space.name.lowercased().contains("lab")
                || space.name.lowercased().contains("cluster")
                || space.name.lowercased().contains("[isd]")
        }

        return result
    }

    /// Group spaces by location
    private func groupSpacesByLocation(_ spaces: [SpaceResult]) -> [String: [SpaceResult]] {
        return Dictionary(grouping: spaces) { space in
            // Extract location information from name
            let components = space.name.split(separator: " ")
            if components.count > 1 {
                // Try to extract location name, remove prefix like [LIB] or [ISD]
                if components[0].starts(with: "[") && components[0].hasSuffix("]") {
                    return String(components.dropFirst().joined(separator: " "))
                }
            }
            return space.name
        }
    }

    /// Process space data
    private func processSpacesData(_ spaces: [SpaceResult]) {
        // Filter out Bidborough House, because it's already closed
        let filteredSpaces = spaces.filter { space in
            !space.name.lowercased().contains("bidborough")
        }

        // Update all spaces
        allSpaces = filteredSpaces

        // Group by category
        spacesByCategory = groupSpacesByCategory(filteredSpaces)

        // Group by location
        spacesByLocation = groupSpacesByLocation(filteredSpaces)

        // Calculate overall statistics information
        overallStatistics = calculateOverallStatistics(spaces: filteredSpaces)

        // Calculate statistics information for each category
        for category in StudySpaceCategory.allCases {
            if let categorySpaces = spacesByCategory[category] {
                categoryStatistics[category] = calculateCategoryStatistics(
                    category: category,
                    spaces: categorySpaces
                )
            }
        }

        // Calculate statistics information for each location
        for (locationName, locationSpaces) in spacesByLocation {
            locationStatistics[locationName] = calculateLocationStatistics(
                locationName: locationName,
                spaces: locationSpaces
            )
        }

        // Apply filters
        applyFilters()
    }

    /// Apply all filters
    private func applyFilters() {
        var filteredResults = allSpaces

        // Apply category filter
        if selectedCategory != .all {
            filteredResults = spacesByCategory[selectedCategory] ?? []
        }

        // Apply availability filter
        if availabilityFilter != .all {
            filteredResults = filteredResults.filter { space in
                switch availabilityFilter {
                case .highAvailability:
                    return space.occupancyPercentage < 33
                case .mediumAvailability:
                    return space.occupancyPercentage >= 33 && space.occupancyPercentage < 66
                case .lowAvailability:
                    return space.occupancyPercentage >= 66
                case .all:
                    return true
                }
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filteredResults = filteredResults.filter { space in
                space.name.lowercased().contains(searchText.lowercased())
                    || space.description.lowercased().contains(searchText.lowercased())
            }
        }

        // Update filtered spaces
        filteredSpaces = filteredResults
    }

    // MARK: - Data Parsing

    /// Parse workspace data
    private func parseWorkspaceData(_ data: [String: Any]) -> [SpaceResult] {
        var results: [SpaceResult] = []
        var processedMapIds = Set<String>()  // Used to track processed map IDs

        if let surveys = data["surveys"] as? [[String: Any]] {
            for survey in surveys {
                if let id = survey["id"] as? Int,
                    let name = survey["name"] as? String,
                    let sensorsAbsent = survey["sensors_absent"] as? Int,
                    let sensorsOccupied = survey["sensors_occupied"] as? Int
                {
                    // Extract map information for description
                    var description = "UCL study space"
                    if let maps = survey["maps"] as? [[String: Any]], !maps.isEmpty {
                        let mapNames = maps.compactMap { $0["name"] as? String }.joined(
                            separator: ", ")
                        if !mapNames.isEmpty {
                            description = mapNames
                        }

                        // If there are sub-spaces (maps), create separate SpaceResult for each sub-space
                        if maps.count > 1 {
                            for map in maps {
                                if let mapId = map["id"] as? Int,
                                    let mapName = map["name"] as? String,
                                    let mapSensorsAbsent = map["sensors_absent"] as? Int,
                                    let mapSensorsOccupied = map["sensors_occupied"] as? Int
                                {
                                    // Check if this sub-space has already been processed with the same name
                                    let mapKey = "\(name)_\(mapName)"
                                    if processedMapIds.contains(mapKey) {
                                        continue  // Skip duplicate sub-spaces
                                    }
                                    processedMapIds.insert(mapKey)

                                    let mapFreeSeats = mapSensorsAbsent
                                    let mapTotalSeats = mapSensorsAbsent + mapSensorsOccupied
                                    let mapOccupancyPercentage =
                                        mapTotalSeats > 0
                                        ? Int(
                                            (Double(mapSensorsOccupied) / Double(mapTotalSeats))
                                                * 100) : 0

                                    // Create sub-space record - Use parent space name + sub-space name
                                    let subspaceName: String
                                    if name.contains("[LIB]") || name.contains("[ISD]") {
                                        subspaceName = "\(name) - \(mapName)"
                                    } else {
                                        subspaceName = "\(name) - \(mapName)"
                                    }

                                    let subspaceDescription =
                                        "Part of \(name.replacingOccurrences(of: "[LIB] ", with: "").replacingOccurrences(of: "[ISD] ", with: ""))"

                                    let subspaceResult = SpaceResult(
                                        id: "\(id)_\(mapId)",
                                        name: subspaceName,
                                        description: subspaceDescription,
                                        freeSeats: mapFreeSeats,
                                        totalSeats: mapTotalSeats,
                                        occupancyPercentage: mapOccupancyPercentage
                                    )

                                    results.append(subspaceResult)
                                }
                            }

                            // Skip adding parent space, because we've already added all sub-spaces
                            continue
                        }
                    }

                    // Check if it's a computer cluster
                    if name.contains("[ISD]") {
                        description += " - Computer cluster"
                    } else if name.contains("[LIB]") {
                        description += " - Library study space"
                    }

                    let freeSeats = sensorsAbsent
                    let totalSeats = sensorsAbsent + sensorsOccupied
                    let occupancyPercentage =
                        totalSeats > 0
                        ? Int((Double(sensorsOccupied) / Double(totalSeats)) * 100) : 0

                    let result = SpaceResult(
                        id: String(id),
                        name: name,
                        description: description,
                        freeSeats: freeSeats,
                        totalSeats: totalSeats,
                        occupancyPercentage: occupancyPercentage
                    )

                    results.append(result)
                }
            }
        }

        return results
    }

    /// Parse location data
    private func parseLocationData(_ data: Any) -> [SpaceResult] {
        var results: [SpaceResult] = []

        if let json = data as? [String: Any],
            let locations = json["locations"] as? [[String: Any]]
        {
            for location in locations {
                if let id = location["lid"] as? Int,
                    let name = location["name"] as? String
                {
                    let description = location["description"] as? String ?? "UCL Library location"
                    let terms = location["terms"] as? String ?? ""

                    // Get the real coordinates of the location
                    _ = UCLBuildingCoordinates.getCoordinate(for: name)

                    // Generate a more meaningful description
                    var enhancedDescription = description
                    if description.isEmpty || description == "UCL Library location" {
                        enhancedDescription = "UCL library and study space located at \(name). "
                        if !terms.isEmpty {
                            enhancedDescription += "Terms: \(terms)"
                        }
                    }

                    // Create location result, note here it doesn't include seat information
                    // Seat information will be obtained from workspace API
                    let result = SpaceResult(
                        id: "lib_\(id)",
                        name: name,  // No need to add "Library:" prefix
                        description: enhancedDescription,
                        freeSeats: 0,
                        totalSeats: 0,
                        occupancyPercentage: 0
                    )

                    results.append(result)
                }
            }
        }

        return results
    }
}
