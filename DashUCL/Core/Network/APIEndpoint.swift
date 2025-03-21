/*
 * Enumeration of all available API endpoints used by the application.
 * Defines the structure for interacting with UCL backend services.
 * Provides path computation and parameter handling for API requests.
 * Organizes endpoints by functional category for better maintainability.
 */

import Foundation

enum APIEndpoint {
    case userInfo
    case timetable
    case studySpaces
    case rooms
    case bookings
    case createBooking
    case cancelBooking(id: String)
    case libCalCategories
    case libCalLocations
    case timetableDepartments
    case freeRooms(startTime: String, endTime: String)
    case roomEquipment(roomId: String)
    case searchPeople(query: String)
    case libCalBookings
    case timetableByModule(modules: [String])
    case workspacesHistoricalSurveys
    case workspacesSensorAverages
    case workspacesSensorsSummary
    case libCalNickname
    case availableSlots(resourceId: String, date: String)

    var path: String {
        switch self {
        case .userInfo:
            return "/oauth/user/data"
        case .timetable:
            return "/timetable/personal"
        case .studySpaces:
            return "/workspaces/sensors/summary"
        case .rooms:
            return "/roombookings/rooms"
        case .bookings:
            return "/libcal/space/bookings"
        case .createBooking:
            return "/libcal/space/book"
        case .cancelBooking(let id):
            return "/libcal/space/cancel/\(id)"
        case .libCalCategories:
            return "/libcal/space/categories"
        case .libCalLocations:
            return "/libcal/space/locations"
        case .timetableDepartments:
            return "/timetable/data/departments"
        case .freeRooms(let startTime, let endTime):
            return "/roombookings/freerooms?start_datetime=\(startTime)&end_datetime=\(endTime)"
        case .roomEquipment(let roomId):
            return "/roombookings/equipment?roomid=\(roomId)"
        case .searchPeople(let query):
            return "/search/people?query=\(query)"
        case .libCalBookings:
            return "/libcal/space/personal_bookings"
        case .timetableByModule(let modules):
            let moduleString = modules.joined(separator: ",")
            return "/timetable/bymodule?modules=\(moduleString)"
        case .workspacesHistoricalSurveys:
            return "/workspaces/historical/surveys"
        case .workspacesSensorAverages:
            return "/workspaces/sensors/averages/time"
        case .workspacesSensorsSummary:
            return "/workspaces/sensors/summary"
        case .libCalNickname:
            return "/libcal/space/nickname"
        case .availableSlots(let resourceId, let date):
            return "/libcal/space/item/\(resourceId)/availability/\(date)"
        }
    }
}
