import Foundation
import SwiftUI

/// Test Timetable Data
/// Provides mock timetable data, including course schedules for a semester
enum TestTimetableData {
    // MARK: - Course Types

    /// Course Type Enumeration
    enum SessionType: String, CaseIterable {
        case lecture = "Lecture"
        case lab = "Workshop_Lab"
        case tutorial = "Tutorial"
        case seminar = "Seminar"
        case workshop = "Workshop"

        var color: Color {
            switch self {
            case .lecture:
                return .blue
            case .lab:
                return .green
            case .tutorial:
                return .orange
            case .seminar:
                return .purple
            case .workshop:
                return .teal
            }
        }

        var displayName: String {
            switch self {
            case .lecture:
                return "Lecture"
            case .lab:
                return "Workshop"
            case .tutorial:
                return "Tutorial"
            case .seminar:
                return "Seminar"
            case .workshop:
                return "Workshop"
            }
        }
    }

    // MARK: - Course Data

    /// Mock course data - Courses scheduled from Monday to Friday as required, March 10, 2025 to April 10, 2025
    static let courses: [TestCourse] = [
        // Computer Science courses
        TestCourse(
            id: "COMP0001",
            name: "Introduction to Programming",
            department: "Computer Science",
            faculty: "Engineering Sciences",
            year: "2024/25",
            leadDepartment: "Computer Science",
            isActive: true,
            modules: [
                TestModule(
                    id: "COMP0001",
                    name: "Introduction to Programming",
                    instances: [
                        TestModuleInstance(
                            id: "COMP0001-A",
                            delivery: "In Person",
                            periods: [
                                // Monday's Lecture
                                TestPeriod(
                                    id: "COMP0001-A-1",
                                    startTime: "09:00",
                                    endTime: "11:00",
                                    day: "Monday",
                                    location: "Roberts Building 106",
                                    type: "Lecture",
                                    weeks: Array(1...5)  // Covers 5 weeks from March 10 to April 10
                                ),
                                // Monday's Tutorial
                                TestPeriod(
                                    id: "COMP0001-A-2",
                                    startTime: "14:00",
                                    endTime: "16:00",
                                    day: "Monday",
                                    location: "Roberts Building 309",
                                    type: "Tutorial",
                                    weeks: Array(1...5)
                                ),
                            ]
                        )
                    ]
                )
            ]
        ),

        // Mathematics courses
        TestCourse(
            id: "MATH0001",
            name: "Mathematical Methods",
            department: "Mathematics",
            faculty: "Mathematical & Physical Sciences",
            year: "2024/25",
            leadDepartment: "Mathematics",
            isActive: true,
            modules: [
                TestModule(
                    id: "MATH0001",
                    name: "Mathematical Methods",
                    instances: [
                        TestModuleInstance(
                            id: "MATH0001-A",
                            delivery: "In Person",
                            periods: [
                                // Tuesday's Workshop
                                TestPeriod(
                                    id: "MATH0001-A-1",
                                    startTime: "10:00",
                                    endTime: "12:00",
                                    day: "Tuesday",
                                    location: "Malet Place Engineering Building 1.02",
                                    type: "Workshop",
                                    weeks: Array(1...5)
                                ),
                                // Tuesday's Lecture
                                TestPeriod(
                                    id: "MATH0001-A-2",
                                    startTime: "14:00",
                                    endTime: "16:00",
                                    day: "Tuesday",
                                    location: "Drayton House B20",
                                    type: "Lecture",
                                    weeks: Array(1...5)
                                ),
                            ]
                        )
                    ]
                )
            ]
        ),

        // Physics courses
        TestCourse(
            id: "PHYS0001",
            name: "Physics Fundamentals",
            department: "Physics",
            faculty: "Mathematical & Physical Sciences",
            year: "2024/25",
            leadDepartment: "Physics",
            isActive: true,
            modules: [
                TestModule(
                    id: "PHYS0001",
                    name: "Physics Fundamentals",
                    instances: [
                        TestModuleInstance(
                            id: "PHYS0001-A",
                            delivery: "In Person",
                            periods: [
                                // Wednesday's first Lecture
                                TestPeriod(
                                    id: "PHYS0001-A-1",
                                    startTime: "09:00",
                                    endTime: "11:00",
                                    day: "Wednesday",
                                    location: "Physics Building A1",
                                    type: "Lecture",
                                    weeks: Array(1...5)
                                ),
                                // Wednesday's second Lecture
                                TestPeriod(
                                    id: "PHYS0001-A-2",
                                    startTime: "13:00",
                                    endTime: "15:00",
                                    day: "Wednesday",
                                    location: "Physics Building B10",
                                    type: "Lecture",
                                    weeks: Array(1...5)
                                ),
                                // Wednesday's Seminar
                                TestPeriod(
                                    id: "PHYS0001-A-3",
                                    startTime: "16:00",
                                    endTime: "18:00",
                                    day: "Wednesday",
                                    location: "Physics Building C5",
                                    type: "Seminar",
                                    weeks: Array(1...5)
                                ),
                            ]
                        )
                    ]
                )
            ]
        ),

        // Artificial Intelligence courses
        TestCourse(
            id: "COMP0101",
            name: "Artificial Intelligence",
            department: "Computer Science",
            faculty: "Engineering Sciences",
            year: "2024/25",
            leadDepartment: "Computer Science",
            isActive: true,
            modules: [
                TestModule(
                    id: "COMP0101",
                    name: "Artificial Intelligence",
                    instances: [
                        TestModuleInstance(
                            id: "COMP0101-A",
                            delivery: "In Person",
                            periods: [
                                // Thursday's Lab
                                TestPeriod(
                                    id: "COMP0101-A-1",
                                    startTime: "13:00",
                                    endTime: "15:00",
                                    day: "Thursday",
                                    location: "Roberts Building 508",
                                    type: "Workshop",
                                    weeks: Array(1...5)
                                )
                            ]
                        )
                    ]
                )
            ]
        ),

        // Software Engineering courses
        TestCourse(
            id: "COMP0201",
            name: "Software Engineering",
            department: "Computer Science",
            faculty: "Engineering Sciences",
            year: "2024/25",
            leadDepartment: "Computer Science",
            isActive: true,
            modules: [
                TestModule(
                    id: "COMP0201",
                    name: "Software Engineering",
                    instances: [
                        TestModuleInstance(
                            id: "COMP0201-A",
                            delivery: "In Person",
                            periods: [
                                // Friday's Lecture
                                TestPeriod(
                                    id: "COMP0201-A-1",
                                    startTime: "14:00",
                                    endTime: "16:00",
                                    day: "Friday",
                                    location: "Roberts Building 421",
                                    type: "Lecture",
                                    weeks: Array(1...5)
                                )
                            ]
                        )
                    ]
                )
            ]
        ),
    ]

