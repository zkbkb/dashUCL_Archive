import SwiftUI
import UIKit

// MARK: - Department Result Row Component
struct DepartmentResultRow: View {
    let department: DepartmentResult
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Use vertical color bar
            Rectangle()
                .fill(Color.purple)
                .frame(width: 4, height: 50)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(department.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text("Department code:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(department.code)
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
    }
}

// MARK: - Optimization Support Components

// Category Pills - New Segmented Control Style
struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(isSelected ? color.opacity(0.15) : Color(UIColor.systemBackground))
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 1 : 0.5)
        )
        .foregroundColor(isSelected ? color : .secondary)
        .shadow(color: isSelected ? color.opacity(0.1) : Color.clear, radius: 1, x: 0, y: 0.5)
    }
}

// Explore Card - Optimized Design
struct ExploreCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    let query: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 100, height: 100)
                )

            Text("No results found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("We couldn't find anything matching '\(query)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Search Loading View
struct SearchLoadingView: View {
    @State private var rotation: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            // Loading indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
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
                Text("Searching...")
                    .font(.headline)

                Text("Looking for matches across UCL")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color(.systemGroupedBackground))
    }
}
