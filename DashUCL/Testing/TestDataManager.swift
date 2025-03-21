import Foundation
import SwiftUI

/// Test Data Manager
/// Responsible for initializing and managing test data in test mode
class TestDataManager {
    // Singleton instance
    static let shared = TestDataManager()

    // Cache variables
    private var _cachedTimetableEvents: [TimetableEvent]?
    private var _cachedSpaces: [SpaceResult]?
    private var _cachedStudySpaces: [SpaceResult]?
    private var _cachedComputerClusters: [SpaceResult]?

    // Private initialization method
    private init() {}

    // MARK: - Data Initialization

    /// Initialize test data
    func initializeTestData() {
        print("🧪 Initializing test data...")

        // Clear all caches
        clearCache()

        // Preload timetable data
        let events = cachedTimetableEvents
        print("🧪 Preloaded \(events.count) course events")

        // Preload space data
        let spaces = allSpaces
        let studySpaces = self.studySpaces
        let computerClusters = self.computerClusters
        print(
            "🧪 Preloaded \(spaces.count) spaces (\(studySpaces.count) study spaces, \(computerClusters.count) computer clusters)"
        )
    }

    // MARK: - Space Data

    /// Get all space data
    var allSpaces: [SpaceResult] {
        if _cachedSpaces == nil {
            _cachedSpaces = TestSpaceData.allSpaces
        }
        return _cachedSpaces ?? []
    }

    /// Get study space data
    var studySpaces: [SpaceResult] {
        if _cachedStudySpaces == nil {
            _cachedStudySpaces = TestSpaceData.studySpaces
        }
        return _cachedStudySpaces ?? []
    }

    /// Get computer cluster data
    var computerClusters: [SpaceResult] {
        if _cachedComputerClusters == nil {
            _cachedComputerClusters = TestSpaceData.computerClusters
        }
        return _cachedComputerClusters ?? []
    }

    /// Get space by ID
    func getSpaceById(_ id: String) -> SpaceResult? {
        return allSpaces.first { $0.id == id }
    }

    // MARK: - Course Data

    /// Get all courses
    var allCourses: [TestCourse] {
        return TestUserData.mockCourses
    }

    /// Get all course periods
    var allPeriods: [TestPeriod] {
        return TestUserData.coursePeriods
    }

