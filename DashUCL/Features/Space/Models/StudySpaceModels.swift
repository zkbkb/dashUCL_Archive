import Foundation
import SwiftUI

// Use model classes defined in UCLModels (LibrarySpace)
// No need to import UCLModels as it's in the same target

// MARK: - Study Space Models

// MARK: - Study Space Survey
struct StudySpaceSurvey: Codable, Identifiable {
    let id: Int
    let name: String
    let active: Bool
    let startTime: String
    let endTime: String
    let staffSurvey: Bool
    let maps: [StudySpaceMap]
    let location: StudySpaceLocation

    enum CodingKeys: String, CodingKey {
        case id, name, active, maps, location
        case startTime = "start_time"
        case endTime = "end_time"
        case staffSurvey = "staff_survey"
    }
}

// MARK: - Study Space Map
struct StudySpaceMap: Codable, Identifiable {
    let id: Int
    let name: String
    let imageId: Int
    let sensors: [StudySpaceSensor]?

    enum CodingKeys: String, CodingKey {
        case id, name, sensors
        case imageId = "image_id"
    }
}

// MARK: - Study Space Sensor
struct StudySpaceSensor: Codable, Identifiable {
    let id: String  // Unique identifier for the sensor
    let deviceType: String  // Device type
    let floor: Bool  // Whether it's on the floor
    let status: SensorStatus  // Sensor status
    let location: String  // Location description
    let room: RoomInfo  // Room information

    // Nested status structure
    struct SensorStatus: Codable {
        let lastTriggerType: String?
        let lastTriggerTimestamp: Date?
        let occupied: Bool?

        enum CodingKeys: String, CodingKey {
            case lastTriggerType = "last_trigger_type"
            case lastTriggerTimestamp = "last_trigger_timestamp"
            case occupied
        }
    }

    // Nested room information structure
    struct RoomInfo: Codable {
        let name: String
        let type: String
        let description: String

        enum CodingKeys: String, CodingKey {
            case name = "room_name"
            case type = "room_type"
            case description = "description_1"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id = "hardware_id"
        case deviceType = "device_type"
        case floor
        case lastTriggerType = "last_trigger_type"
        case lastTriggerTimestamp = "last_trigger_timestamp"
        case occupied
        case location
        case roomName = "room_name"
        case roomType = "room_type"
        case description = "description_1"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode basic attributes
        id = try container.decode(String.self, forKey: .id)
        deviceType = try container.decode(String.self, forKey: .deviceType)
        floor = try container.decode(Bool.self, forKey: .floor)
        location = try container.decode(String.self, forKey: .location)

        // Create status object
        status = SensorStatus(
            lastTriggerType: try container.decodeIfPresent(String.self, forKey: .lastTriggerType),
            lastTriggerTimestamp: try container.decodeIfPresent(
                Date.self, forKey: .lastTriggerTimestamp),
            occupied: try container.decodeIfPresent(Bool.self, forKey: .occupied)
        )

        // Create room information object
        room = RoomInfo(
            name: try container.decode(String.self, forKey: .roomName),
            type: try container.decode(String.self, forKey: .roomType),
            description: try container.decode(String.self, forKey: .description)
        )
    }

    // Custom encoder to generate flat JSON structure
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode basic attributes
        try container.encode(id, forKey: .id)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(floor, forKey: .floor)
        try container.encode(location, forKey: .location)

        // Encode status information
        try container.encodeIfPresent(status.lastTriggerType, forKey: .lastTriggerType)
        try container.encodeIfPresent(status.lastTriggerTimestamp, forKey: .lastTriggerTimestamp)
        try container.encodeIfPresent(status.occupied, forKey: .occupied)

        // Encode room information
        try container.encode(room.name, forKey: .roomName)
        try container.encode(room.type, forKey: .roomType)
        try container.encode(room.description, forKey: .description)
    }
}

// MARK: - Study Space Location
struct StudySpaceLocation: Codable {
    let coordinates: StudySpaceCoordinates
    let address: [String]
}

// MARK: - Study Space Coordinates
struct StudySpaceCoordinates: Codable {
    let lat: String
    let lng: String
}

// MARK: - Study Space Response Wrappers
struct StudySpaceResponse: Codable {
    let ok: Bool?
    let surveys: [StudySpaceSummary]?
    let data: StudySpaceData?
    let result: StudySpaceResult?
}

struct StudySpaceData: Codable {
    let surveys: [StudySpaceSummary]?
    let spaces: [StudySpaceSummary]?
    let summary: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case surveys, spaces, summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        surveys = try container.decodeIfPresent([StudySpaceSummary].self, forKey: .surveys)
        spaces = try container.decodeIfPresent([StudySpaceSummary].self, forKey: .spaces)

        // Skip summary decoding since we don't need it and it might have complex structure
        summary = nil
    }

    // Implement encode to satisfy Encodable protocol
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(surveys, forKey: .surveys)
        try container.encodeIfPresent(spaces, forKey: .spaces)
        // Skip encoding summary since it's complex and we don't need it
    }
}

struct StudySpaceResult: Codable {
    let spaces: [StudySpaceSummary]?
    let surveys: [StudySpaceSummary]?
}

// MARK: - Study Space Summary
struct StudySpaceSummary: Codable {
    let name: String
    let id: Int
    let sensorsAbsent: Int
    let sensorsTotal: Int
    let sensorsOccupied: Int
    let maps: [StudySpaceMapSummary]

    enum CodingKeys: String, CodingKey {
        case name, id, maps
        case sensorsAbsent = "sensors_absent"
        case sensorsTotal = "sensors_total"
        case sensorsOccupied = "sensors_occupied"
    }

