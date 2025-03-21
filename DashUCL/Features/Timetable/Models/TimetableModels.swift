import Foundation

// MARK: - Coding User Info Keys
extension CodingUserInfoKey {
    static let contextDate = CodingUserInfoKey(rawValue: "contextDate")!
}

// MARK: - Date Formatter
extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - Timetable Models Namespace
enum Timetable {
    // MARK: - Event
    struct Event: Codable, Identifiable {
        let id: String
        let location: Location
        let module: Module
        let startTime: Date
        let endTime: Date
        let duration: Int
        let sessionType: String
        let sessionTypeStr: String
        let sessionGroup: String
        let sessionTitle: String
        let contact: String

        enum CodingKeys: String, CodingKey {
            case location, module, duration, contact
            case id = "session_id"
            case startTime = "start_time"
            case endTime = "end_time"
            case sessionType = "session_type"
            case sessionTypeStr = "session_type_str"
            case sessionGroup = "session_group"
            case sessionTitle = "session_title"
        }
    }

    // MARK: - Module
    struct Module: Codable {
        let lecturer: Lecturer
        let moduleId: String
        let name: String
        let departmentId: String
        let departmentName: String

        enum CodingKeys: String, CodingKey {
            case lecturer, name
            case moduleId = "module_id"
            case departmentId = "department_id"
            case departmentName = "department_name"
        }
    }

    // MARK: - Lecturer
    struct Lecturer: Codable {
        let name: String
        let departmentId: String
        let departmentName: String
        let email: String

        enum CodingKeys: String, CodingKey {
            case name, email
            case departmentId = "department_id"
            case departmentName = "department_name"
        }
    }

    // MARK: - Location
    struct Location: Codable {
        let name: String
        let address: [String]
        let siteName: String
        let type: String
        let capacity: Int
        let coordinates: Coordinates

        enum CodingKeys: String, CodingKey {
            case name, address, type, capacity, coordinates
            case siteName = "site_name"
        }
    }

    // MARK: - Coordinates
    struct Coordinates: Codable {
        let lat: String
        let lng: String
    }

    // MARK: - Department
    struct Department: Codable {
        let departmentId: String
        let name: String

        enum CodingKeys: String, CodingKey {
            case name
            case departmentId = "department_id"
        }
    }

    // MARK: - Course
    struct Course: Codable {
        let courseName: String
        let courseId: String
        let years: Int

        enum CodingKeys: String, CodingKey {
            case years
            case courseName = "course_name"
            case courseId = "course_id"
        }
    }

    // MARK: - Module Instance
    struct ModuleInstance: Codable {
        let fullModuleId: String
        let classSize: Int
        let delivery: Delivery
        let periods: Period
        let instanceCode: String

        enum CodingKeys: String, CodingKey {
            case classSize = "class_size"
            case fullModuleId = "full_module_id"
            case delivery, periods
            case instanceCode = "instance_code"
        }
    }

    // MARK: - Module Delivery
    struct Delivery: Codable {
        let fheqLevel: Int
        let isUndergraduate: Bool
        let studentType: String

        enum CodingKeys: String, CodingKey {
            case fheqLevel = "fheq_level"
            case isUndergraduate = "is_undergraduate"
            case studentType = "student_type"
        }
    }

    // MARK: - Module Period
    struct Period: Codable {
        let teachingPeriods: TeachingPeriods
        let yearLong: Bool
        let lsr: Bool
        let summerSchool: SummerSchool

        enum CodingKeys: String, CodingKey {
            case teachingPeriods = "teaching_periods"
            case yearLong = "year_long"
            case lsr
            case summerSchool = "summer_school"
        }
    }

    // MARK: - Teaching Periods
    struct TeachingPeriods: Codable {
        let term1: Bool
        let term2: Bool
        let term3: Bool
        let term1NextYear: Bool
        let summer: Bool

        enum CodingKeys: String, CodingKey {
            case term1 = "term_1"
            case term2 = "term_2"
            case term3 = "term_3"
            case term1NextYear = "term_1_next_year"
            case summer
        }
    }

    // MARK: - Summer School
    struct SummerSchool: Codable {
        let isSummerSchool: Bool
        let sessions: SummerSessions

        enum CodingKeys: String, CodingKey {
            case isSummerSchool = "is_summer_school"
            case sessions
        }
    }

    // MARK: - Summer Sessions
    struct SummerSessions: Codable {
        let session1: Bool
        let session2: Bool

        enum CodingKeys: String, CodingKey {
            case session1 = "session_1"
            case session2 = "session_2"
        }
    }
}

// MARK: - Timetable Response
struct TimetableResponse: Codable {
    let ok: Bool
    let timetable: [String: [TimetableEvent]]

    enum CodingKeys: String, CodingKey {
        case ok
        case timetable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode the 'ok' flag
        ok = try container.decode(Bool.self, forKey: .ok)

        // Debug log
        print("TimetableResponse - Decoded ok flag: \(ok)")

