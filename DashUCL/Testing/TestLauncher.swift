import Foundation

enum TestLauncher {
    static func configure() {
        #if DEBUG
            // Automatically enable or disable test mode in debug environment
            if ProcessInfo.processInfo.arguments.contains("--enableTestMode") {
                TestEnvironment.shared.isTestMode = true
                // Initialize test data
                TestDataManager.shared.initializeTestData()
            }

            if ProcessInfo.processInfo.arguments.contains("--disableTestMode") {
                TestEnvironment.shared.isTestMode = false
            }
        #endif
    }
}
