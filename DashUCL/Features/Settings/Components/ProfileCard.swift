import SwiftUI

// User type enum
enum UserType: String {
    case undergraduate = "ucl-ug"
    case postgraduate = "ucl-pg"
    case staff = "ucl-staff"

    var displayName: String {
        switch self {
        case .undergraduate:
            return "Undergraduate"
        case .postgraduate:
            return "Postgraduate"
        case .staff:
            return "Staff"
        }
    }
}

struct ProfileCard: View {
    @StateObject private var userModel = UserModel.shared
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject private var testEnvironment = TestEnvironment.shared

    // Cache state
    @State private var cachedModuleCount: Int = 0
    @State private var cachedEventCount: Int = 0
    @State private var cachedBookingCount: Int = 0
    @State private var cachedUserData: (fullName: String, department: String, email: String)?
    @State private var cachedUserType: UserType?
    @State private var lastStatsUpdateTime: Date = .distantPast
    @State private var lastProfileUpdateTime: Date = .distantPast
    @State private var isLoading: Bool = true
    @State private var retryCount: Int = 0
    private let maxRetries = 3
    private let statsValidityDuration: TimeInterval = 300  // 5 minutes stats cache
    private let profileValidityDuration: TimeInterval = 43200  // 12 hours profile cache

    // Parse user type from userGroups
    private var userType: UserType? {
        if let cached = cachedUserType, !shouldRefreshProfileCache() {
            return cached
        }

        let groups =
            testEnvironment.isTestMode
            ? testEnvironment.mockUserProfile.uclGroups : userModel.uclGroups
        let type: UserType?
        if groups.contains("ucl-ug") {
            type = .undergraduate
        } else if groups.contains("ucl-pg") {
            type = .postgraduate
        } else if groups.contains("ucl-staff") {
            type = .staff
        } else {
            type = nil
        }
        cachedUserType = type
        return type
    }

    private var userData: (fullName: String, department: String, email: String) {
        if let cached = cachedUserData, !shouldRefreshProfileCache() {
            return cached
        }

        let data: (fullName: String, department: String, email: String)
        if testEnvironment.isTestMode {
            let profile = testEnvironment.mockUserProfile
            data = (profile.fullName, profile.department, profile.email)
        } else {
            data = (userModel.fullName, userModel.department, userModel.email)
        }
        cachedUserData = data
        return data
    }

    var body: some View {
        BentoCard {
            if isLoading && !testEnvironment.isTestMode {
                // Show loading state
                VStack(spacing: 8) {
                    ProgressView("Loading user data...")
                    if retryCount > 0 {
                        Text("Retrying... (\(retryCount)/\(maxRetries))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else if userData.fullName.isEmpty && !testEnvironment.isTestMode {
                // Show error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text("Failed to load user data")
                        .font(.headline)
                    Text("Please try again later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        retryLoadingData()
                    }
                    .buttonStyle(.bordered)
                    .disabled(retryCount >= maxRetries)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        // Name and Type
                        HStack {
                            Text(userData.fullName)
                                .font(.title2)
                                .bold()
                            Spacer()
                            if let type = userType {
                                Text(type.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }

                        // Department
                        Text(userData.department)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Stats Section
                    HStack {
                        StatItem(
                            title: "Modules",
                            value: "\(cachedModuleCount)",
                            color: .blue
                        )

                        Divider()
                            .frame(height: 40)

                        StatItem(
                            title: "Events",
                            value: "\(cachedEventCount)",
                            color: .orange
                        )

                        Divider()
                            .frame(height: 40)

                        StatItem(
                            title: "Bookings",
                            value: "\(cachedBookingCount)",
                            color: .green
                        )
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            if testEnvironment.isTestMode {
                isLoading = false
                updateStats()
            } else if shouldRefreshProfileCache() {
                retryLoadingData()
            } else if shouldRefreshStatsCache() {
                updateStats()
                lastStatsUpdateTime = Date()
            } else {
                isLoading = false
            }
        }
        .onChange(of: testEnvironment.isTestMode) { oldValue, newValue in
            if newValue {
                isLoading = false
                updateStats()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDataDidUpdate)) { _ in
            if !testEnvironment.isTestMode {
                if shouldRefreshProfileCache() {
                    retryLoadingData()
                } else if shouldRefreshStatsCache() {
                    updateStats()
                    lastStatsUpdateTime = Date()
                }
            }
        }
    }

    private func shouldRefreshProfileCache() -> Bool {
        // Check if profile cache is expired (12 hours)
        let now = Date()
        return now.timeIntervalSince(lastProfileUpdateTime) > profileValidityDuration
    }

    private func shouldRefreshStatsCache() -> Bool {
        // Check if stats cache is expired (5 minutes)
        let now = Date()
        return now.timeIntervalSince(lastStatsUpdateTime) > statsValidityDuration
    }

    private func retryLoadingData() {
        guard !testEnvironment.isTestMode else {
            isLoading = false
            return
        }

        guard retryCount < maxRetries else {
            isLoading = false
            return
        }

        isLoading = true
        retryCount += 1

        Task {
            do {
                // Use exponential backoff strategy to calculate delay time
                if retryCount > 1 {
                    let delay = Double(pow(2.0, Double(retryCount - 1)))  // 1s, 2s, 4s
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }

                try await userModel.syncUserData()
                await MainActor.run {
                    isLoading = false
                    retryCount = 0
                    updateStats()
                    lastStatsUpdateTime = Date()
                    lastProfileUpdateTime = Date()
                    // Force update cached profile information
                    cachedUserData = nil
                    cachedUserType = nil
                    _ = userData  // Trigger recalculation
                    _ = userType  // Trigger recalculation
                }
            } catch {
                print("Retry \(retryCount) failed with error: \(error.localizedDescription)")

                if retryCount < maxRetries {
                    await MainActor.run {
                        retryLoadingData()
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            }
        }
    }

    private func updateStats() {
        Task {
            await MainActor.run {
                cachedModuleCount = 6
                cachedEventCount = 12
                cachedBookingCount = 3
            }
        }
    }
}

// Stat item component
private struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileCard()
        .padding()
}
