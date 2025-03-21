import Foundation
import SwiftUI

// Use model classes defined in UCLModels
// No need to import UCLModels as it's in the same target

// Booking Models
struct LibCalBooking: Codable, Identifiable {
    let id: String
    let bookId: String
    let firstName: String
    let lastName: String
    let email: String
    let checkInCode: String
    let eid: Int
    let cid: Int
    let lid: Int
    let fromDate: Date
    let toDate: Date
    let created: Date
    let status: String
    let locationName: String
    let categoryName: String
    let itemName: String
    let seatId: Int?
    let seatName: String?
    let cancelled: Date?

    enum CodingKeys: String, CodingKey {
        case id = "book_id"
        case bookId = "booking_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case checkInCode = "check_in_code"
        case eid, cid, lid
        case fromDate = "from_date"
        case toDate = "to_date"
        case created, status
        case locationName = "location_name"
        case categoryName = "category_name"
        case itemName = "item_name"
        case seatId = "seat_id"
        case seatName = "seat_name"
        case cancelled
    }
}

// MARK: - Booking Request
struct LibCalBookingRequest: Codable {
    let start: String
    let test: Int
    let nickname: String?
    let bookings: [LibCalBookingItem]
}

// MARK: - Booking Item
struct LibCalBookingItem: Codable {
    let id: Int
    let to: String
    let seatId: Int?

    enum CodingKeys: String, CodingKey {
        case id, to
        case seatId = "seat_id"
    }
}

// MARK: - Booking Response
struct LibCalBookingResponse: Codable {
    let success: String?
    let bookingId: String
    let cost: String

    enum CodingKeys: String, CodingKey {
        case success
        case bookingId = "booking_id"
        case cost
    }
}

// MARK: - Booking Category
struct LibCalCategory: Codable {
    let cid: Int
    let formid: Int
    let name: String
    let isPublic: Int

    enum CodingKeys: String, CodingKey {
        case cid, formid, name
        case isPublic = "public"
    }
}

// MARK: - Booking Location
struct LibCalLocation: Codable {
    let lid: Int
    let name: String
    let isPublic: Int
    let terms: String?

    enum CodingKeys: String, CodingKey {
        case lid, name
        case isPublic = "public"
        case terms
    }
}

// MARK: - Booking Space
struct LibCalSpace: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let image: String
    let capacity: Int
    let formid: Int
    let isBookableAsWhole: Bool
    let isAccessible: Bool
    let isPowered: Bool
    let zoneId: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description, image, capacity, formid
        case isBookableAsWhole = "is_bookable_as_whole"
        case isAccessible = "is_accessible"
        case isPowered = "is_powered"
        case zoneId = "zone_id"
    }
}

// MARK: - Booking Seat
struct LibCalSeat: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let isAccessible: Bool
    let isPowered: Bool
    let image: String
    let status: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case isAccessible = "is_accessible"
        case isPowered = "is_powered"
        case image, status
    }
}

// MARK: - Booking Zone
struct LibCalZone: Codable, Identifiable {
    let id: Int
    let name: String
    let spaces: [LibCalSpaceInZone]
}

// MARK: - Space in Zone
struct LibCalSpaceInZone: Codable, Identifiable {
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
