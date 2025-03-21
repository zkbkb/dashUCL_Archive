/*
 * UIKit application delegate that handles system-level interactions and lifecycle events.
 * Manages push notifications setup, permissions, and user interactions with notification actions.
 * Configures background tasks for widget data updates and application appearance settings.
 * Implements UNUserNotificationCenterDelegate for handling notifications in different app states.
 */

import BackgroundTasks
import SwiftUI
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Notification manager instance
    private let notificationManager = NotificationManager.shared

    // Test environment instance
    private let testEnvironment = TestEnvironment.shared

    // Called when application launches
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure navigation bar appearance
        #if canImport(NavigationBarAppearance)
            NavigationBarAppearance.configure()
        #else
            // If unable to import, set navigation bar style directly here
            let standardAppearance = UINavigationBarAppearance()
            standardAppearance.configureWithDefaultBackground()
            standardAppearance.backgroundColor = .systemBackground
            standardAppearance.shadowColor = .clear  // Remove bottom shadow

            let scrollEdgeAppearance = UINavigationBarAppearance()
            scrollEdgeAppearance.configureWithTransparentBackground()

            UINavigationBar.appearance().standardAppearance = standardAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
            UINavigationBar.appearance().compactAppearance = standardAppearance
        #endif

        // TabBar appearance is configured uniformly by NavigationBarAppearance
        // Not set here to avoid configuration conflicts

        // Set up push notifications
        setupPushNotifications()

        // Register background tasks (for widget data updates)
        registerBackgroundTasks()

        // Initialize notification manager, ensure it's created and configured at app launch
        _ = notificationManager

        // Ensure test environment is correctly initialized
        if TestConfig.isTestMode {
            print(
                "Application launched: Detected test mode enabled, ensure test data initialization")
            // TestEnvironment's initialization logic will handle necessary setup
            _ = testEnvironment
        }

        return true
    }

    // Called when application will enter foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("Application will enter foreground")

        // Check test mode status
        if TestConfig.isTestMode {
            print(
                "Application will enter foreground: Detected test mode enabled, ensure test data initialized"
            )
            // Ensure TestEnvironment is accessed, trigger its notification listener
            _ = testEnvironment
        }
    }

    // Called when application becomes active from background
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("Application becomes active state")

        // Here you can add other operations that need to be performed when the application becomes active
    }

    // Called when application will enter background
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application entered background")

        // Here you can add operations that need to be performed when the application enters background
    }

    // MARK: - Push notifications processing

    // Set up push notifications
    private func setupPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self  // Set delegate to receive foreground notifications

        // Define notification categories (for course reminders)
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )

        let viewAction = UNNotificationAction(
            identifier: "VIEW_CLASS_ACTION",
            title: "View Class Details",
            options: [.foreground]
        )

        // Create course reminder category
        let classReminderCategory = UNNotificationCategory(
            identifier: "CLASS_REMINDER",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Register notification categories
        center.setNotificationCategories([classReminderCategory])

        // Request notification permissions
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            } else {
                print("User declined notification permissions")
            }
        }
    }

    // Successfully registered remote notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert device token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device token: \(token)")

        // Send token to your server so you can send push notifications later
        sendDeviceTokenToServer(token)
    }

    // Remote notification registration failed
    func application(
        _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Remote notification registration failed: \(error.localizedDescription)")
    }

    // Received notification when application is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        // Allow notification to be displayed in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // User responded to notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Get notification data
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        // Handle different actions
        switch actionIdentifier {
        case "VIEW_CLASS_ACTION":
            // Open course detail page
            if let classId = userInfo["classId"] as? String {
                openClassDetails(classId: classId)
            }
        case UNNotificationDefaultActionIdentifier:
            // User clicked on the notification itself
            if let classId = userInfo["classId"] as? String {
                openClassDetails(classId: classId)
            }
        default:
            break
        }

        completionHandler()
    }

    // MARK: - Widget-related background tasks

    private func registerBackgroundTasks() {
        // Register background task for updating widget data
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.Kaibin-Zhang.Dash-UCL.widgetrefresh",
            using: nil
        ) { task in
            self.handleWidgetRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func handleWidgetRefresh(task: BGAppRefreshTask) {
        // Create a task to update widget data in the background
        let updateTask = Task {
            do {
                // Update widget data
                try await updateWidgetData()

                // Complete task
                task.setTaskCompleted(success: true)
            } catch {
                print("Failed to update widget data: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }

        // If task is cancelled, cancel update operation
        task.expirationHandler = {
            updateTask.cancel()
            task.setTaskCompleted(success: false)
        }

        // Schedule next update
        scheduleNextWidgetUpdate()
    }

    private func scheduleNextWidgetUpdate() {
        let request = BGAppRefreshTaskRequest(identifier: "com.Kaibin-Zhang.Dash-UCL.widgetrefresh")
        // Set to update after at least 1 hour
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Unable to schedule widget update task: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper methods

    private func sendDeviceTokenToServer(_ token: String) {
        // Implement logic to send device token to your server
    }

    private func openClassDetails(classId: String) {
        // Implement logic to open course detail page
        NotificationCenter.default.post(
            name: Notification.Name("OpenClassDetails"),
            object: nil,
            userInfo: ["classId": classId]
        )
    }

    private func updateWidgetData() async throws {
        // Implement logic to update widget data
    }
}
