import SwiftUI

// Toast style
enum ToastStyle {
    case error
    case warning
    case success

    var themeColor: Color {
        switch self {
        case .error:
            return .red
        case .warning:
            return .orange
        case .success:
            return .green
        }
    }

    var iconName: String {
        switch self {
        case .error:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
}

// Toast configuration
struct Toast: Equatable {
    let style: ToastStyle
    let message: String
    let duration: Double = 2.0
    let delay: Double = 0.22  // Delay time changed to 0.22 seconds
}

// Toast view
struct ToastView: View {
    let style: ToastStyle
    let message: String
    let onClosed: () -> Void
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.iconName)
                .foregroundColor(.white)
                .imageScale(.medium)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onClosed) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .imageScale(.small)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(style.themeColor)
                .opacity(0.95)
        )
        .shadow(color: style.themeColor.opacity(0.3), radius: 8, y: 4)
        .frame(maxWidth: .infinity, alignment: .leading)  // Add maximum width limit
        .padding(.horizontal, 40)  // Use same horizontal padding as Welcome text
    }
}

// Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isVisible {
                        VStack(spacing: 0) {
                            mainToastView()
                                .padding(.top, geometry.safeAreaInsets.top + 70)
                            Spacer()
                        }
                    }
                }
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3),
                    value: isVisible
                )
            )
            .onChange(of: toast) { oldValue, newValue in
                showToast()
            }
    }

    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            ToastView(
                style: toast.style,
                message: toast.message
            ) {
                dismissToast()
            }
            .transition(
                AnyTransition.asymmetric(
                    insertion: AnyTransition.scale(scale: 0.5, anchor: UnitPoint.center)
                        .combined(with: AnyTransition.opacity),
                    removal: AnyTransition.scale(scale: 0.8, anchor: UnitPoint.center)
                        .combined(with: AnyTransition.opacity)
                )
            )
        }
    }

    private func showToast() {
        guard let toast = toast else { return }

        workItem?.cancel()

        // Delay display
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.delay) {
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .rigid)
                .impactOccurred()

            // Show Toast
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3)) {
                isVisible = true
            }

            // Set disappear time
            let task = DispatchWorkItem {
                dismissToast()
            }

            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }

    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }

        // Wait for animation to complete before cleaning up state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            toast = nil
            workItem?.cancel()
            workItem = nil
        }
    }
}

// Toast View extension
extension View {
    func toast(toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Get safe area
private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return (windowScene.windows.first?.safeAreaInsets ?? UIEdgeInsets()).insets
        }
        return EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
