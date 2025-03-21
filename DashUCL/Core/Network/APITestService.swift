/*
 * Testing service for validating all UCL API endpoints and recording diagnostics.
 * Automatically runs tests in development environments to validate API health.
 * Records detailed test results including performance metrics and failure diagnostics.
 * Provides test reporting UI for developers to troubleshoot API integration issues.
 */

import Foundation
import SwiftUI

/// API Test Service for testing all available UCL API endpoints and recording results
@MainActor
class APITestService: ObservableObject {
    // Singleton instance
    static let shared = APITestService()

    // Dependencies
    private let networkService = NetworkService()
    private let authManager = AuthManager.shared

    // Auto API testing is disabled by default
    private var enableAutoAPITests = false

    // Test state
    @Published private(set) var isRunningTests = false
    @Published private(set) var testResults: [APITestResult] = []

    // Private initializer
    private init() {
        print("🧪 APITestService initialized")

        // Register for login success notification to run tests automatically
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDidSignIn),
            name: .userDidSignIn,
            object: nil
        )

        print("🧪 APITestService registered for userDidSignIn notifications")
    }

    // Triggered when user signs in successfully
    @objc private func handleUserDidSignIn(notification: Notification) {
        print("🧪 APITestService received userDidSignIn notification!")

        // 检查是否启用了自动API测试
        guard enableAutoAPITests else {
            print("🧪 Auto API tests are disabled. Skipping tests.")
            return
        }

        // Small delay to ensure authentication is fully completed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                print("🧪 Starting API tests after login...")
                await self.runAllTests()
            }
        }
    }

    // Manually trigger all API tests
    func runAllTests() async {
        isRunningTests = true
        testResults = []

        print("\n🧪🧪🧪 UCL API TEST STARTED 🧪🧪🧪")
        print("🧪 Time: \(Date().formatted())")

        // 用户相关
        await testUserInfo()

        // 课表相关
        await testTimetable()
        await testTimetableDepartments()
        await testTimetableByModule()

        // 测试PHIL0041模块
        print("\n🧪 Running targeted test for PHIL0041 module")
        await testPhilosophyModule()

        // 学习空间相关
        await testStudySpaces()
        await testWorkspacesSensorsSummary()
        await testWorkspacesSensorAverages()

        // 房间相关
        await testRooms()
        await testFreeRooms()
        await testRoomEquipment()

        // 预订相关
        await testBookings()

        // 搜索相关
        await testSearchPeople()

        // LibCal相关
        await testLibCalLocations()
        await testLibCalBookings()
        await testLibCalCategoriesAll()
        await testLibCalNickname()

        print("\n🧪🧪🧪 UCL API TEST COMPLETED 🧪🧪🧪")

        // Output summary results
        let successCount = testResults.filter { $0.success }.count
        let failureCount = testResults.filter { !$0.success }.count

        print("\n🧪 Test Results Summary:")
        print("🧪 Success: \(successCount)")
        print("🧪 Failed: \(failureCount)")
        print("🧪 Total: \(testResults.count)")

        // Output detailed results for each API endpoint
        print("\n🧪 Detailed Results:")
        for result in testResults {
            let statusSymbol = result.success ? "✅" : "❌"
            print("🧪 \(statusSymbol) \(result.endpoint): \(result.message)")
        }

        isRunningTests = false

        // Notify that tests are completed
        NotificationCenter.default.post(
            name: .apiTestsCompleted, object: self, userInfo: ["results": testResults])
        print("🧪 API tests completed, posted apiTestsCompleted notification")
    }

    // Test user info API
    private func testUserInfo() async {
        let endpoint = APIEndpoint.userInfo
        print("\n🧪 Testing API: User Info")

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract user info
            let userName = extractUserName(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "User Info",
                    success: true,
                    message: "Successfully retrieved user data, name: \(userName)"
                ))
            print("🧪 ✅ Successfully retrieved user info")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "User Info",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                ))
            print("🧪 ❌ User Info API failed: \(error.localizedDescription)")
        }
    }

    // Extract user name from response data
    private func extractUserName(from data: Data) -> String {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let fullName = json["full_name"] as? String
            {
                return fullName
            }
        } catch {
            print("🧪 Error parsing user info: \(error)")
        }
        return "Unknown"
    }

    // Test personal timetable API
    private func testTimetable() async {
        let endpoint = APIEndpoint.timetable
        print("\n🧪 Testing API: Personal Timetable")

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Safely parse the response to extract timetable events count
            let eventCount = extractTimetableEventsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Personal Timetable",
                    success: true,
                    message: "Successfully retrieved timetable with \(eventCount) events"
                ))
            print("🧪 ✅ Successfully retrieved personal timetable with \(eventCount) events")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Personal Timetable",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                ))
            print("🧪 ❌ Personal Timetable API failed: \(error.localizedDescription)")
        }
    }

    // New: Test timetable departments API
    private func testTimetableDepartments() async {
        let endpoint = APIEndpoint.timetableDepartments
        print("\n🧪 Testing API: Timetable Departments")

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let departmentCount = extractDepartmentsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Timetable Departments",
                    success: true,
                    message: "Successfully retrieved \(departmentCount) departments"
                )
            )
            print("🧪 ✅ Successfully retrieved departments list with \(departmentCount) departments")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Timetable Departments",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Timetable Departments API failed: \(error.localizedDescription)")
        }
    }

    // Extract departments count
    private func extractDepartmentsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let departments = json["departments"] as? [[String: Any]]
            {
                return departments.count
            }
        } catch {
            print("🧪 Error parsing departments data: \(error)")
        }
        return 0
    }

    // New: Test timetable modules API
    /*
    private func testTimetableModules() async {
        let endpoint = APIEndpoint.timetableModules(department: "COMP")
        print("\n🧪 Testing API: Timetable Modules")

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let moduleCount = extractModulesCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Timetable Modules",
                    success: true,
                    message: "Successfully retrieved \(moduleCount) modules"
                )
            )
            print("🧪 ✅ Successfully retrieved modules list with \(moduleCount) modules")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Timetable Modules",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Timetable Modules API failed: \(error.localizedDescription)")
        }
    }
    */

    // Extract modules count
    private func extractModulesCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let modules = json["modules"] as? [[String: Any]]
            {
                return modules.count
            }
        } catch {
            print("🧪 Error parsing modules data: \(error)")
        }
        return 0
    }

    // Safely extract timetable events count
    private func extractTimetableEventsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let timetableEvents = json["timetable"] as? [[String: Any]]
            {
                return timetableEvents.count
            } else if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                // Handle case where response is a direct array
                return json.count
            }
        } catch {
            print("🧪 Error parsing timetable data: \(error)")
        }
        return 0
    }

    // Test library study spaces API
    private func testStudySpaces() async {
        let endpoint = APIEndpoint.studySpaces
        print("\n🧪 Testing API: Study Spaces Overview")

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract study spaces count
            let (spaceCount, _) = extractStudySpacesInfo(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Study Spaces Overview",
                    success: true,
                    message: "Successfully retrieved \(spaceCount) study spaces"
                ))
            print("🧪 ✅ Successfully retrieved study spaces list with \(spaceCount) spaces")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Study Spaces Overview",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                ))
            print("🧪 ❌ Study Spaces Overview API failed: \(error.localizedDescription)")
        }
    }

    // Extract study spaces info
    private func extractStudySpacesInfo(from data: Data) -> (count: Int, firstId: Int?) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let surveys = json["surveys"] as? [[String: Any]]
            {
                let firstId = surveys.first.flatMap { $0["id"] as? Int }
                return (surveys.count, firstId)
            }
        } catch {
            print("🧪 Error parsing study spaces data: \(error)")
        }
        return (0, nil)
    }

    // Test rooms API
    private func testRooms() async {
        let endpoint = APIEndpoint.rooms
        print("\n🧪 Testing API: Rooms")

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract rooms count
            let roomCount = extractRoomsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Rooms",
                    success: true,
                    message: "Successfully retrieved \(roomCount) rooms"
                ))
            print("🧪 ✅ Successfully retrieved room data with \(roomCount) rooms")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Rooms",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                ))
            print("🧪 ❌ Rooms API failed: \(error.localizedDescription)")
        }
    }

    // New: Test free rooms API
    private func testFreeRooms() async {
        print("\n🧪 Testing API: Free Rooms")

        // Get current time and one hour from now for testing
        let dateFormatter = ISO8601DateFormatter()
        let now = Date()
        let oneHourLater = now.addingTimeInterval(3600)
        let startTime = dateFormatter.string(from: now)
        let endTime = dateFormatter.string(from: oneHourLater)

        let endpoint = APIEndpoint.freeRooms(startTime: startTime, endTime: endTime)

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract free rooms count
            let roomCount = extractFreeRoomsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Free Rooms",
                    success: true,
                    message: "Successfully retrieved \(roomCount) free rooms"
                )
            )
            print("🧪 ✅ Successfully retrieved free rooms data with \(roomCount) rooms")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Free Rooms",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Free Rooms API failed: \(error.localizedDescription)")
        }
    }

    // Extract free rooms count
    private func extractFreeRoomsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let rooms = json["free_rooms"] as? [[String: Any]]
            {
                return rooms.count
            }
        } catch {
            print("🧪 Error parsing free rooms data: \(error)")
        }
        return 0
    }

    // Test Room Equipment
    private func testRoomEquipment() async {
        print("\n🧪 Testing API: Room Equipment")

        // 使用默认的房间ID和siteid
        let roomId = "433"  // 示例房间ID

        do {
            // 添加siteid查询参数
            let queryItems = [URLQueryItem(name: "siteid", value: "085")]
            let endpoint = APIEndpoint.roomEquipment(roomId: roomId)
            let data = try await networkService.fetchRawData(
                endpoint: endpoint,
                additionalQueryItems: queryItems
            )

            // 提取设备数量
            let equipmentCount = extractEquipmentCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Room Equipment",
                    success: true,
                    message: "Successfully retrieved \(equipmentCount) equipment items"
                )
            )
            print("🧪 ✅ Successfully retrieved room equipment data with \(equipmentCount) items")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Room Equipment",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Room Equipment API failed: \(error.localizedDescription)")
        }
    }

    // Extract equipment count
    private func extractEquipmentCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let equipment = json["equipment"] as? [[String: Any]]
            {
                return equipment.count
            }
        } catch {
            print("🧪 Error parsing room equipment data: \(error)")
        }
        return 0
    }

    // Extract rooms count
    private func extractRoomsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let rooms = json["rooms"] as? [[String: Any]]
            {
                return rooms.count
            }
        } catch {
            print("🧪 Error parsing rooms data: \(error)")
        }
        return 0
    }

    // Test bookings API
    private func testBookings() async {
        let endpoint = APIEndpoint.bookings
        print("\n🧪 Testing API: Bookings")

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract bookings count and details
            let (bookingCount, _) = extractBookingsDetails(from: data)

            // 删除详细打印booking信息的部分，只打印统计数据
            // Print booking summary
            print("🧪 Retrieved \(bookingCount) bookings")

            testResults.append(
                APITestResult(
                    endpoint: "Bookings",
                    success: true,
                    message: "Successfully retrieved \(bookingCount) bookings"
                ))
            print("🧪 ✅ Successfully retrieved booking data with \(bookingCount) bookings")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Bookings",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                ))
            print("🧪 ❌ Bookings API failed: \(error.localizedDescription)")
        }
    }

    // Format booking JSON for better readability
    private func formatBookingJSON(_ booking: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: booking, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error formatting booking JSON: \(error)")
            return nil
        }
    }

    // Extract bookings count and details
    private func extractBookingsDetails(from data: Data) -> (count: Int, details: [[String: Any]]) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let bookings = json["bookings"] as? [[String: Any]]
            {
                return (bookings.count, bookings)
            }
        } catch {
            print("🧪 Error parsing bookings data: \(error)")
        }
        return (0, [])
    }

    // Test available slots API
    /*
    private func testAvailableSlots() async {
        // Use a default resource ID and today's date for testing
        let resourceId = "12345"  // Example resource ID, replace with valid ID in production
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        let endpoint = APIEndpoint.availableSlots(resourceId: resourceId, date: today)
        print("\n🧪 Testing API: Available Slots")

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract slots count
            let slotCount = extractSlotsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Available Slots",
                    success: true,
                    message: "Successfully retrieved \(slotCount) available slots"
                ))
            print("🧪 ✅ Successfully retrieved available slots data")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Available Slots",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                ))
            print("🧪 ❌ Available Slots API failed: \(error.localizedDescription)")
        }
    }
    */

    // Extract slots count
    private func extractSlotsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let slots = json["slots"] as? [[String: Any]]
            {
                return slots.count
            }
        } catch {
            print("🧪 Error parsing slots data: \(error)")
        }
        return 0
    }

    // New: Test search people API
    private func testSearchPeople() async {
        print("\n🧪 Testing API: Search People")

        // Use a generic search query
        let searchQuery = "smith"

        let endpoint = APIEndpoint.searchPeople(query: searchQuery)

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract people count from results
            let peopleCount = extractPeopleCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Search People",
                    success: true,
                    message: "Successfully found \(peopleCount) people matching '\(searchQuery)'"
                )
            )
            print("🧪 ✅ Successfully searched for people with \(peopleCount) results")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Search People",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Search People API failed: \(error.localizedDescription)")
        }
    }

    // Extract people count
    private func extractPeopleCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let people = json["people"] as? [[String: Any]]
            {
                return people.count
            }
        } catch {
            print("🧪 Error parsing search people data: \(error)")
        }
        return 0
    }

    // New: Test LibCal locations API
    private func testLibCalLocations() async {
        print("\n🧪 Testing API: LibCal Locations")

        let endpoint = APIEndpoint.libCalLocations

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract locations count
            let locationsCount = extractLibCalLocationsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "LibCal Locations",
                    success: true,
                    message: "Successfully retrieved \(locationsCount) LibCal locations"
                )
            )
            print("🧪 ✅ Successfully retrieved LibCal locations with \(locationsCount) locations")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "LibCal Locations",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ LibCal Locations API failed: \(error.localizedDescription)")
        }
    }

    // Extract LibCal locations count
    private func extractLibCalLocationsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let locations = json["locations"] as? [[String: Any]]
            {
                return locations.count
            }
        } catch {
            print("🧪 Error parsing LibCal locations data: \(error)")
        }
        return 0
    }

    // New: Test LibCal bookings API
    private func testLibCalBookings() async {
        print("\n🧪 Testing API: LibCal Bookings")

        let endpoint = APIEndpoint.libCalBookings

        do {
            // Get raw data and parse it manually
            let data = try await networkService.fetchRawData(endpoint: endpoint)

            // Extract bookings count
            let bookingsCount = extractLibCalBookingsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "LibCal Bookings",
                    success: true,
                    message: "Successfully retrieved \(bookingsCount) LibCal bookings"
                )
            )
            print("🧪 ✅ Successfully retrieved LibCal bookings with \(bookingsCount) bookings")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "LibCal Bookings",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ LibCal Bookings API failed: \(error.localizedDescription)")
        }
    }

    // Extract LibCal bookings count
    private func extractLibCalBookingsCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let bookings = json["bookings"] as? [[String: Any]]
            {
                return bookings.count
            }
        } catch {
            print("🧪 Error parsing LibCal bookings data: \(error)")
        }
        return 0
    }

    // Test Timetable By Module
    private func testTimetableByModule() async {
        print("\n🧪 Testing API: Timetable By Module")

        // 使用一些模块ID进行测试
        let modules = ["COMP0067", "COMP0068"]
        let endpoint = APIEndpoint.timetableByModule(modules: modules)

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let eventCount = extractTimetableEventsCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Timetable By Module",
                    success: true,
                    message:
                        "Successfully retrieved timetable with \(eventCount) events for modules \(modules.joined(separator: ", "))"
                )
            )
            print("🧪 ✅ Successfully retrieved timetable by module with \(eventCount) events")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Timetable By Module",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Timetable By Module API failed: \(error.localizedDescription)")
        }
    }

    // Test Timetable Courses
    /*
    private func testTimetableCourses() async {
        print("\n🧪 Testing API: Timetable Courses")

        // 使用计算机系代码
        let department = "COMP"
        let endpoint = APIEndpoint.timetableCourses(department: department)

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let courseCount = extractCoursesCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Timetable Courses",
                    success: true,
                    message:
                        "Successfully retrieved \(courseCount) courses for department \(department)"
                )
            )
            print("🧪 ✅ Successfully retrieved courses list with \(courseCount) courses")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Timetable Courses",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Timetable Courses API failed: \(error.localizedDescription)")
        }
    }
    */

    // Test Timetable Course Modules
    /*
    private func testTimetableCourseModules() async {
        print("\n🧪 Testing API: Timetable Course Modules")

        // 使用计算机科学硕士课程ID
        let courseId = "TMSCOMSCISG01"
        let endpoint = APIEndpoint.timetableCourseModules(courseId: courseId)

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let moduleCount = extractModulesCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Timetable Course Modules",
                    success: true,
                    message:
                        "Successfully retrieved \(moduleCount) modules for course \(courseId)"
                )
            )
            print("🧪 ✅ Successfully retrieved course modules with \(moduleCount) modules")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Timetable Course Modules",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Timetable Course Modules API failed: \(error.localizedDescription)")
        }
    }
    */

    // Test Workspaces Sensors Summary
    private func testWorkspacesSensorsSummary() async {
        print("\n🧪 Testing API: Workspaces Sensors Summary")

        let endpoint = APIEndpoint.workspacesSensorsSummary

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let summaryCounts = extractSensorsSummary(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Sensors Summary",
                    success: true,
                    message: "Successfully retrieved sensors summary with \(summaryCounts) regions"
                )
            )
            print(
                "🧪 ✅ Successfully retrieved workspaces sensors summary with \(summaryCounts) regions"
            )
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Sensors Summary",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Workspaces Sensors Summary API failed: \(error.localizedDescription)")
        }
    }

    // Extract sensors summary count
    private func extractSensorsSummary(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let surveys = json["surveys"] as? [[String: Any]]
            {
                return surveys.count
            }
        } catch {
            print("🧪 Error parsing sensors summary data: \(error)")
        }
        return 0
    }

    // Test Workspaces Historical Surveys
    /*
    private func testWorkspacesHistoricalSurveys() async {
        print("\n🧪 Testing API: Workspaces Historical Surveys")

        let endpoint = APIEndpoint.workspacesHistoricalSurveys

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let surveysCount = extractHistoricalSurveysCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Historical Surveys",
                    success: true,
                    message: "Successfully retrieved \(surveysCount) historical surveys"
                )
            )
            print("🧪 ✅ Successfully retrieved historical surveys with \(surveysCount) surveys")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Historical Surveys",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Workspaces Historical Surveys API failed: \(error.localizedDescription)")
        }
    }
    */

    // Test workspaces historical sensors
    /*
    private func testWorkspacesHistoricalSensors() async {
        print("\n🧪 Testing API: Workspaces Historical Sensors")

        // 使用Science Library ID
        let surveyId = 22
        let endpoint = APIEndpoint.workspacesHistoricalSensors(surveyId: surveyId)

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let (count, _) = extractHistoricalSensorsInfo(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Historical Sensors",
                    success: true,
                    message:
                        "Successfully retrieved \(count) historical sensor records for survey \(surveyId)"
                )
            )
            print("🧪 ✅ Successfully retrieved historical sensors with \(count) records")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Historical Sensors",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Workspaces Historical Sensors API failed: \(error.localizedDescription)")
        }
    }
    */

    // Test workspaces historical data
    /*
    private func testWorkspacesHistoricalData() async {
        print("\n🧪 Testing API: Workspaces Historical Data")

        let surveyId = 22
        let days = 30
        let endpoint = APIEndpoint.workspacesHistoricalData(surveyId: surveyId, days: days)

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let count = extractHistoricalDataCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Historical Data",
                    success: true,
                    message:
                        "Successfully retrieved \(count) historical data points for survey \(surveyId) over \(days) days"
                )
            )
            print("🧪 ✅ Successfully retrieved historical data with \(count) data points")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Historical Data",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Workspaces Historical Data API failed: \(error.localizedDescription)")
        }
    }
    */

    // Test workspaces sensors last updated
    /*
    private func testWorkspacesSensorsLastUpdated() async {
        // ... 已注释的代码 ...
    }
    */

    // Test Workspaces Sensor Averages
    private func testWorkspacesSensorAverages() async {
        print("\n🧪 Testing API: Workspaces Sensor Averages")

        // 使用days参数(1, 7, 30)
        do {
            // 添加days查询参数
            let queryItems = [URLQueryItem(name: "days", value: "7")]
            let data = try await networkService.fetchRawData(
                endpoint: .workspacesSensorAverages,
                additionalQueryItems: queryItems
            )

            let averagesCount = extractSensorAveragesCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Sensor Averages",
                    success: true,
                    message: "Successfully retrieved \(averagesCount) sensor averages"
                )
            )
            print("🧪 ✅ Successfully retrieved sensor averages with \(averagesCount) entries")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "Workspaces Sensor Averages",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ Workspaces Sensor Averages API failed: \(error.localizedDescription)")
        }
    }

    // Extract sensor averages count
    private func extractSensorAveragesCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let averages = json["averages"] as? [String: Any]
            {
                return averages.count
            }
        } catch {
            print("🧪 Error parsing sensor averages data: \(error)")
        }
        return 0
    }

    // Test workspaces image
    /*
    private func testWorkspacesImage() async {
        // ... 已注释的代码 ...
    }
    */

    // Test LibCal Categories (All)
    private func testLibCalCategoriesAll() async {
        print("\n🧪 Testing API: LibCal Categories (All)")

        do {
            // 添加ids查询参数
            let queryItems = [URLQueryItem(name: "ids", value: "872,2725")]
            let data = try await networkService.fetchRawData(
                endpoint: .libCalCategories,
                additionalQueryItems: queryItems
            )

            let categoriesCount = extractLibCalCategoriesCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "LibCal Categories (All)",
                    success: true,
                    message: "Successfully retrieved \(categoriesCount) LibCal categories"
                )
            )
            print("🧪 ✅ Successfully retrieved LibCal categories with \(categoriesCount) categories")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "LibCal Categories (All)",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ LibCal Categories (All) API failed: \(error.localizedDescription)")
        }
    }

    // Extract LibCal categories count
    private func extractLibCalCategoriesCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let categories = json["categories"] as? [[String: Any]]
            {
                return categories.count
            }
        } catch {
            print("🧪 Error parsing LibCal categories data: \(error)")
        }
        return 0
    }

    // Test LibCal Nickname
    private func testLibCalNickname() async {
        print("\n🧪 Testing API: LibCal Nickname")

        do {
            // 添加ids查询参数
            let queryItems = [URLQueryItem(name: "ids", value: "3334,3335")]
            let data = try await networkService.fetchRawData(
                endpoint: .libCalNickname,
                additionalQueryItems: queryItems
            )

            let nicknamesCount = extractLibCalNicknamesCount(from: data)

            testResults.append(
                APITestResult(
                    endpoint: "LibCal Nickname",
                    success: true,
                    message: "Successfully retrieved \(nicknamesCount) nicknames"
                )
            )
            print("🧪 ✅ Successfully retrieved nicknames with \(nicknamesCount) entries")
        } catch {
            testResults.append(
                APITestResult(
                    endpoint: "LibCal Nickname",
                    success: false,
                    message: "Error: \(error.localizedDescription)"
                )
            )
            print("🧪 ❌ LibCal Nickname API failed: \(error.localizedDescription)")
        }
    }

    // Extract LibCal nicknames count
    private func extractLibCalNicknamesCount(from data: Data) -> Int {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let nicknames = json["nicknames"] as? [[String: Any]]
            {
                return nicknames.count
            }
        } catch {
            print("🧪 Error parsing LibCal nicknames data: \(error)")
        }
        return 0
    }

    // 测试哲学模块PHIL0041
    func testPhilosophyModule() async {
        print("\n🧪 Testing Philosophy module PHIL0041")

        guard authManager.accessToken != nil else {
            print("❌ Authentication required")
            return
        }

        // 使用bymodule端点
        let endpoint = APIEndpoint.timetableByModule(modules: ["PHIL0041"])

        do {
            let data = try await networkService.fetchRawData(endpoint: endpoint)
            let eventCount = extractTimetableEventsCount(from: data)

            print("✅ Successfully retrieved timetable for PHIL0041 with \(eventCount) events")

            // 解析和处理数据
            if eventCount > 0 {
                print("Events found for PHIL0041:")
                if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 尝试提取事件详情
                    extractAndPrintPhilosophyEvents(from: jsonObj)
                }
            } else {
                print("No events found for PHIL0041")
            }
        } catch {
            print("❌ Failed to retrieve PHIL0041 timetable: \(error)")
        }
    }

    // 提取并打印哲学模块事件
    private func extractAndPrintPhilosophyEvents(from json: [String: Any]) {
        if let timetable = json["timetable"] as? [[String: Any]] {
            for (index, event) in timetable.enumerated() {
                print("Event \(index + 1):")
                if let moduleId = event["module_id"] as? String {
                    print("  Module ID: \(moduleId)")
                }
                if let moduleName = event["module_name"] as? String {
                    print("  Module Name: \(moduleName)")
                }
                if let startTime = event["start_time"] as? String,
                    let endTime = event["end_time"] as? String
                {
                    print("  Time: \(startTime) - \(endTime)")
                }
                if let location = event["location"] as? [String: Any],
                    let roomName = location["name"] as? String
                {
                    print("  Location: \(roomName)")
                }
                print("  ---")
            }
        }
    }

    // 调试工具: 打印详细API请求信息
    func debugApiRequest(endpoint: String, parameters: [String: String]) {
        print("\n=== DEBUG API REQUEST ===")
        print("Endpoint: \(endpoint)")
        print("Parameters:")
        for (key, value) in parameters {
            print("- \(key): \(value)")
        }
        print("========================\n")
    }

    // 调试工具: 分析API响应
    func analyzeApiResponse(data: Data, endpoint: String) {
        print("\n=== ANALYZING API RESPONSE ===")
        print("Endpoint: \(endpoint)")

        // 尝试打印响应大小
        print("Response size: \(data.count) bytes")

        // 尝试解析为JSON
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Response structure: Dictionary with \(json.count) keys")
                print("Keys: \(Array(json.keys).joined(separator: ", "))")

                // 检查是否有错误信息
                if let error = json["error"] as? String {
                    print("⚠️ Error message: \(error)")
                }

                // 检查成功状态
                if let ok = json["ok"] as? Bool {
                    print("Status: \(ok ? "Success" : "Failed")")
                }
            } else if let jsonArray = try JSONSerialization.jsonObject(with: data)
                as? [[String: Any]]
            {
                print("Response structure: Array with \(jsonArray.count) items")
                if let firstItem = jsonArray.first, !firstItem.isEmpty {
                    print("First item keys: \(Array(firstItem.keys).joined(separator: ", "))")
                }
            } else {
                print("Response is not a dictionary or array")
            }
        } catch {
            print("Failed to parse JSON: \(error)")

            // 尝试作为文本输出
            if let text = String(data: data, encoding: .utf8) {
                let preview = text.prefix(200) + (text.count > 200 ? "..." : "")
                print("Response as text (preview): \(preview)")

                // 检查是否是HTML
                if text.contains("<!DOCTYPE") || text.contains("<html") {
                    print("⚠️ Response appears to be HTML, not JSON!")
                }
            } else {
                print("Unable to convert response to text")
            }
        }

        print("========================\n")
    }

    // 高级错误分析
    func analyzeAPIError(error: Error, endpoint: String, data: Data? = nil) {
        print("\n=== API ERROR ANALYSIS ===")
        print("Endpoint: \(endpoint)")
        print("Error: \(error.localizedDescription)")

        // 根据错误类型提供更详细的分析
        let networkError = error as NSError
        if networkError.domain == "NetworkService" {
            print("Error code: \(networkError.code)")

            // 分类处理常见错误
            switch networkError.code {
            case -1:
                print("⚠️ Authentication error: 需要有效的访问令牌")
                print("建议: 尝试重新登录获取新的访问令牌")

            case 400:
                print("⚠️ Bad request: 请求参数可能不正确")
                print("建议: 检查请求参数格式和值")

            case 401:
                print("⚠️ Unauthorized: 访问令牌可能已过期或无效")
                print("建议: 重新获取访问令牌")

            case 403:
                print("⚠️ Forbidden: 没有权限访问此资源")
                print("建议: 确认用户权限或API权限设置")

            case 404:
                print("⚠️ Not found: 请求的资源不存在")
                print("建议: 检查资源ID或端点URL")

            case 429:
                print("⚠️ Too many requests: 超出API请求速率限制")
                print("建议: 降低请求频率或实现请求节流")

            case 500:
                print("⚠️ Server error: UCL API服务器内部错误")
                print("建议: 稍后重试或联系API提供者")

            default:
                print("⚠️ 未分类错误: 代码 \(networkError.code)")
            }
        }

        // 分析响应数据（如果有）
        if let responseData = data, !responseData.isEmpty {
            print("\n分析响应数据:")
            analyzeApiResponse(data: responseData, endpoint: endpoint)
        }

        print("=========================\n")
    }

    // 公共方法：专门测试PHIL0041模块，可从UI直接调用
    func testPHIL0041Module() async {
        print("\n🧪🧪🧪 TESTING PHIL0041 MODULE 🧪🧪🧪")

        // 检查访问令牌
        guard let token = authManager.accessToken else {
            print("🧪❌ 测试失败: 未找到有效的访问令牌")
            return
        }

        print("🧪✓ 使用访问令牌: \(token.prefix(10))...")

        // 运行测试
        await testPhilosophyModule()

        print("\n🧪🧪🧪 PHIL0041 MODULE TEST COMPLETED 🧪🧪🧪")
    }
}

// API test result model
struct APITestResult: Identifiable {
    let id = UUID()
    let endpoint: String
    let success: Bool
    let message: String
    let timestamp = Date()
}

// Notification extension
extension Notification.Name {
    static let apiTestsCompleted = Notification.Name("apiTestsCompleted")
}

enum Days: Int, CaseIterable {
    case daily = 1
    case weekly = 7
    case monthly = 30
}
