/*
 * Extension to NetworkService that enables offline test mode functionality.
 * Provides mock API responses for testing the app without network connectivity.
 * Simulates search endpoints with configurable test data responses.
 * Integrates with TestEnvironment to maintain consistent test state.
 */

import Foundation

// Extend NetworkService to support test mode
extension NetworkService {
    // Extend fetchJSON method in test mode to provide mock data for searchPeople
    func fetchJSONWithTestModeSupport(endpoint: APIEndpoint) async throws -> [String: Any] {
        // Check if this is a searchPeople request in test mode
        if TestEnvironment.shared.isTestMode {
            if case .searchPeople(let query) = endpoint {
                print("Test mode: Using TestStaffData to handle searchPeople request: \(query)")

                // Get test staff data
                let searchResults = TestStaffData.searchStaff(query: query)

                // Convert TestStaffData.StaffMember to API response format
                let peopleArray: [[String: Any]] = searchResults.map { staff in
                    return [
                        "id": staff.id,
                        "name": staff.name,
                        "email": staff.email,
                        "department": staff.department,
                        "position": staff.position,
                        "phone": staff.phoneNumber,
                    ]
                }

                // Return mock API response
                return [
                    "ok": true,
                    "people": peopleArray,
                ]
            }
        }

        // Execute original method by default
        return try await fetchJSON(endpoint: endpoint)
    }
}
