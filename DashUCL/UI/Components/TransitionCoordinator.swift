/*
 * Manages view transitions between major app states like login and main content.
 * Implements smooth animations with coordinated timing for fluid user experience.
 * Uses a singleton pattern to maintain consistent transition state across the app.
 * Supports two-phase transitions with customizable animation parameters.
 */

import SwiftUI

class TransitionCoordinator: ObservableObject {
    static let shared = TransitionCoordinator()

    @Published var isTransitioning = false
    @Published var shouldShowLogin = false

    private init() {}

    func transitionToLogin() {
        // Start transition
        withAnimation(.easeOut(duration: 0.3)) {
            isTransitioning = true
        }

        // Show login interface after first animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.shouldShowLogin = true
            }
        }
    }

    func resetState() {
        isTransitioning = false
        shouldShowLogin = false
    }
}
