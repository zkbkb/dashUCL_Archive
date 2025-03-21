/*
 * Main entry point for the DashUCL app, responsible for application initialization and lifecycle.
 * Implements a custom splash screen with smooth transition from the system launch screen.
 * Configures global services, theme management, and authentication state observation.
 * Uses SwiftUI's App protocol with UIKit integration via UIApplicationDelegateAdaptor.
 */

//
//  DashUCLApp.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 16/02/2025.
//

import SwiftUI
import UIKit

// Add a global variable to ensure splash screen shows immediately
var hasAppLaunched = false

// Preload default splash screen image before app loads
@_cdecl("UIApplicationPreloadLaunchImages")
func preloadLaunchImages() {
    // Preload splash image for iPhone 16 Pro size
    let _ = UIImage(named: "Launch-6.3")
    // Cache default size to UserDefaults
    if UserDefaults.standard.string(forKey: "com.dashucl.launchscreen.size") == nil {
        UserDefaults.standard.set("Launch-6.3", forKey: "com.dashucl.launchscreen.size")
    }
}

@main
struct DashUCLApp: App {
    // Add AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var themeManager = ThemeManager.shared

    // Add authentication state observer
    @StateObject private var authObserver = AuthStateObserver.shared

    // Ensure API test service is initialized
    private let apiTestService = APITestService.shared

    // Splash screen state flag
    @State private var isShowingLaunchScreen = true

    init() {
        // Immediately mark app as launched to avoid showing splash screen again
        hasAppLaunched = true

        // Ensure splash image is loaded
        let _ = UIImage(named: "Launch-6.3")

        #if DEBUG
            TestLauncher.configure()
        #endif

        // Silent preload all necessary services
        let _ = self.apiTestService
        let _ = ThemeManager.shared
        let _ = AuthManager.shared

        // Set UI appearance to ensure no flicker during startup
        UIView.setAnimationsEnabled(false)
    }

    var body: some Scene {
        WindowGroup {
            // Use ZStack to ensure content stacking is correct
            ZStack {
                // Main content view
                ContentView()
                    .preferredColorScheme(themeManager.colorScheme)
                    .environmentObject(authObserver)
                    .environmentObject(NavigationManager.shared)
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: Notification.Name("OpenClassDetails"))
                    ) { notification in
                        if let classId = notification.userInfo?["classId"] as? String {
                            NavigationManager.shared.navigateToClassDetails(classId: classId)
                        }
                    }
                    // Hide main content view until splash screen disappears
                    .opacity(isShowingLaunchScreen ? 0 : 1)
                    .accessibilityHidden(isShowingLaunchScreen)

                // Show splash screen, ensure it immediately covers system default launch screen
                if isShowingLaunchScreen {
                    LaunchScreen()
                        .ignoresSafeArea()
                        .zIndex(999)  // Use highest z-index to ensure it's on top
                        .transition(.opacity)
                        .onAppear {
                            // Re-enable animations after initialization
                            UIView.setAnimationsEnabled(true)

                            // Hide splash screen after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    isShowingLaunchScreen = false
                                }
                            }
                        }
                }
            }
            // Ensure no animation transitions during launch
            .animation(nil, value: isShowingLaunchScreen)
            // Use onAppear to ensure operations after main content view loads
            .task {
                // Ensure device screen size is detected and cached
                if UserDefaults.standard.string(forKey: "com.dashucl.launchscreen.size") == nil {
                    // If no cache, use default value
                    UserDefaults.standard.set("Launch-6.3", forKey: "com.dashucl.launchscreen.size")
                }
            }
        }
    }
}