        // Try to decode the timetable
        if let timetableContainer = try? container.nestedContainer(
            keyedBy: DynamicDateCodingKey.self, forKey: .timetable)
        {
            print("Found nested timetable container")
            var timeTable = [String: [TimetableEvent]]()

            // Get all date keys
            let dateKeys = timetableContainer.allKeys
            print("Found \(dateKeys.count) date keys: \(dateKeys.map { $0.stringValue })")

            // Process each date key
            for dateKey in dateKeys {
                let dateString = dateKey.stringValue

                // Simply decode the events without trying to add context to decoder
                let events = try timetableContainer.decode([TimetableEvent].self, forKey: dateKey)
                print("Decoded \(events.count) events for date \(dateString)")
                timeTable[dateString] = events
            }

            self.timetable = timeTable
        } else {
            // If that fails, try to decode as a direct dictionary
            print("Falling back to direct dictionary decoding for timetable")
            self.timetable = try container.decode(
                [String: [TimetableEvent]].self, forKey: .timetable)
        }
    }
}

// Dynamic coding key for date strings
struct DynamicDateCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// MARK: - Timetable Data
struct TimetableData: Codable {
    let events: [TimetableEvent]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        do {
            // First try to decode as a TimetableResponse
            let response = try container.decode(TimetableResponse.self)
            print(
                "Successfully decoded as TimetableResponse with \(response.timetable.count) dates")
            self.events = response.timetable.values.flatMap { $0 }
        } catch let responseError {
            print("Failed to decode as TimetableResponse: \(responseError)")

            // If that fails, try to decode as a direct dictionary of events by date
            do {
                let eventsDictionary = try container.decode([String: [TimetableEvent]].self)
                print("Successfully decoded as dictionary with \(eventsDictionary.count) dates")
                self.events = eventsDictionary.values.flatMap { $0 }
            } catch let dictError {
                print("Failed to decode as dictionary: \(dictError)")

                // If both approaches fail, try as a direct array
                do {
                    let eventsArray = try container.decode([TimetableEvent].self)
                    print("Successfully decoded as direct array with \(eventsArray.count) events")
                    self.events = eventsArray
                } catch let arrayError {
                    print("Failed to decode as direct array: \(arrayError)")

                    // Last attempt: Try to decode from a JSON object containing a data field
                    do {
                        // Try to decode as APIResponse containing TimetableEvents directly
                        let response = try container.decode(APIResponse<[TimetableEvent]>.self)
                        if let eventsData = response.data {
                            print("Successfully decoded from APIResponse<[TimetableEvent]>")
                            self.events = eventsData
                        } else {
                            print("APIResponse<[TimetableEvent]> had nil data")
                            self.events = []
                        }
                    } catch {
                        print("All parsing attempts failed for timetable data: \(error)")
                        self.events = []
                    }
                }
            }
        }
    }

    init(events: [TimetableEvent]) {
        self.events = events
    }
}