    /// Convert TestPeriod to TimetableEvent
    func convertToTimetableEvents() -> [TimetableEvent] {
        // If cached events exist, return them directly
        if let cachedEvents = _cachedTimetableEvents, !cachedEvents.isEmpty {
            print("Using cached \(cachedEvents.count) timetable events")
            return cachedEvents
        }

        print("Converting test data to timetable events...")

        // Event list
        var timetableEvents: [TimetableEvent] = []

        // Time formatter
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        // Set start date to March 10, 2025 (Monday)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Create start date (March 10, 2025)
        let calendar = Calendar.current
        var startDateComponents = DateComponents()
        startDateComponents.year = 2025
        startDateComponents.month = 3
        startDateComponents.day = 10

        guard let startDate = calendar.date(from: startDateComponents) else {
            print("Unable to create start date")
            return []
        }

        // Calculate end date (April 10, 2025)
        guard let endDate = calendar.date(byAdding: .day, value: 31, to: startDate) else {
            print("Unable to create end date")
            return []
        }

        // Create current date (starting from start date)
        var currentDate = startDate

        // Generate events for each week until end date
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            let dayNames = [
                "", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
            ]
            let currentDayName = dayNames[weekday]

            // Get course periods for the current day
            let periodsForDay = TestTimetableData.periodsForDay(currentDayName)

            for period in periodsForDay {
                // Find corresponding course and module
                guard
                    let course = TestTimetableData.courses.first(where: {
                        $0.modules.contains(where: {
                            $0.id == period.id.split(separator: "-").first?.description
                        })
                    })
                else {
                    continue
                }

                guard
                    let module = course.modules.first(where: {
                        $0.id == period.id.split(separator: "-").first?.description
                    })
                else {
                    continue
                }

                // Convert start and end time
                guard let startTime = timeFormatter.date(from: period.startTime),
                    let endTime = timeFormatter.date(from: period.endTime)
                else {
                    continue
                }

                // Combine date and time
                var periodStartComponents = calendar.dateComponents(
                    [.year, .month, .day], from: currentDate)
                let startTimeComponents = calendar.dateComponents(
                    [.hour, .minute], from: startTime)
                periodStartComponents.hour = startTimeComponents.hour
                periodStartComponents.minute = startTimeComponents.minute

                var periodEndComponents = calendar.dateComponents(
                    [.year, .month, .day], from: currentDate)
                let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                periodEndComponents.hour = endTimeComponents.hour
                periodEndComponents.minute = endTimeComponents.minute

                guard let fullStartTime = calendar.date(from: periodStartComponents),
                    let fullEndTime = calendar.date(from: periodEndComponents)
                else {
                    continue
                }

                // Calculate duration (minutes)
                let duration = Int(fullEndTime.timeIntervalSince(fullStartTime) / 60)

                // Create event object
                // Create a JSON dictionary in the format of the API
                let eventDict: [String: Any] = [
                    "start_time": formatDate(fullStartTime),
                    "end_time": formatDate(fullEndTime),
                    "duration": duration,
                    "location": [
                        "name": period.location,
                        "address": [period.location.components(separatedBy: " ").first ?? "UCL"],
                        "site_name": period.location.components(separatedBy: " ").first ?? "UCL",
                        "type": "Teaching Space",
                        "capacity": 50,
                        "coordinates": [
                            "lat": "51.5248",
                            "lng": "-0.1335",
                        ],
                    ],
                    "module": [
                        "module_id": module.id,
                        "name": module.name,
                        "department_id": course.departmentId,
                        "department_name": course.department,
                        "lecturer": [
                            "name": "Professor Smith",
                            "department_id": course.departmentId,
                            "department_name": course.department,
                            "email": "professor.smith@ucl.ac.uk",
                        ],
                    ],
                    "session_type": period.type,
                    "session_type_str": period.type,
                    "session_group": module.id,
                    "session_title": module.name,
                    "contact": "Professor Smith",
                ]

                // Convert to JSON data
                guard let jsonData = try? JSONSerialization.data(withJSONObject: eventDict) else {
                    continue
                }

                // Create context date string
                let dateString = dateFormatter.string(from: fullStartTime) + "T00:00:00Z"

                // Decode to TimetableEvent object
                let decoder = JSONDecoder()
                decoder.userInfo[CodingUserInfoKey(rawValue: "contextDate")!] = dateString

                do {
                    let event = try decoder.decode(TimetableEvent.self, from: jsonData)
                    timetableEvents.append(event)
                } catch {
                    print("Error decoding TimetableEvent: \(error)")
                    continue
                }
            }

            // Move to the next day
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }

        // Update cache
        _cachedTimetableEvents = timetableEvents
        print("Successfully converted \(timetableEvents.count) timetable events")

        return timetableEvents
    }

    /// Format date as ISO 8601 string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    /// Get course periods for a specific week
    func periodsForWeek(_ weekNumber: Int) -> [TestPeriod] {
        return TestTimetableData.periodsForWeek(weekNumber)
    }

    /// Get course periods for a specific day
    func periodsForDay(_ day: String) -> [TestPeriod] {
        return TestTimetableData.periodsForDay(day)
    }

    /// Get course periods for a specific day and week
    func periodsForDayAndWeek(day: String, week: Int) -> [TestPeriod] {
        return TestTimetableData.periodsForDayAndWeek(day: day, week: week)
    }

    // MARK: - Booking Data

    /// Get all bookings
    var allBookings: [Booking] {
        return TestUserData.bookings
    }

    // MARK: - Staff Data

    /// Get all staff
    var allStaffMembers: [TestStaffData.StaffMember] {
        return TestUserData.staffMembers
    }

    /// Search staff
    func searchStaff(query: String) -> [TestStaffData.StaffMember] {
        return TestStaffData.searchStaff(query: query)
    }

    /// Get staff by department
    func staffByDepartment(_ department: String) -> [TestStaffData.StaffMember] {
        return TestStaffData.staffByDepartment(department)
    }

    /// Get staff by research interest
    func staffByResearchInterest(_ interest: String) -> [TestStaffData.StaffMember] {
        return TestStaffData.staffByResearchInterest(interest)
    }

    /// Cached timetable events
    var cachedTimetableEvents: [TimetableEvent] {
        if _cachedTimetableEvents == nil {
            _cachedTimetableEvents = convertToTimetableEvents()
        }
        return _cachedTimetableEvents ?? []
    }

    /// Clear cache
    func clearCache() {
        _cachedTimetableEvents = nil
        _cachedSpaces = nil
        _cachedStudySpaces = nil
        _cachedComputerClusters = nil
        print("All test data caches cleared")
    }
}