    // MARK: - Helper Methods

    /// Get all course periods
    static var allPeriods: [TestPeriod] {
        var periods: [TestPeriod] = []
        for course in courses {
            for module in course.modules {
                for instance in module.instances {
                    periods.append(contentsOf: instance.periods)
                }
            }
        }
        return periods
    }

    /// Get course periods for specific week
    static func periodsForWeek(_ weekNumber: Int) -> [TestPeriod] {
        return allPeriods.filter { $0.weeks.contains(weekNumber) }
    }

    /// Get course periods for specific date
    static func periodsForDay(_ day: String) -> [TestPeriod] {
        return allPeriods.filter { $0.day == day }
    }

    /// Get course periods for specific date and week
    static func periodsForDayAndWeek(day: String, week: Int) -> [TestPeriod] {
        return allPeriods.filter { $0.day == day && $0.weeks.contains(week) }
    }

    /// Get course color
    static func colorForSessionType(_ type: String) -> Color {
        if let sessionType = SessionType(rawValue: type) {
            return sessionType.color
        }
        return .gray
    }

    /// Format date to ISO 8601 string
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    /// Convert TestPeriod to TimetableEvent
    func convertToTimetableEvents() -> [TimetableEvent] {
        var timetableEvents: [TimetableEvent] = []

        // Date formatter
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let dayNames = [
            "", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
        ]
        let todayName = dayNames[weekday]  // Get today's English name

        // Convert TestPeriod to TimetableEvent
        for period in TestTimetableData.allPeriods {
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

            // Get today's date string
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            _ = dateFormatter.string(from: today)

            // Convert start and end times
            guard let startTime = timeFormatter.date(from: period.startTime),
                let endTime = timeFormatter.date(from: period.endTime)
            else {
                continue
            }

            // Process date
            var periodDate: Date

            // 1. Create some courses for today
            if period.day == todayName {
                periodDate = today
            } else {
                // Calculate date offset (original logic)
                let dayMap = [
                    "Monday": 2, "Tuesday": 3, "Wednesday": 4, "Thursday": 5, "Friday": 6,
                    "Saturday": 7, "Sunday": 1,
                ]
                let periodDay = dayMap[period.day] ?? 2

                // Calculate days difference between today and course day
                var dayDiff = periodDay - weekday
                if dayDiff <= 0 {
                    dayDiff += 7  // If it's a past day, move to next week
                }

                // Create course date
                periodDate = calendar.date(byAdding: .day, value: dayDiff, to: today)!
            }

            _ = dateFormatter.string(from: periodDate)

            // Combine date and time
            var periodStartComponents = calendar.dateComponents(
                [.year, .month, .day], from: periodDate)
            let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            periodStartComponents.hour = startTimeComponents.hour
            periodStartComponents.minute = startTimeComponents.minute

            var periodEndComponents = calendar.dateComponents(
                [.year, .month, .day], from: periodDate)
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
            // Create a JSON dictionary conforming to API format
            let eventDict: [String: Any] = [
                "start_time": TestTimetableData.formatDate(fullStartTime),
                "end_time": TestTimetableData.formatDate(fullEndTime),
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
            // Reuse previously created dateFormatter
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

        // 2. Add extra courses for today (to ensure at least a few courses for the day)
        let todayCourses = [
            ("Morning Swift Workshop", "09:30", "11:30", "Workshop", "Roberts Building 105"),
            ("iOS App Development", "13:00", "15:00", "Lecture", "Darwin Building B15"),
            (
                "SwiftUI Interface Design", "15:30", "17:00", "Workshop",
                "Malet Place Engineering Building 1.21"
            ),
            ("Mobile App Testing", "17:30", "19:00", "Tutorial", "Cruciform Building B.404 - LT1"),
        ]

        // Add some extra courses for each day to ensure enough courses
        // Weekly courses
        let weekdayCourses: [[(String, String, String, String, String)]] = [
            // Sunday
            [
                ("Web Development Basics", "08:30", "10:00", "Lecture", "Roberts Building 101"),
                ("Database Systems", "13:30", "15:30", "Workshop", "Malet Place 1.05"),
            ],
            // Monday
            [
                ("UI/UX Design", "08:00", "10:00", "Workshop", "Roberts Building 305"),
                ("Mobile App Architecture", "13:30", "15:00", "Tutorial", "Darwin Building B10"),
            ],
            // Tuesday
            [
                ("Cloud Computing", "08:30", "10:30", "Lecture", "Drayton House G01"),
                ("DevOps Practices", "13:30", "15:30", "Workshop", "Malet Place 1.12"),
            ],
            // Wednesday
            [
                ("Software Testing", "08:30", "10:30", "Tutorial", "Cruciform Building B.304"),
                ("Agile Methodology", "13:00", "15:00", "Lecture", "Roberts Building 422"),
            ],
            // Thursday
            [
                ("Network Security", "08:00", "10:00", "Lecture", "Chandler House B01"),
                ("API Development", "13:30", "15:30", "Workshop", "Roberts Building 309"),
            ],
            // Friday
            [
                ("Project Management", "08:30", "10:00", "Tutorial", "Darwin Building B05"),
                ("Data Visualization", "13:00", "15:00", "Workshop", "Malet Place 1.10"),
            ],
            // Saturday
            [
                ("Blockchain Fundamentals", "08:00", "10:00", "Lecture", "Chandler House G15"),
                ("Entrepreneurship", "13:30", "15:00", "Tutorial", "Roberts Building 106"),
            ],
        ]

        // Add today's courses
        for (index, course) in todayCourses.enumerated() {
            addExtraCourse(
                timetableEvents: &timetableEvents,
                courseTitle: course.0,
                startTime: course.1,
                endTime: course.2,
                type: course.3,
                location: course.4,
                moduleId: "TODAY\(index)",
                day: today
            )
        }

        // Add daily fixed courses
        for dayOffset in 0..<7 {
            // Create corresponding date
            guard
                let date = calendar.date(
                    byAdding: .day, value: dayOffset,
                    to:
                        calendar.startOfDay(for: today))
            else {
                continue
            }

            // Get corresponding day of week (0-6, 0 represents Sunday)
            let weekdayIndex = (calendar.component(.weekday, from: date) + 6) % 7

            // Get this day's courses
            let coursesForDay = weekdayCourses[weekdayIndex]

            // Add courses for this day
            for (courseIndex, course) in coursesForDay.enumerated() {
                addExtraCourse(
                    timetableEvents: &timetableEvents,
                    courseTitle: course.0,
                    startTime: course.1,
                    endTime: course.2,
                    type: course.3,
                    location: course.4,
                    moduleId: "DAY\(weekdayIndex)_\(courseIndex)",
                    day: date
                )
            }
        }

        return timetableEvents
    }

    /// Add extra course helper method
    private func addExtraCourse(
        timetableEvents: inout [TimetableEvent],
        courseTitle: String,
        startTime: String,
        endTime: String,
        type: String,
        location: String,
        moduleId: String,
        day: Date
    ) {
        // Get today's date
        let calendar = Calendar.current

        // Create start and end times
        let startTimeParts = startTime.split(separator: ":")
        let endTimeParts = endTime.split(separator: ":")

        var startComponents = calendar.dateComponents([.year, .month, .day], from: day)
        startComponents.hour = Int(startTimeParts[0])
        startComponents.minute = Int(startTimeParts[1])

        var endComponents = calendar.dateComponents([.year, .month, .day], from: day)
        endComponents.hour = Int(endTimeParts[0])
        endComponents.minute = Int(endTimeParts[1])

        guard let startTime = calendar.date(from: startComponents),
            let endTime = calendar.date(from: endComponents)
        else {
            return
        }

        // Calculate duration (minutes)
        let duration = Int(endTime.timeIntervalSince(startTime) / 60)

        // Create event object
        // Create a JSON dictionary conforming to API format
        let eventDict: [String: Any] = [
            "start_time": TestTimetableData.formatDate(startTime),
            "end_time": TestTimetableData.formatDate(endTime),
            "duration": duration,
            "location": [
                "name": location,
                "address": [location.components(separatedBy: " ").first ?? "UCL"],
                "site_name": location.components(separatedBy: " ").first ?? "UCL",
                "type": "Teaching Space",
                "capacity": 50,
                "coordinates": [
                    "lat": "51.5248",
                    "lng": "-0.1335",
                ],
            ],
            "module": [
                "module_id": moduleId,
                "name": courseTitle,
                "department_id": "COMP",
                "department_name": "Computer Science",
                "lecturer": [
                    "name": "Professor Johnson",
                    "department_id": "COMP",
                    "department_name": "Computer Science",
                    "email": "professor.johnson@ucl.ac.uk",
                ],
            ],
            "session_type": type,
            "session_type_str": type,
            "session_group": moduleId,
            "session_title": courseTitle,
            "contact": "Professor Johnson",
        ]

        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: eventDict) else {
            return
        }

        // Create context date string
        // Reuse previously created dateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: day) + "T00:00:00Z"

        // Decode to TimetableEvent object
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey(rawValue: "contextDate")!] = dateString

        do {
            let event = try decoder.decode(TimetableEvent.self, from: jsonData)
            timetableEvents.append(event)
        } catch {
            print("Error decoding extra TimetableEvent: \(error)")
        }
    }
}
