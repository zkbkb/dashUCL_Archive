import Foundation
import SwiftUI

// MARK: - Study Space Result Model
struct SpaceResult: Identifiable {
    let id: String
    let name: String
    let description: String
    let freeSeats: Int
    let totalSeats: Int
    let occupancyPercentage: Int

    // Occupancy rate color
    var occupancyColor: Color {
        if occupancyPercentage <= 50 {
            return .green
        } else if occupancyPercentage <= 80 {
            return .orange
        } else {
            return .red
        }
    }

    // Occupancy status text
    var occupancyText: String {
        if occupancyPercentage <= 50 {
            return "Low occupancy"
        } else if occupancyPercentage <= 80 {
            return "Moderate occupancy"
        } else {
            return "High occupancy"
        }
    }
}

// MARK: - Space Type Enumeration
enum SpaceType: String, CaseIterable, Identifiable {
    case all = "All"
    case library = "Library"
    case computerLab = "Computer Lab"
    case studySpace = "Study Space"
    case other = "Other"

    var id: String { self.rawValue }

    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .library: return "books.vertical.fill"
        case .computerLab: return "desktopcomputer"
        case .studySpace: return "person.3.fill"
        case .other: return "building.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .library: return .green
        case .computerLab: return .purple
        case .studySpace: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Location Model
struct Location {
    let latitude: Double
    let longitude: Double
}

// MARK: - Workspace Model
struct StudySpaceStatus {
    let id: String
    let name: String
    let freeSeats: Int
    let totalSeats: Int
    let occupancyPercentage: Int
}
