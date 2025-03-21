/*
 * Primary container view that manages authentication state and view transitions.
 * Handles switching between LoginView and HomeView based on user authentication status.
 * Implements smooth animations for view transitions with opacity and scaling effects.
 * Uses notification center to respond to authentication state changes across the app.
 */

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var testEnvironment = TestEnvironment.shared
    @StateObject private var coordinator = TransitionCoordinator.shared
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var authObserver = AuthStateObserver.shared

    @State private var shouldShowHome: Bool = false
    @State private var viewOpacity: CGFloat = 1
    @State private var viewScale: CGFloat = 1

    init() {
        _shouldShowHome = State(initialValue: AuthManager.shared.isAuthenticated)
    }

    var body: some View {
        ZStack {
            // Background color - Use iOS dark mode standard dark gray (RGB: 28, 28, 30)
            (colorScheme == .dark
                ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
                : Color(UIColor.systemBackground))
                .ignoresSafeArea()

            // Main content view
            Group {
                if shouldShowHome || testEnvironment.isAuthenticated {
                    HomeView()
                        .transition(
                            AnyTransition.asymmetric(
                                insertion: AnyTransition.opacity.combined(
                                    with: AnyTransition.scale(scale: 1.02)),
                                removal: AnyTransition.opacity.combined(
                                    with: AnyTransition.scale(scale: 0.98))
                            )
                        )
                } else {
                    LoginView(onLoginComplete: {
                        // Ensure UI updates on main thread
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                shouldShowHome = true
                            }
                        }
                    })
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: AnyTransition.opacity.combined(
                                with: AnyTransition.scale(scale: 0.98)),
                            removal: AnyTransition.opacity.combined(
                                with: AnyTransition.scale(scale: 1.02))
                        )
                    )
                }
            }
            .opacity(viewOpacity)
            .scaleEffect(viewScale)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.85),
                value: shouldShowHome || testEnvironment.isAuthenticated
            )
        }
        .preferredColorScheme(themeManager.colorScheme)
        // Listen for logout notification
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            // Fade out current view first
            withAnimation(.easeInOut(duration: 0.25)) {
                viewOpacity = 0
                viewScale = 0.98
            }

            // Wait for fade out animation to complete before switching views
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    shouldShowHome = false
                }

                // Start restore animation immediately after view switch
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewOpacity = 1
                    viewScale = 1
                }
            }
        }
        // Monitor authentication state changes
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                // If authenticated, show home page
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    shouldShowHome = true
                }
            } else {
                // If not authenticated, return to login page
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    shouldShowHome = false
                }
            }
        }
        // Add .onAppear to ensure view appears to check authentication state
        .onAppear {
            // At view appearance, ensure shouldShowHome and authManager.isAuthenticated are consistent
            if shouldShowHome != authManager.isAuthenticated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    shouldShowHome = authManager.isAuthenticated
                }
            }
            print(
                "ContentView appeared, authentication state: \(authManager.isAuthenticated), shouldShowHome: \(shouldShowHome)"
            )
        }
        // Add listener for user login success notification
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignIn)) { _ in
            print("ContentView received userDidSignIn notification")
            if !shouldShowHome {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    shouldShowHome = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationManager.shared)
}
