import SwiftUI

struct SuccessCheckmarkView: View {
    @Binding var isShowing: Bool
    @State private var checkmarkScale: CGFloat = 0
    @State private var circleScale: CGFloat = 0
    @State private var checkmarkStrokeEnd: CGFloat = 0

    // Define color scheme
    private let successColor = Color(red: 0.2, green: 0.85, blue: 0.45)
    private let bgColor = Color.white.opacity(0.95)

    var body: some View {
        ZStack {
            // Success checkmark container
            if isShowing {
                ZStack {
                    // Outer blur effect
                    Circle()
                        .fill(Material.ultraThinMaterial)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(bgColor.opacity(0.5), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .scaleEffect(circleScale)

                    // Success color circle
                    Circle()
                        .stroke(successColor, lineWidth: 3.5)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .fill(successColor.opacity(0.12))
                        )
                        .scaleEffect(circleScale)

                    // Checkmark with gradient
                    CheckmarkShape()
                        .trim(from: 0, to: checkmarkStrokeEnd)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    successColor,
                                    successColor.opacity(0.85),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4.2, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 32, height: 32)
                        .scaleEffect(checkmarkScale)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                // Smoother animation timing
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    circleScale = 1
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)) {
                    checkmarkScale = 1
                }
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    checkmarkStrokeEnd = 1
                }

                // Auto-dismiss after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            } else {
                checkmarkScale = 0
                circleScale = 0
                checkmarkStrokeEnd = 0
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height

        var path = Path()
        // Optimize checkmark shape
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.53))
        path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.7))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.3))

        return path
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isShowing = true

        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)

                Button("Toggle Animation") {
                    withAnimation {
                        isShowing.toggle()
                    }
                }

                SuccessCheckmarkView(isShowing: $isShowing)
            }
        }
    }

    return PreviewWrapper()
}
