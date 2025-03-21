/*
 * Extension to NetworkService that provides specialized handling for test environments.
 * Implements mock data generation for various API endpoints during testing.
 * Simulates network responses without requiring actual server connections.
 * Enables consistent testing of UI components with predictable data.
 */

import Foundation
import UIKit

// Extend NetworkService to better handle TestEnvironment
extension NetworkService {
    // Add a method to check test mode outside the original fetchJSON method
    func handleTestModeForSearchRequest(_ endpoint: APIEndpoint) -> [String: Any]? {
        // Only handle in test mode
        guard TestEnvironment.shared.isTestMode else { return nil }

        // Handle different test data based on endpoint type
        switch endpoint {
        case .searchPeople(let query):
            print("🧪 Using test data for people search: \(query)")
            // Create mock response for SearchPeople
            let searchResults = TestStaffData.searchStaff(query: query)

            // Convert TestStaffData.StaffMember to a format that can be displayed in UI
            let peopleArray: [[String: Any]] = searchResults.map { staff in
                return [
                    "id": staff.id,
                    "name": staff.name,
                    "email": staff.email,
                    "department": staff.department,
                    "position": staff.position,
                    "phone": staff.phoneNumber,
                ]
            }

            // Create JSON object matching API response format
            return [
                "ok": true,
                "people": peopleArray,
            ]
        default:
            // Don't handle other endpoints
            return nil
        }
    }
}

// Add a method to check test mode outside the original fetchJSON method
extension NetworkService {
    // Static method is called at application startup
    // Use notification center to monitor changes in test mode
    static let setupTestModePatch: Void = {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 使用通知中心来监听测试模式的变化
            NotificationCenter.default.addObserver(
                forName: .init("TestModeDidChange"), object: nil, queue: .main
            ) { _ in
                if TestEnvironment.shared.isTestMode {
                    print(
                        "🧪 Test mode enabled - Network service will use TestStaffData for staff search"
                    )
                }
            }

            // 立即检查当前状态
            if TestEnvironment.shared.isTestMode {
                print(
                    "🧪 Test mode enabled - Network service will use TestStaffData for staff search")
            }
        }
    }()
}

// Add a method to check test mode outside the original fetchJSON method
// To ensure static variables are initialized
// Rename initialize method to avoid conflict with Objective-C runtime
@objc class NetworkServiceInitializer: NSObject {
    // 重命名initialize方法，避免与Objective-C运行时冲突
    @objc static func setupServices() {
        _ = NetworkService.setupTestModePatch
    }
}

// Add a method to check test mode outside the original fetchJSON method
// 在应用启动时执行初始化
extension UIApplication {
    private static let runOnce: Void = {
        NetworkServiceInitializer.setupServices()  // 使用新的方法名
    }()

    // 添加override关键字
    override open var next: UIResponder? {
        // 这会在应用启动时触发
        UIApplication.runOnce
        return super.next
    }
}
