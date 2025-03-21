/*
 * Authentication view handling user login for the DashUCL app.
 * Features an animated gradient background with smooth transitions and loading states.
 * Implements OAuth authentication flow with UCL's identity provider.
 * Provides feedback for login errors and handles authentication state persistence.
 */

import SwiftUI

// Define AnimatedGradientBackground until I resolve import issues
struct AnimatedGradientBackground: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @State private var startPoint = UnitPoint(x: 0, y: 0)
    @State private var endPoint = UnitPoint(x: 1, y: 1)

    // Dark mode colors
    private let darkModeColors: [Color] = [
        Color(red: 0.06, green: 0.06, blue: 0.10),
        Color(red: 0.04, green: 0.04, blue: 0.08),
        Color(red: 0.05, green: 0.05, blue: 0.09),
        Color(red: 0.06, green: 0.06, blue: 0.10),
    ]

    var body: some View {
        ZStack {
            // Fixed dark gray background to prevent flashing
            Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))

            // Gradient animation
            GeometryReader { geometry in
                LinearGradient(
                    gradient: Gradient(colors: darkModeColors),
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .blur(radius: 0)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 30)
                    .repeatForever(autoreverses: true)
            ) {
                startPoint = UnitPoint(x: 1, y: 0)
                endPoint = UnitPoint(x: 0, y: 1)
            }
        }
    }
}

