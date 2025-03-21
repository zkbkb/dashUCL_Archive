import SwiftUI

// Temporarily reference TabBarItem until we resolve the import issue
enum TabBarItem: Hashable {
    case home
    case timetable
    case spaces
    case setting

    var iconName: String {
        switch self {
        case .home:
            return "house.fill"
        case .timetable:
            return "calendar.badge.clock"
        case .spaces:
            return "building.2.fill"
        case .setting:
            return "gearshape.2.fill"
        }
    }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .timetable:
            return "Timetable"
        case .spaces:
            return "Spaces"
        case .setting:
            return "Settings"
        }
    }

    var color: Color {
        switch self {
        case .home:
            return .blue
        case .timetable:
            return .blue
        case .spaces:
            return .blue
        case .setting:
            return .blue
        }
    }
}

@Observable
class HomeViewModel {
    var selectedTab: TabBarItem = .home

    init() {
        // Initialize any required data or services
    }
}
