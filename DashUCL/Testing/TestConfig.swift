import Foundation

enum TestConfig {
    static var isTestMode: Bool {
        get { UserDefaults.standard.bool(forKey: "testMode") }
        set { UserDefaults.standard.set(newValue, forKey: "testMode") }
    }

    // Using a placeholder token since we don't call network APIs in test mode
    static let mockToken = "test-mode-token"

    static func getMockToken() -> String {
        return mockToken
    }

    static let mockUserProfile = UserProfile(
        ok: true,
        cn: "dajdhg",
        department: "Computer Science",
        email: "jeremy.bentham.25@ucl.ac.uk",
        fullName: "Jeremy Bentham",
        givenName: "Jeremy",
        upi: "abcdef",
        scopeNumber: 30,
        isStudent: true,
        uclGroups: [
            "ucl-pg"

        ],
        sn: "Bentham",
        mail: "jeremy.bentham.25@ucl.ac.uk",
        userTypes: ["U/G"]
    )
}
