/*
 * Observer service that monitors and responds to authentication state changes.
 * Manages data loading and cleanup operations when users log in or out.
 * Uses notification center to maintain consistent state across the application.
 * Ensures appropriate data availability based on current authentication context.
 */

import Foundation
import SwiftUI

/// Authentication state observer, responsible for monitoring user login status and automatically loading data
@MainActor
class AuthStateObserver: ObservableObject {
    static let shared = AuthStateObserver()

    // Data manager
    private let dataManager = UCLDataManager.shared
    // Authentication manager
    private let authManager = AuthManager.shared

    // Notification observers
    private var loginObserver: NSObjectProtocol?
    private var logoutObserver: NSObjectProtocol?

    @Published private(set) var isInitialDataLoaded = false

    private init() {
        setupObservers()
    }

    deinit {
        // Asynchronously remove observers on main thread
        Task { @MainActor [weak self] in
            self?.removeObservers()
        }
    }

    private func setupObservers() {
        // Listen for user login success
        loginObserver = NotificationCenter.default.addObserver(
            forName: .userDidSignIn,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Use Task wrapper to safely access MainActor isolated methods
            Task { @MainActor [weak self] in
                self?.handleUserLogin()
            }
        }

        // Listen for user logout
        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidSignOut,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Use Task wrapper to safely access MainActor isolated methods
            Task { @MainActor [weak self] in
                self?.handleUserLogout()
            }
        }

        // If user is already logged in, load data immediately
        if authManager.isAuthenticated {
            // Use Task wrapper to safely access MainActor isolated methods
            Task { @MainActor in
                self.handleUserLogin()
            }
        }
    }

    private func removeObservers() {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleUserLogin() {
        print("User logged in, loading initial data...")

        // Start auto refresh
        Task {
            // Refresh all data
            await dataManager.refreshAll()

            // Load static data (data that only needs to be fetched once)
            await loadStaticData()

            // Start auto refresh
            await dataManager.startAutoRefresh()

            isInitialDataLoaded = true
            print("Initial data loaded successfully")
        }
    }

    /// Load static data - These data only need to be fetched once and cached
    private func loadStaticData() async {
        print("Getting static data and caching...")

        // Create network service instance
        let networkService = NetworkService()
        // Static data manager
        let staticDataManager = StaticDataManager.shared

        // Set task group, get multiple static data in parallel
        await withTaskGroup(of: Void.self) { group in
            // 1. Room information - If UCLDataManager's fetchRooms has already cached room data, this step can be omitted
            // But to ensure getting, we still call it separately
            group.addTask {
                do {
                    print("Getting room data...")
                    let roomsData = try await networkService.fetchRawData(endpoint: .rooms)

                    // Pass to StaticDataManager for processing and caching
                    await staticDataManager.processRoomsData(roomsData)
                } catch {
                    print("❌ Failed to get room data: \(error.localizedDescription)")
                }
            }

            // 2. Department information
            group.addTask {
                do {
                    print("Getting department data...")
                    let deptsData = try await networkService.fetchRawData(
                        endpoint: .timetableDepartments)

                    // Pass to StaticDataManager for processing and caching
                    await staticDataManager.processDepartmentsData(deptsData)
                } catch {
                    print("❌ Failed to get department data: \(error.localizedDescription)")
                }
            }

            // 3. LibCal location information
            group.addTask {
                do {
                    print("Getting LibCal location data...")
                    let locationsData = try await networkService.fetchRawData(
                        endpoint: .libCalLocations)

                    // Pass to StaticDataManager for processing and caching
                    await staticDataManager.processLibCalLocationsData(locationsData)
                } catch {
                    print("❌ Failed to get LibCal location data: \(error.localizedDescription)")
                }
            }
        }

        print("Static data get and cache completed")

        // Send notification to indicate static data has been loaded
        NotificationCenter.default.post(name: .staticDataLoaded, object: nil)
    }

    private func handleUserLogout() {
        print("User logged out, stopping data refresh...")

        // Stop auto refresh
        dataManager.stopAutoRefresh()

        // Clear cache (optional)
        Task {
            await dataManager.clearCache()
            isInitialDataLoaded = false
            print("Data cache cleared")
        }
    }
}