// MARK: - Event
struct TimetableEvent: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: Int
    let location: TimetableLocation
    let module: TimetableModule
    let sessionType: String
    let sessionTypeStr: String
    let sessionGroup: String
    let sessionTitle: String
    let contact: String

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case location
        case module
        case sessionType = "session_type"
        case sessionTypeStr = "session_type_str"
        case sessionGroup = "session_group"
        case sessionTitle = "session_title"
        case contact
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode other properties first
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.location = try container.decode(TimetableLocation.self, forKey: .location)
        self.module = try container.decode(TimetableModule.self, forKey: .module)
        self.sessionType = try container.decode(String.self, forKey: .sessionType)
        self.sessionTypeStr = try container.decode(String.self, forKey: .sessionTypeStr)
        self.sessionGroup = try container.decodeIfPresent(String.self, forKey: .sessionGroup) ?? ""
        self.sessionTitle = try container.decode(String.self, forKey: .sessionTitle)
        self.contact = try container.decode(String.self, forKey: .contact)

        // Decode date strings
        let startTimeString = try container.decode(String.self, forKey: .startTime)
        let endTimeString = try container.decode(String.self, forKey: .endTime)

        print("Parsing time strings: \(startTimeString) - \(endTimeString)")

        // Try multiple date formats
        let dateFormatters = [
            DateFormatter.iso8601Full,  // Try ISO8601 first
            {
                // Try time-only format (HH:mm)
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter
            }(),
        ]

        var parsedStartTime: Date?
        var parsedEndTime: Date?

        // Get the proper date context if it's in HH:mm format
        let contextDate: Date?

        // Extract date from decoder's userInfo if available
        if let contextDateString = decoder.userInfo[.contextDate] as? String,
            let date = ISO8601DateFormatter().date(from: contextDateString)
        {
            contextDate = date
        } else {
            // Default to nil - we'll handle it later
            contextDate = nil
        }

        // Try each formatter
        for formatter in dateFormatters {
            // Check if this is a time-only format (HH:mm)
            let isTimeOnly = formatter.dateFormat == "HH:mm"

            if isTimeOnly && startTimeString.count <= 5 && endTimeString.count <= 5 {
                // This is definitely a time-only format (like "11:00")
                if let startTime = formatter.date(from: startTimeString),
                    let endTime = formatter.date(from: endTimeString)
                {
                    // Use context date if available, otherwise use today's date
                    let calendar = Calendar.current
                    let baseDate = contextDate ?? Date()

                    // Extract time components
                    let startComponents = calendar.dateComponents(
                        [.hour, .minute], from: startTime)
                    let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

                    // Create date with the time components
                    let dateComponents = calendar.dateComponents(
                        [.year, .month, .day], from: baseDate)

                    var finalStartComponents = dateComponents
                    finalStartComponents.hour = startComponents.hour
                    finalStartComponents.minute = startComponents.minute

                    var finalEndComponents = dateComponents
                    finalEndComponents.hour = endComponents.hour
                    finalEndComponents.minute = endComponents.minute

                    if let finalStartTime = calendar.date(from: finalStartComponents),
                        let finalEndTime = calendar.date(from: finalEndComponents)
                    {
                        parsedStartTime = finalStartTime
                        parsedEndTime = finalEndTime
                        print("Parsed using time-only format")
                        break
                    }
                }
            } else if !isTimeOnly {
                // Try full ISO format
                if let startTime = formatter.date(from: startTimeString),
                    let endTime = formatter.date(from: endTimeString)
                {
                    parsedStartTime = startTime
                    parsedEndTime = endTime
                    print("Parsed using ISO format")
                    break
                }
            }
        }

        // Check if we successfully parsed the dates
        guard let startTime = parsedStartTime, let endTime = parsedEndTime else {
            // Last resort: create dates manually if they look like HH:MM format
            if startTimeString.count <= 5 && endTimeString.count <= 5,
                startTimeString.contains(":") && endTimeString.contains(":")
            {
                let calendar = Calendar.current
                let baseDate = contextDate ?? Date()

                // Try to extract hours and minutes manually
                let startParts = startTimeString.split(separator: ":")
                let endParts = endTimeString.split(separator: ":")

                if startParts.count == 2 && endParts.count == 2,
                    let startHour = Int(startParts[0]), let startMinute = Int(startParts[1]),
                    let endHour = Int(endParts[0]), let endMinute = Int(endParts[1])
                {
                    var startComponents = calendar.dateComponents(
                        [.year, .month, .day], from: baseDate)
                    startComponents.hour = startHour
                    startComponents.minute = startMinute

                    var endComponents = calendar.dateComponents(
                        [.year, .month, .day], from: baseDate)
                    endComponents.hour = endHour
                    endComponents.minute = endMinute

                    if let manualStartTime = calendar.date(from: startComponents),
                        let manualEndTime = calendar.date(from: endComponents)
                    {
                        self.startTime = manualStartTime
                        self.endTime = manualEndTime
                        print("Manually created dates from time components")
                        return
                    }
                }
            }

            throw DecodingError.dataCorruptedError(
                forKey: .startTime,
                in: container,
                debugDescription:
                    "Could not parse date strings: \(startTimeString), \(endTimeString)"
            )
        }

        self.startTime = startTime
        self.endTime = endTime
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode dates as strings
        try container.encode(DateFormatter.iso8601Full.string(from: startTime), forKey: .startTime)
        try container.encode(DateFormatter.iso8601Full.string(from: endTime), forKey: .endTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(location, forKey: .location)
        try container.encode(module, forKey: .module)
        try container.encode(sessionType, forKey: .sessionType)
        try container.encode(sessionTypeStr, forKey: .sessionTypeStr)
        try container.encode(sessionGroup, forKey: .sessionGroup)
        try container.encode(sessionTitle, forKey: .sessionTitle)
        try container.encode(contact, forKey: .contact)
    }
}

// MARK: - Location
struct TimetableLocation: Codable {
    let name: String
    let address: [String]
    let siteName: String
    let type: String
    let capacity: Int
    let coordinates: TimetableCoordinates

    enum CodingKeys: String, CodingKey {
        case name
        case address
        case siteName = "site_name"
        case type
        case capacity
        case coordinates
    }
}

// MARK: - Module
struct TimetableModule: Codable {
    let moduleId: String
    let name: String
    let departmentId: String
    let departmentName: String
    let lecturer: TimetableLecturer

    enum CodingKeys: String, CodingKey {
        case moduleId = "module_id"
        case name
        case departmentId = "department_id"
        case departmentName = "department_name"
        case lecturer
    }
}

// MARK: - Lecturer
struct TimetableLecturer: Codable {
    let name: String
    let departmentId: String
    let departmentName: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case name
        case departmentId = "department_id"
        case departmentName = "department_name"
        case email
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle possible null values
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        departmentId = try container.decodeIfPresent(String.self, forKey: .departmentId) ?? ""
        departmentName = try container.decodeIfPresent(String.self, forKey: .departmentName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? "Unknown"
    }
}

// MARK: - Coordinates
struct TimetableCoordinates: Codable {
    let lat: String
    let lng: String

    enum CodingKeys: String, CodingKey {
        case lat
        case lng
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle possible null values
        lat = try container.decodeIfPresent(String.self, forKey: .lat) ?? "0"
        lng = try container.decodeIfPresent(String.self, forKey: .lng) ?? "0"
    }
}
