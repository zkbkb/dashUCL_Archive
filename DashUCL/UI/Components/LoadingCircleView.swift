/*
 * Reusable loading indicator component with customizable appearance and text.
 * Implements a smooth rotation animation and adaptable color scheme support.
 * Provides consistent loading experience across different app screens.
 * Features accessibility considerations with descriptive labels and scalable elements.
 */

import SwiftUI

/// Generic circular loading animation component
/// Displays a rotating circular loading indicator with title and optional description text
struct LoadingCircleView: View {
    // MARK: - Properties
    @State private var rotation: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    // Customizable properties
    var title: String
    var description: String?
    var circleColor: Color
    var circleSize: CGFloat
    var strokeWidth: CGFloat

    // MARK: - Initializers

    /// Create a standard loading view
    /// - Parameters:
    ///   - title: Loading title
    ///   - description: Optional description text
    ///   - circleColor: Circle color, defaults to blue
    ///   - circleSize: Circle size, defaults to 80
    ///   - strokeWidth: Circle stroke width, defaults to 8
    init(
        title: String,
        description: String? = nil,
        circleColor: Color = .blue,
        circleSize: CGFloat = 80,
        strokeWidth: CGFloat = 8
    ) {
        self.title = title
        self.description = description
        self.circleColor = circleColor
        self.circleSize = circleSize
        self.strokeWidth = strokeWidth
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            // Loading indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: strokeWidth)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        circleColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 1).repeatForever(autoreverses: false)
                        ) {
                            rotation = 360
                        }
                    }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)

                if let description = description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorScheme == .dark
                ? Color(.systemBackground)
                : Color(.systemBackground)
        )
    }
}

#Preview("Loading Circle Variants") {
    VStack {
        LoadingCircleView(
            title: "Loading Data",
            description: "Please wait while we fetch your information"
        )
        .frame(height: 300)

        LoadingCircleView(
            title: "Processing",
            description: nil,
            circleColor: .green,
            circleSize: 60,
            strokeWidth: 6
        )
        .frame(height: 300)
    }
}