    // Custom initializer to handle different API response formats
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<StudySpaceSummary.CodingKeys>

        do {
            // First try to decode from top-level object
            container = try decoder.container(keyedBy: CodingKeys.self)
        } catch {
            // If that fails, try to decode from nested structure
            // API might return format like { "ok": true, "surveys": [{ ... }] }
            do {
                let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)

                // Try multiple possible response formats
                if rootContainer.contains(.surveys) {
                    var nestedArrayContainer = try rootContainer.nestedUnkeyedContainer(
                        forKey: .surveys)

                    if nestedArrayContainer.isAtEnd {
                        throw DecodingError.valueNotFound(
                            [StudySpaceSummary].self,
                            DecodingError.Context(
                                codingPath: nestedArrayContainer.codingPath,
                                debugDescription: "Empty surveys array"
                            )
                        )
                    }

                    // Get the first element from the nested container
                    let nestedDecoder = try nestedArrayContainer.superDecoder()
                    container = try nestedDecoder.container(keyedBy: CodingKeys.self)
                } else if rootContainer.contains(.data) {
                    // Try another possible format with "data" key
                    let dataContainer = try rootContainer.nestedContainer(
                        keyedBy: DataCodingKeys.self, forKey: .data)

                    if dataContainer.contains(.surveys) {
                        var surveysContainer = try dataContainer.nestedUnkeyedContainer(
                            forKey: .surveys)
                        let surveyDecoder = try surveysContainer.superDecoder()
                        container = try surveyDecoder.container(keyedBy: CodingKeys.self)
                    } else if dataContainer.contains(.spaces) {
                        var spacesContainer = try dataContainer.nestedUnkeyedContainer(
                            forKey: .spaces)
                        let spaceDecoder = try spacesContainer.superDecoder()
                        container = try spaceDecoder.container(keyedBy: CodingKeys.self)
                    } else {
                        // Fallback to direct data container
                        container = try rootContainer.nestedContainer(
                            keyedBy: CodingKeys.self, forKey: .data)
                    }
                } else {
                    // No expected structure found
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription:
                                "Cannot find surveys array or direct study space summary"
                        )
                    )
                }
            } catch let nestedError {
                print("Nested structure decoding failed: \(nestedError)")

                // Print diagnostic information about the data structure
                do {
                    let jsonContainer = try decoder.singleValueContainer()
                    if let jsonData = try? jsonContainer.decode(Data.self),
                        let jsonString = String(data: jsonData, encoding: .utf8)
                    {
                        print("Raw JSON structure: \(jsonString)")
                    } else {
                        print("Could not decode raw data for diagnosis")
                    }
                } catch {
                    print("Failed to decode raw data for diagnosis: \(error)")
                }

                throw nestedError
            }
        }

        // Normal value decoding with safe fallbacks
        do {
            name = try container.decode(String.self, forKey: .name)
        } catch {
            print("Failed to decode name: \(error)")
            name = "Unknown Space"
        }

        do {
            id = try container.decode(Int.self, forKey: .id)
        } catch {
            print("Failed to decode id: \(error)")
            id = -1
        }

        // Handle potentially missing fields with safe defaults
        sensorsAbsent = (try? container.decode(Int.self, forKey: .sensorsAbsent)) ?? 0
        sensorsTotal = (try? container.decode(Int.self, forKey: .sensorsTotal)) ?? 0
        sensorsOccupied = (try? container.decode(Int.self, forKey: .sensorsOccupied)) ?? 0
        maps = (try? container.decode([StudySpaceMapSummary].self, forKey: .maps)) ?? []
    }

    // Root container decoding keys
    private enum RootCodingKeys: String, CodingKey {
        case ok
        case surveys
        case data
        case result
    }

    // Data container keys
    private enum DataCodingKeys: String, CodingKey {
        case surveys
        case spaces
        case summary
    }
}

// MARK: - Study Space Map Summary
struct StudySpaceMapSummary: Codable {
    let name: String
    let id: Int
    let sensorsAbsent: Int
    let sensorsTotal: Int
    let sensorsOccupied: Int

    enum CodingKeys: String, CodingKey {
        case name, id
        case sensorsAbsent = "sensors_absent"
        case sensorsTotal = "sensors_total"
        case sensorsOccupied = "sensors_occupied"
    }
}

// MARK: - Study Space Utilization
struct StudySpaceUtilization: Codable {
    let seatSummary: StudySpaceSeatSummary
    let spaceSummary: StudySpaceSpaceSummary
    let zones: [StudySpaceZone]
    let date: Date

    enum CodingKeys: String, CodingKey {
        case seatSummary = "seat_summary"
        case spaceSummary = "space_summary"
        case zones, date
    }
}

// MARK: - Study Space Seat Summary
struct StudySpaceSeatSummary: Codable {
    let active: Int
    let bookableCount: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case active
        case bookableCount = "bookable_count"
        case total
    }
}

// MARK: - Study Space Space Summary
struct StudySpaceSpaceSummary: Codable {
    let active: Int
    let bookableCount: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case active
        case bookableCount = "bookable_count"
        case total
    }
}

// MARK: - Study Space Zone
struct StudySpaceZone: Codable, Identifiable {
    let id: Int
    let name: String
    let spaces: [StudySpaceDetail]
}

// MARK: - Study Space Detail
struct StudySpaceDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let bookableAsWhole: Bool
    let currentOccupancy: Int
    let currentCapacity: Int
    let maxCapacity: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case bookableAsWhole = "bookable_as_whole"
        case currentOccupancy = "current_occupancy"
        case currentCapacity = "current_capacity"
        case maxCapacity = "max_capacity"
    }
}
