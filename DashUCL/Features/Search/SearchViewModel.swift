import SwiftUI
import UIKit

// Add notification name extension
extension Notification.Name {
    // Delete room-related notifications
}

// MARK: - Custom Toast Manager
// Toast manager is responsible for displaying and hiding prompt messages

// Using ToastView imported from LoginViewModifiers.swift, no need to redefine
class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message = ""

    func show(message: String) {
        self.message = message
        withAnimation {
            isShowing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.isShowing = false
            }
        }
    }
}

// MARK: - Search Category Enum
enum SearchCategory: String, CaseIterable, Identifiable {
    case people = "People"

    var id: String { self.rawValue }

    var iconName: String {
        switch self {
        case .people: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .people: return .blue
        }
    }
}

// MARK: - Data Model

@MainActor
class SearchViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var peopleResults: [Features.Search.PersonResult] = []

    // Add state to control expand/collapse
    @Published var isPeopleExpanded: Bool = false

    // Filter options
    @Published var selectedCategory: SearchCategory? = nil

    private let networkService = NetworkService()
    private let navigationManager = NavigationManager.shared

    var hasResults: Bool {
        !peopleResults.isEmpty
    }

    init() {
        // Remove the call to generate smart suggestions at initialization
    }

    // Search all categories
    func searchAllCategories(query: String) async {
        guard !query.isEmpty else { return }

        isSearching = true
        clearResults()  // Clear previous search results

        // If no filter category selected, search all categories
        if self.selectedCategory == nil {
            await searchPeople(query: query)
        } else {
            // Otherwise, search different types of content based on category
            switch self.selectedCategory! {
            case .people:
                await searchPeople(query: query)
            }
        }

        isSearching = false
    }

    // Search function - Modified to not automatically add history
    func search(query: String, category: SearchCategory) async {
        guard !query.isEmpty else { return }

        print(
            "DEBUG: Start executing specific category search, category: \(category.rawValue), query: \"\(query)\""
        )
        isSearching = true

        // Clear previous results
        clearResults()

        // Search different types of content based on category
        switch category {
        case .people:
            print("DEBUG: Executing people search")
            await searchPeople(query: query)
        }

        isSearching = false
        print("DEBUG: Specific category search completed")
    }

    // People search
    func searchPeople(query: String) async {
        do {
            // Check if in test mode
            if TestEnvironment.shared.isTestMode {
                print("DEBUG: Executing people search in test mode, query: \"\(query)\"")

                // In test mode, use TestStaffData
                let staffResults = TestStaffData.searchStaff(query: query)

                // Convert StaffMember to PersonResult
                self.peopleResults = staffResults.map { staff in
                    Features.Search.PersonResult(
                        id: staff.id,
                        name: staff.name,
                        email: staff.email,
                        department: staff.department,
                        position: staff.position
                    )
                }

                return
            }

            // Normal API call
            let endpoint = APIEndpoint.searchPeople(query: query)
            let data = try await networkService.fetchJSON(endpoint: endpoint)

            // Parse API response
            if let results = data["people"] as? [[String: Any]] {
                self.peopleResults = results.compactMap {
                    personData -> Features.Search.PersonResult? in
                    guard let name = personData["name"] as? String else { return nil }

                    return Features.Search.PersonResult(
                        id: UUID().uuidString,
                        name: name,
                        email: personData["email"] as? String ?? "",
                        department: personData["department"] as? String ?? "",
                        position: personData["phone"] as? String ?? ""
                    )
                }
            }
        } catch {
            print("Error searching people: \(error)")
        }
    }

    // Clear search results
    func clearResults() {
        peopleResults.removeAll()
    }
}

// MARK: - Namespace
enum Features {
    enum Search {
        // MARK: - People Search Result Model
        struct PersonResult: Identifiable {
            let id: String
            let name: String
            let email: String
            let department: String
            let position: String
        }
    }
}

// MARK: - Department Search Result Model
struct DepartmentResult: Identifiable {
    let id: String
    let name: String
    let code: String
}
