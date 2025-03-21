import Foundation

// Using model classes defined in UCLModels (Room, RoomType, RoomEquipment)
// No need to import UCLModels as it's in the same target

// MARK: - Workspace Models
struct Workspace: Codable {
    let id: Int
    let name: String
    let active: Bool
    let location: WorkspaceLocation
    let maps: [WorkspaceMap]
    let staffSurvey: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case active
        case location
        case maps
        case staffSurvey = "staff_survey"
    }
}

struct WorkspaceLocation: Codable {
    let coordinates: WorkspaceCoordinates
    let address: [String]
}

struct WorkspaceCoordinates: Codable {
    let lat: String
    let lng: String
}

struct WorkspaceMap: Codable {
    let id: Int
    let name: String
    let imageId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageId = "image_id"
    }
}

// MARK: - Workspace Status
struct WorkspaceStatus: Codable {
    let surveyId: Int
    let name: String
    let sensorsAbsent: Int
    let sensorsTotal: Int
    let sensorsOccupied: Int
    let maps: [WorkspaceMapStatus]

    enum CodingKeys: String, CodingKey {
        case surveyId = "id"
        case name
        case sensorsAbsent = "sensors_absent"
        case sensorsTotal = "sensors_total"
        case sensorsOccupied = "sensors_occupied"
        case maps
    }
}

struct WorkspaceMapStatus: Codable {
    let id: Int
    let name: String
    let sensorsAbsent: Int
    let sensorsTotal: Int
    let sensorsOccupied: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sensorsAbsent = "sensors_absent"
        case sensorsTotal = "sensors_total"
        case sensorsOccupied = "sensors_occupied"
    }
}
