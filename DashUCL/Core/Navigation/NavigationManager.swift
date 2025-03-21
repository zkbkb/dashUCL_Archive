/*
 * Centralized navigation system that manages app-wide routing and deep linking.
 * Implements a singleton pattern with ObservableObject for SwiftUI integration.
 * Defines all possible navigation destinations through typed enum values.
 * Provides methods for programmatic navigation between different app screens.
 */

import Combine
import SwiftUI

/// In-app navigation destinations
enum NavigationDestination: Hashable {
    case home
    case search
    case timetable
    case studySpaces
    case spaces  // Add standalone study spaces tab option
    case profile
    case freeRooms
    case roomDetail(id: String)
    case spaceDetail(id: String)
    case classDetail(id: String)  // Add course detail navigation destination
    case settings
    case login
    case uclStructure  // UCL organization structure browsing destination
    case organizationUnit(id: String)  // Navigate to specific organization unit, using ID as parameter
    case departmentExplore(id: String)  // Add department explore view navigation destination
}

/// Navigation Manager
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()

    @Published var activeDestination: NavigationDestination = .home
    @Published var navigationPath = NavigationPath()

    // Add search related properties
    @Published var searchQuery: String = ""
    @Published var shouldFocusSearchField: Bool = false

    // Add timetable date properties
    @Published var timetableSelectedDate: Date = Date()

    // Add target organization unit ID, used to automatically expand and scroll to specified unit in organization structure view
    @Published var targetOrganizationUnitID: String? = nil

    private init() {}

    /// Navigate to specific destination
    func navigateTo(_ destination: NavigationDestination) {
        activeDestination = destination
    }

    /// Navigate to new destination (add to navigation stack)
    func navigateToDetail(_ destination: NavigationDestination) {
        // Add directly to navigation path without changing activeDestination
        // This avoids triggering navigation logic in HomeView's onChange
        // Print navigation state for debugging
        print("Navigate to detail: \(destination), path length: \(navigationPath.count)")
        navigationPath.append(destination)
    }

    /// Return to previous level
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    /// Return to root view
    func navigateToRoot() {
        navigationPath = NavigationPath()
    }

    /// Navigate to search page and set search query
    func navigateToSearchWithQuery(_ query: String) {
        // Set search query
        searchQuery = query
        // Set focus flag
        shouldFocusSearchField = true
        // Navigate to search page
        activeDestination = .search
    }

    /// Navigate to Spaces tab
    func navigateToSpacesTab() {
        // First set activeDestination to a temporary value to ensure onChange is triggered
        if activeDestination == .spaces {
            activeDestination = .home
            // Use asynchronous call to ensure status update before switching back to spaces
            DispatchQueue.main.async {
                self.activeDestination = .spaces
            }
        } else {
            // If not currently in spaces, directly set
            activeDestination = .spaces
        }
    }

    /// Navigate to course details page
    func navigateToClassDetails(classId: String) {
        // First navigate to timetable tab
        activeDestination = .timetable

        // Then navigate to course details page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigateToDetail(.classDetail(id: classId))
        }
    }

    /// Navigate to timetable and set specific date
    func navigateToTimetableWithDate(_ date: Date) {
        // Set selected date
        timetableSelectedDate = date
        // Navigate to timetable page
        activeDestination = .timetable
    }

    /// Navigate to organization structure view and expand to specific department
    func navigateToOrganizationUnit(id: String, isUseExploreView: Bool = true) {
        // Set target organization unit ID
        targetOrganizationUnitID = id

        print("Navigate to organization unit: \(id), use explore view: \(isUseExploreView)")

        // First navigate to main search page
        activeDestination = .search

        // Then navigate to corresponding view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isUseExploreView {
                // Use new department explore view
                print("Use department explore view to navigate to: \(id)")
                self.navigateToDetail(.departmentExplore(id: id))
            } else {
                // Use original UCL structure view and automatically expand to specific department
                print("Use UCL structure view to navigate to: \(id)")
                self.navigateToDetail(.uclStructure)
            }
        }
    }

    /// Navigate from person details page to corresponding department
    func navigateFromPersonToDepartment(departmentName: String) {
        // Find department ID
        print("Start navigating from person to department: \(departmentName)")
        if let unit = UCLOrganizationRepository.shared.getUnit(byName: departmentName) {
            print("Find department by exact name match: \(unit.name), ID: \(unit.id)")
            // First activate search tab
            activeDestination = .search
            // Delay a bit before navigating to detail to ensure tab switch is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Use departmentExplore navigation target
                self.navigateToDetail(.departmentExplore(id: unit.id))
            }
        } else {
            // If no exact match found, try fuzzy match
            let units = UCLOrganizationRepository.shared.searchUnits(query: departmentName)
            if let bestMatch = units.first {
                print("Find department by fuzzy match: \(bestMatch.name), ID: \(bestMatch.id)")
                // First activate search tab
                activeDestination = .search
                // Delay a bit before navigating to detail to ensure tab switch is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.navigateToDetail(.departmentExplore(id: bestMatch.id))
                }
            } else {
                // Try searching for keywords related to department name
                let keywords = departmentName.split(separator: " ")
                print("Try using keyword match: \(keywords)")

                for keyword in keywords where keyword.count > 3 {
                    let results = UCLOrganizationRepository.shared.searchUnits(
                        query: String(keyword))
                    print("Keyword '\(keyword)' search result count: \(results.count)")

                    if let match = results.first {
                        print(
                            "Find department by keyword: \(match.name), ID: \(match.id), keyword: \(keyword)"
                        )
                        // First activate search tab
                        activeDestination = .search
                        // Delay a bit before navigating to detail to ensure tab switch is complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.navigateToDetail(.departmentExplore(id: match.id))
                        }
                        return
                    }
                }

                // If still no match found, directly navigate to UCL structure page
                print("No matching department found, use UCL root organization")
                activeDestination = .search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Use UCL root organization ID to navigate to department explore view
                    self.navigateToDetail(.departmentExplore(id: "UCL"))
                }
            }
        }
    }
}
