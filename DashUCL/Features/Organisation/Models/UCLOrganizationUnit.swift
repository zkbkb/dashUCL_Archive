import Foundation
import SwiftUI

/// Represents a UCL organizational unit (schools, faculties, departments, etc.)
struct UCLOrganizationUnit: Identifiable, Equatable {
    let id: String
    let name: String
    let type: OrganizationType
    let parentID: String?
    var children: [UCLOrganizationUnit]?

    /// Organization unit type
    enum OrganizationType: String, Codable, CaseIterable {
        case university = "University"
        case faculty = "Faculty"
        case department = "Department"
        case division = "Division"
        case school = "School"
        case institute = "Institute"
        case center = "Center"
        case administrative = "Administrative"
        case other = "Other"

        /// Returns type color
        var color: Color {
            switch self {
            case .university: return .blue
            case .faculty: return .purple
            case .department: return .indigo
            case .division: return .teal
            case .school: return .orange
            case .institute: return .green
            case .center: return .pink
            case .administrative: return .orange
            case .other: return .gray
            }
        }
    }

    static func == (lhs: UCLOrganizationUnit, rhs: UCLOrganizationUnit) -> Bool {
        return lhs.id == rhs.id
    }
}

extension UCLOrganizationUnit {
    /// Returns formatted display name (including type)
    var displayName: String {
        if id == "UCL" {
            return name
        }
        return "\(type.rawValue) of \(name)"
    }

    /// Returns short identifier for list display
    var shortTitle: String {
        return name
    }
}
