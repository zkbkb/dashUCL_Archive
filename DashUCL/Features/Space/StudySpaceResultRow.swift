import SwiftUI

/// Study Space Result Row - Enhanced Version
struct StudySpaceResultRow: View {
    // MARK: - Properties
    let space: SpaceResult
    let showNavigationArrow: Bool
    @Environment(\.colorScheme) private var colorScheme

    // Show navigation arrow by default
    init(space: SpaceResult, showNavigationArrow: Bool = true) {
        self.space = space
        self.showNavigationArrow = showNavigationArrow
    }

    // MARK: - Body
    var body: some View {
        NavigationLink(destination: StudySpaceDetailView(space: space)) {
            HStack(spacing: 12) {
                // Left status indicator - Vertical color bar with circular occupancy indicator
                VStack(spacing: 4) {
                    // Occupancy indicator dot
                    ZStack {
                        Circle()
                            .fill(occupancyColor)
                            .frame(width: 16, height: 16)

                        Circle()
                            .stroke(occupancyColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }

                    // Vertical color bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(occupancyColor)
                        .frame(width: 4, height: 40)
                }
                .padding(.leading, 4)

                // Middle content area
                VStack(alignment: .leading, spacing: 4) {
                    // Space name and occupancy status
                    HStack {
                        Text(space.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        // Brief occupancy status text
                        Text(occupancyStatusText)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(occupancyColor.opacity(0.15))
                            .foregroundColor(occupancyColor)
                            .clipShape(Capsule())
                    }

                    // Seat information
                    HStack(spacing: 8) {
                        // Seat count information
                        Label {
                            Text("\(space.freeSeats) of \(space.totalSeats) available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "chair.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }

                        Spacer()

                        // Occupancy percentage
                        Text("\(space.occupancyPercentage)% Full")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // If there is description information, show a small part
                    if !space.description.isEmpty {
                        Text(
                            space.description.prefix(60)
                                + (space.description.count > 60 ? "..." : "")
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                }

                // Right navigation arrow (if enabled)
                if showNavigationArrow {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    /// Occupancy color
    private var occupancyColor: Color {
        if space.occupancyPercentage < 33 {
            return .green
        } else if space.occupancyPercentage < 66 {
            return .orange
        } else {
            return .red
        }
    }

    /// Occupancy status text
    private var occupancyStatusText: String {
        if space.occupancyPercentage < 33 {
            return "Low"
        } else if space.occupancyPercentage < 66 {
            return "Moderate"
        } else {
            return "High"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        VStack(spacing: 16) {
            StudySpaceResultRow(
                space: SpaceResult(
                    id: "1",
                    name: "Main Library - Study Area",
                    description: "Quiet study space for individual work with good natural lighting",
                    freeSeats: 25,
                    totalSeats: 100,
                    occupancyPercentage: 75
                ))

            StudySpaceResultRow(
                space: SpaceResult(
                    id: "2",
                    name: "Science Library",
                    description: "Specialized resources for science students",
                    freeSeats: 45,
                    totalSeats: 50,
                    occupancyPercentage: 10
                ))

            StudySpaceResultRow(
                space: SpaceResult(
                    id: "3",
                    name: "Computer Science Hub",
                    description: "Computer workstations with development software",
                    freeSeats: 5,
                    totalSeats: 30,
                    occupancyPercentage: 83
                ))
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