struct LoginView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = LoginViewModel()
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var isLoggingIn = false
    @State private var isShowingLoadingAnimation = false
    @State private var curveOffset: CGFloat = 0
    @State private var currentToast: Toast?
    @State private var showSuccessCheckmark = false
    @State private var agreedToTerms = false
    @State private var shakeLoginButton = false
    @State private var showDeveloperLoginAlert = false
    @State private var developerPassword = ""
    @ObservedObject private var testEnvironment = TestEnvironment.shared
    let onLoginComplete: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main view container
                ZStack {
                    // Dynamic background - consistently use dark mode colors
                    AnimatedGradientBackground()
                        .environment(\.colorScheme, SwiftUI.ColorScheme.dark)
                        .ignoresSafeArea()

                    // Background after successful login - use pure white
                    Rectangle()
                        .fill(.white)
                        .opacity(isLoggingIn ? 1 : 0)
                        .offset(y: isLoggingIn ? 0 : geometry.size.height)
                        .animation(
                            .spring(response: 0.9, dampingFraction: 0.85).delay(0.2),
                            value: isLoggingIn
                        )
                        .ignoresSafeArea()

                    // Main content
                    VStack(spacing: 0) {
                        // Top section with welcome text
                        VStack {
                            Spacer()
                                .frame(height: geometry.size.height * 0.2)

                            // Welcome Text without animation
                            Text("Welcome!")
                                .font(.system(size: 46, weight: .bold))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .padding(.horizontal, 40)
                                .opacity(isShowingLoadingAnimation || isLoggingIn ? 0 : 1)
                                .animation(
                                    .easeInOut(duration: 0.3),
                                    value: isShowingLoadingAnimation || isLoggingIn
                                )

                            // Welcome Text without animation
                            Text("Let's get you signed in.")
                                .font(.system(size: 46, weight: .bold))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .padding(.horizontal, 40)
                                .opacity(isShowingLoadingAnimation || isLoggingIn ? 0 : 1)
                                .animation(
                                    .easeInOut(duration: 0.3),
                                    value: isShowingLoadingAnimation || isLoggingIn
                                )

                            // Loading Animation
                            if isShowingLoadingAnimation {
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    Text("Signing in...")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                .transition(.opacity)
                                .animation(
                                    .easeInOut(duration: 0.3), value: isShowingLoadingAnimation)
                            }

                            Spacer()
                        }
                        .frame(height: geometry.size.height * 0.68)
                        .opacity(isLoggingIn ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.3),
                            value: isLoggingIn
                        )

                        // Bottom section with buttons
                        ZStack {
                            // Background shape
                            ZStack {
                                // Bottom white rectangle
                                Rectangle()
                                    .fill(.white)
                                    .frame(height: geometry.size.height * 0.32 + 50)
                                    .cornerRadius(30, corners: [.topLeft, .topRight])
                                    .offset(y: 50)

                                // Curved design
                                BottomCurveShape(curveOffset: curveOffset)
                                    .fill(.white)
                                    .frame(height: geometry.size.height * 0.32)
                                    .cornerRadius(30, corners: [.topLeft, .topRight])
                                    .offset(
                                        y: isLoggingIn ? -geometry.size.height + curveOffset : 0
                                    )
                                    .animation(
                                        .spring(response: 0.9, dampingFraction: 0.85).delay(0.2),
                                        value: isLoggingIn
                                    )
                            }
                            .opacity(isLoggingIn ? 0 : 1)
                            .animation(
                                .easeOut(duration: 0.5).delay(0.3),
                                value: isLoggingIn
                            )

                            VStack(spacing: 16) {
                                Spacer()  // Add top Spacer to center content

                                // Sign in with UCL Button
                                Button(action: {
                                    if !agreedToTerms {
                                        // Shake button effect
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.2))
                                        {
                                            shakeLoginButton = true
                                        }

                                        // Reset shake effect
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation {
                                                shakeLoginButton = false
                                            }
                                        }

                                        // Show toast reminder
                                        currentToast = Toast(
                                            style: .warning,
                                            message: "Please agree to our terms."
                                        )
                                        return
                                    }

                                    Task {
                                        withAnimation {
                                            isShowingLoadingAnimation = true
                                        }
                                        do {
                                            try await viewModel.login()

                                            // Hide loading animation
                                            withAnimation {
                                                isShowingLoadingAnimation = false
                                            }

                                            // Wait for loading animation to disappear
                                            try await Task.sleep(
                                                nanoseconds: UInt64(0.3 * 1_000_000_000))

                                            // Show success animation
                                            withAnimation {
                                                showSuccessCheckmark = true
                                            }

                                            // Wait for success animation to display
                                            try await Task.sleep(
                                                nanoseconds: UInt64(0.5 * 1_000_000_000))

                                            // Login successful, trigger animation
                                            withAnimation {
                                                isLoggingIn = true
                                            }

                                            // Wait for animation to complete
                                            try await Task.sleep(
                                                nanoseconds: UInt64(1.0 * 1_000_000_000))

                                            // Call completion callback
                                            onLoginComplete()
                                        } catch {
                                            // Restore UI state on login failure
                                            withAnimation(.spring(response: 0.3)) {
                                                isShowingLoadingAnimation = false
                                                isLoggingIn = false
                                                showSuccessCheckmark = false
                                            }

                                            // Show error prompt
                                            currentToast = Toast(
                                                style: .error,
                                                message: "Sign in failed. Please try again."
                                            )
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.circle.fill")
                                            .imageScale(.large)
                                        Text("Sign in with UCL")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                    .shadow(
                                        color: Color.blue.opacity(0.3),
                                        radius: 15,
                                        y: 5
                                    )
                                }
                                .frame(width: geometry.size.width * 0.8)  // Limit button width
                                .offset(x: shakeLoginButton ? -10 : 0)
                                .disabled(viewModel.isLoading || isShowingLoadingAnimation)
                                .opacity(viewModel.isLoading ? 0.7 : 1)
                                .padding(.top, 0)
                                .padding(.bottom, 10)  // Adjust to 10
                                .frame(maxWidth: .infinity)  // Center the button

                                // Terms and Conditions Checkbox
                                HStack {
                                    Spacer()

                                    HStack(alignment: .center, spacing: 12) {
                                        // Checkbox
                                        Button(action: {
                                            withAnimation {
                                                agreedToTerms.toggle()
                                            }
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(
                                                        agreedToTerms
                                                            ? Color.blue : Color.gray.opacity(0.5),
                                                        lineWidth: 1.5
                                                    )
                                                    .frame(width: 24, height: 24)
                                                    .background(
                                                        agreedToTerms
                                                            ? Color.blue.opacity(0.1) : Color.clear
                                                    )

                                                if agreedToTerms {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }

                                        // Use VStack to display text in multiple lines
                                        VStack(alignment: .leading, spacing: 2) {
                                            // First line
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                Text("I Agree to these")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(
                                                        Color(hex: "1C1C1E").opacity(0.8))

                                                Button(action: {
                                                    showTermsSheet = true
                                                }) {
                                                    Text("Terms and Conditions")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.blue)
                                                        .underline()
                                                }
                                            }
                                            .fixedSize(horizontal: false, vertical: true)

                                            // Second line
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                Text("and")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(
                                                        Color(hex: "1C1C1E").opacity(0.8))

                                                Button(action: {
                                                    showPrivacySheet = true
                                                }) {
                                                    Text("Privacy Policy")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.blue)
                                                        .underline()
                                                }
                                            }
                                            .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    Spacer()
                                }
                                .frame(width: geometry.size.width * 0.8)  // Match button width
                                .frame(maxWidth: .infinity)  // Center display
                                .padding(.top, 0)
                                .padding(.bottom, 0)
                                .offset(x: shakeLoginButton && !agreedToTerms ? 10 : 0)

                                // Developer Login
                                Text("Developer Login")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .padding(.top, 20)
                                    .onTapGesture {
                                        showDeveloperLoginAlert = true
                                    }

                                Spacer()  // Bottom Spacer automatically adjusts height to center content
                            }
                            .offset(y: isLoggingIn ? geometry.size.height : 0)
                            .animation(
                                .spring(response: 0.9, dampingFraction: 0.85).delay(0.2),
                                value: isLoggingIn
                            )
                        }
                        .frame(height: geometry.size.height * 0.32)
                    }
                    .frame(maxWidth: min(geometry.size.width, 500))
                    .frame(maxWidth: .infinity)
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 44,
                        style: .continuous
                    )
                )

                // Success Checkmark
                SuccessCheckmarkView(isShowing: $showSuccessCheckmark)
            }
        }
        .toast(toast: $currentToast)
        .fullScreenCover(isPresented: $showTermsSheet) {
            TermsAndConditionsView()
        }
        .fullScreenCover(isPresented: $showPrivacySheet) {
            LoginPrivacyPolicyView()
        }
        .ignoresSafeArea()
        .onAppear {
            // Delay expanding login interface
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {  // Increase delay to 0.6 seconds
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
                        interfaceOrientations: .portrait
                    )
                    windowScene.requestGeometryUpdate(geometryPreferences)
                }
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                    curveOffset = 35  // Decrease offset to make curve more natural
                }
            }
        }
        .alert("Developer Login", isPresented: $showDeveloperLoginAlert) {
            SecureField("Enter Password", text: $developerPassword)
                .keyboardType(.numberPad)

            Button("Cancel", role: .cancel) {
                developerPassword = ""
            }

            Button("Login") {
                if developerPassword == "171743" {
                    // Enable test mode
                    testEnvironment.isTestMode = true

                    // Show success message
                    currentToast = Toast(
                        style: .success,
                        message: "Developer mode activated"
                    )

                    // Delay login completion callback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onLoginComplete()
                    }
                } else {
                    // Show error message
                    currentToast = Toast(
                        style: .error,
                        message: "Invalid developer password"
                    )
                }

                // Clear password
                developerPassword = ""
            }
        } message: {
            Text("Enter the 6-digit developer password to access test mode")
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIScene.willConnectNotification)
        ) { notification in
            guard let windowScene = notification.object as? UIWindowScene else { return }
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
                interfaceOrientations: .portrait
            )
            windowScene.requestGeometryUpdate(geometryPreferences)
        }
        // Add background style modifier
        .background(Color.black)
    }
}

// Avatar circle modifier
struct AvatarCircleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
    }
}

// Extension for hex color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Bottom curve shape
struct BottomCurveShape: Shape {
    var curveOffset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let midX = width / 2

        // Simplified pure arc design
        let arcHeight: CGFloat = 35  // Decrease arc height to make it more natural

        // Start point from bottom
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: height - curveOffset))

        // Use three Bezier curves to create a smooth arc
        path.addCurve(
            to: CGPoint(x: midX, y: height - curveOffset - arcHeight),
            control1: CGPoint(x: width * 0.25, y: height - curveOffset),
            control2: CGPoint(x: width * 0.35, y: height - curveOffset - arcHeight)
        )

        path.addCurve(
            to: CGPoint(x: width, y: height - curveOffset),
            control1: CGPoint(x: width * 0.65, y: height - curveOffset - arcHeight),
            control2: CGPoint(x: width * 0.75, y: height - curveOffset)
        )

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

#Preview("Login Screen") {
    LoginView(onLoginComplete: {
        print("Login animation completed")
    })
}
