import Foundation
import SwiftUI

/// Test User Data Model
/// Provides mock user data for test mode

enum TestUserData {
    // MARK: - Course Data

    /// Get test course data
    static var mockCourses: [TestCourse] {
        return TestTimetableData.courses
    }

    // MARK: - Booking Data

    // Test user's booking data
    static let mockBookings: [TestBooking] = [
        TestBooking(
            id: "12345",
            startTime: Date().addingTimeInterval(86400),  // Tomorrow
            endTime: Date().addingTimeInterval(86400 + 7200),  // Tomorrow + 2 hours
            resourceName: "Science Library - Study Pod 3",
            resourceId: "sci-lib-pod-3",
            location: "Science Library",
            status: "Confirmed"
        ),
        TestBooking(
            id: "67890",
            startTime: Date().addingTimeInterval(172800),  // Day after tomorrow
            endTime: Date().addingTimeInterval(172800 + 7200),  // Day after tomorrow + 2 hours
            resourceName: "Main Library - Group Study Room 2",
            resourceId: "main-lib-room-2",
            location: "Main Library",
            status: "Confirmed"
        ),
    ]

    // MARK: - Space Data

    /// Get test space data
    static var mockSpaces: [TestSpaceResult] {
        // Convert TestSpaceData data to TestSpaceResult
        return TestSpaceData.allSpaces.map { space in
            return TestSpaceResult(
                id: space.id,
                name: space.name,
                description: space.description,
                freeSeats: space.freeSeats,
                totalSeats: space.totalSeats,
                occupancyPercentage: space.occupancyPercentage
            )
        }
    }

    // MARK: - Staff Data

    /// Get test staff data
    static var mockStaffMembers: [TestStaffData.StaffMember] {
        return TestStaffData.staffMembers
    }

    // MARK: - Conversion Methods

    // Convert test space results to SpaceResult type used in the project
    static func convertToSpaceResult(_ testResult: TestSpaceResult) -> SpaceResult {
        return SpaceResult(
            id: testResult.id,
            name: testResult.name,
            description: testResult.description,
            freeSeats: testResult.freeSeats,
            totalSeats: testResult.totalSeats,
            occupancyPercentage: testResult.occupancyPercentage
        )
    }

    // Convert test bookings to Booking type used in the project
    static func convertToBooking(_ testBooking: TestBooking) -> Booking {
        return Booking(
            id: testBooking.id,
            resourceId: testBooking.resourceId,
            resourceType: .librarySpace,
            startTime: testBooking.startTime,
            endTime: testBooking.endTime,
            status: .confirmed,
            notes: testBooking.resourceName
        )
    }

    // MARK: - Get Data Methods

    // Get converted space data
    static var spaceResults: [SpaceResult] {
        // Directly use TestSpaceData data
        return TestSpaceData.allSpaces
    }

    // Get converted booking data
    static var bookings: [Booking] {
        return mockBookings.map { convertToBooking($0) }
    }

    // Get learning space data
    static var studySpaces: [SpaceResult] {
        return TestSpaceData.studySpaces
    }

    // Get computer cluster data
    static var computerClusters: [SpaceResult] {
        return TestSpaceData.computerClusters
    }

    // Get course period data
    static var coursePeriods: [TestPeriod] {
        return TestTimetableData.allPeriods
    }

    // Get staff data
    static var staffMembers: [TestStaffData.StaffMember] {
        return TestStaffData.staffMembers
    }
}

// Simulated course model
struct TestCourse: Identifiable, Codable {
    let id: String
    let name: String
    let department: String
    let faculty: String
    let year: String
    let leadDepartment: String
    let isActive: Bool
    let modules: [TestModule]

    // Add departmentId helper calculation attribute
    var departmentId: String {
        return department.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}

// Simulated module model
struct TestModule: Identifiable, Codable {
    let id: String
    let name: String
    let instances: [TestModuleInstance]
}

// Simulated module instance model
struct TestModuleInstance: Identifiable, Codable {
    let id: String
    let delivery: String
    let periods: [TestPeriod]
}

// Simulated period model
struct TestPeriod: Identifiable, Codable {
    let id: String
    let startTime: String
    let endTime: String
    let day: String
    let location: String
    let type: String
    let weeks: [Int]
}

// Simulated booking model
struct TestBooking: Identifiable, Codable {
    let id: String
    let startTime: Date
    let endTime: Date
    let resourceName: String
    let resourceId: String
    let location: String
    let status: String
}

// Simulated space result model
struct TestSpaceResult: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let freeSeats: Int
    let totalSeats: Int
    let occupancyPercentage: Int
}
