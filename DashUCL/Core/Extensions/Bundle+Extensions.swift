import Foundation

extension Bundle {
    /// Returns the full version number of the app (e.g., 1.2.3)
    var appVersionLong: String {
        let version =
            object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        return version
    }

    /// Returns the build number of the app (e.g., 123)
    var buildVersion: String {
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return build
    }

    /// Returns the combination of version and build number (e.g., 1.2.3 (123))
    var versionAndBuild: String {
        return "\(appVersionLong) (\(buildVersion))"
    }

    /// Returns the app name
    var appName: String {
        let name = object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown"
        return name
    }
}
