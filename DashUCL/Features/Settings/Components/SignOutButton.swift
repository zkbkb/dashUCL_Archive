import Foundation
import SwiftUI

struct SignOutButton: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    @Binding var isSigningOut: Bool
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var coordinator = TransitionCoordinator.shared

    var body: some View {
        Button(action: {
            showingConfirmation = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .imageScale(.medium)
                Text("Sign Out")
                    .fontWeight(.medium)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.red.opacity(0.1))
            }
        }
        .confirmationDialog(
            "Sign out from DashUCL?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                performSignOut()
            }

            Button("Cancel", role: .cancel) {
                showingConfirmation = false
            }
        } message: {
            Text("You'll need to sign in again to access your account.")
        }
    }

    private func performSignOut() {
        // Use combined animations to create a smooth transition effect
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isSigningOut = true
        }

        // Wait for the spring animation to partially complete before starting the sign out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Send sign out notification
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)

            // Perform the actual sign out operation
            AuthManager.shared.signOut()

            // Start transition animation
            coordinator.transitionToLogin()

            // Close the current view after the login screen is fully displayed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    SignOutButton(isSigningOut: .constant(false))
}
