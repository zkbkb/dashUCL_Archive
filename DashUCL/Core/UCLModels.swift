/*
 * Core data models representing UCL facilities and services.
 * Defines structures for library spaces, rooms, events, and other campus resources.
 * Implements Identifiable, Codable, and Equatable protocols for consistent data handling.
 * Used throughout the app for representing API responses and local data structures.
 */

import Foundation
import SwiftUI

// MARK: - LibrarySpace Model
struct LibrarySpace: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let availableSeats: Int
    let totalCapacity: Int
    let lastUpdated: Date
    let location: String
    let isAccessible: Bool
    let averageOccupancy: Double

    static func == (lhs: LibrarySpace, rhs: LibrarySpace) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Room Model
struct Room: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let type: RoomType
    let capacity: Int
    let building: String
    let floor: String
    let equipment: [RoomEquipment]
    let isAccessible: Bool
    let images: [URL]

    enum CodingKeys: String, CodingKey {
        case id, name, type, capacity, building, floor, equipment, isAccessible, images
    }

    static func == (lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Room Type
enum RoomType: String, Codable, CaseIterable {
    case classroom = "classroom"
    case lectureTheatre = "lecture_theatre"
    case laboratory = "laboratory"
    case computerCluster = "computer_cluster"
    case meetingRoom = "meeting_room"
    case seminarRoom = "seminar_room"
    case socialSpace = "social_space"
    case other = "other"

    var displayName: String {
        switch self {
        case .classroom:
            return "Classroom"
        case .lectureTheatre:
            return "Lecture Theatre"
        case .laboratory:
            return "Laboratory"
        case .computerCluster:
            return "Computer Cluster"
        case .meetingRoom:
            return "Meeting Room"
        case .seminarRoom:
            return "Seminar Room"
        case .socialSpace:
            return "Social Space"
        case .other:
            return "Other"
        }
    }
}

// MARK: - Room Equipment
struct RoomEquipment: Codable, Hashable {
    let name: String
    let category: String
    let description: String?

    init(name: String, category: String, description: String? = nil) {
        self.name = name
        self.category = category
        self.description = description
    }
}

// MARK: - Booking Model
struct Booking: Identifiable, Codable, Equatable {
    let id: String
    let resourceId: String
    let resourceType: ResourceType
    let startTime: Date
    let endTime: Date
    let status: BookingStatus
    let notes: String?

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    static func == (lhs: Booking, rhs: Booking) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Resource Type
enum ResourceType: String, Codable, CaseIterable {
    case librarySpace = "library_space"
    case room = "room"
    case equipment = "equipment"

    var displayName: String {
        switch self {
        case .librarySpace:
            return "Library Space"
        case .room:
            return "Room"
        case .equipment:
            return "Equipment"
        }
    }
}

// MARK: - Booking Status
enum BookingStatus: String, Codable {
    case confirmed = "confirmed"
    case pending = "pending"
    case cancelled = "cancelled"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .confirmed:
            return "Confirmed"
        case .pending:
            return "Pending"
        case .cancelled:
            return "Cancelled"
        case .completed:
            return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .confirmed:
            return .green
        case .pending:
            return .orange
        case .cancelled:
            return .red
        case .completed:
            return .blue
        }
    }
}

// MARK: - Booking Slot
struct BookingSlot: Identifiable, Codable {
    let id: String
    let resourceId: String
    let startTime: Date
    let endTime: Date
    let isAvailable: Bool

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}
