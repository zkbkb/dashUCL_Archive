import MapKit
import SwiftUI

/// Study Space Detail View
struct StudySpaceDetailView: View {
    // MARK: - Properties
    let space: SpaceResult
    @Environment(\.dismiss) private var dismiss
    @State private var mapRegion = MKCoordinateRegion()
    @State private var isMapExpanded = false
    @State private var showDirections = false
    @State private var expandedDescription = false

    // Regular expression for clearing [LIB] and [ISD] prefixes
    private static let tagPattern = try! NSRegularExpression(
        pattern: "\\[(LIB|ISD)\\]\\s*",
        options: []
    )

    // Clean space name (no tags)
    private var cleanSpaceName: String {
        let range = NSRange(location: 0, length: space.name.utf16.count)
        return Self.tagPattern.stringByReplacingMatches(
            in: space.name,
            options: [],
            range: range,
            withTemplate: ""
        ).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title area
                VStack(alignment: .leading, spacing: 8) {
                    Text(cleanSpaceName)
                        .font(.title)
                        .fontWeight(.bold)

                    if !space.description.isEmpty {
                        Text(
                            expandedDescription
                                ? space.description
                                : space.description.prefix(100)
                                    + (space.description.count > 100 ? "..." : "")
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(expandedDescription ? nil : 3)
                        .animation(.easeInOut, value: expandedDescription)
                        .onTapGesture {
                            withAnimation {
                                expandedDescription.toggle()
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal)

                // Seat occupancy card - Only shown when seat data is available
                if space.totalSeats > 0 {
                    VStack(spacing: 12) {
                        // Occupancy information card
                        occupancyCard

                        // Seat information card
                        bookableSeatInfo
                    }
                    .padding(.horizontal)
                } else {
                    // Show no seat data prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seat Availability")
                            .font(.headline)

                        Text("No seat availability data for this location")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Get real coordinates of the building where the space is located
                let spaceCoordinate = UCLBuildingCoordinates.getCoordinate(for: space.name)

                // Map view
                ZStack(alignment: .topTrailing) {
                    MapView(coordinate: spaceCoordinate, locationName: cleanSpaceName)
                        .frame(height: isMapExpanded ? 300 : 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(.spring(), value: isMapExpanded)

                    // Expand/shrink map button
                    Button(action: {
                        withAnimation {
                            isMapExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isMapExpanded ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .padding(8)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .padding(.horizontal)

                // Navigation button
                Button {
                    showDirections = true
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Get Directions")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Add data source explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Source Information")
                        .font(.headline)

                    Text(
                        "Location data is provided by UCL API. Seat availability data is only available for spaces reported by the workspace sensors API. Some locations may not have seat availability information."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Location Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDirections) {
            // Open map application for navigation using real coordinates
            let coordinate = UCLBuildingCoordinates.getCoordinate(for: space.name)
            NavigationDirectionsView(destination: coordinate, locationName: cleanSpaceName)
        }
    }

    // MARK: - Components

    /// Seat occupancy information card
    private var occupancyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Availability")
                .font(.headline)

            HStack(alignment: .center, spacing: 20) {
                // Occupancy chart - Modified to show availability
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: CGFloat(100 - space.occupancyPercentage) / 100)
                        .stroke(occupancyColor, lineWidth: 10)
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(100 - space.occupancyPercentage)%")
                            .font(.system(size: 20, weight: .bold))
                        Text("Available")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                // Occupancy description
                VStack(alignment: .leading, spacing: 5) {
                    Label {
                        Text(occupancyDescription)
                            .font(.subheadline)
                            .foregroundStyle(occupancyColor)
                    } icon: {
                        Image(systemName: occupancyIcon)
                            .foregroundStyle(occupancyColor)
                    }

                    Text("\(space.totalSeats - space.freeSeats) seats in use")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(space.freeSeats) seats available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Seat information card
    private var bookableSeatInfo: some View {
        HStack(spacing: 20) {
            // Left information card
            VStack(alignment: .leading, spacing: 6) {
                Label("Total Capacity", systemImage: "person.3.fill")
                    .font(.subheadline)

                Text("\(space.totalSeats)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Right information card
            VStack(alignment: .leading, spacing: 6) {
                Label("Available Now", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(space.freeSeats > 0 ? .green : .red)

                Text("\(space.freeSeats)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helper Methods

    /// Returns corresponding color based on occupancy rate
    private var occupancyColor: Color {
        if space.occupancyPercentage <= 33 {
            return .green
        } else if space.occupancyPercentage <= 66 {
            return .orange
        } else {
            return .red
        }
    }

    /// Occupancy description text - Modified to describe availability
    private var occupancyDescription: String {
        if space.occupancyPercentage <= 33 {
            return "High Availability"
        } else if space.occupancyPercentage <= 66 {
            return "Moderate Availability"
        } else {
            return "Low Availability"
        }
    }

    /// Occupancy icon - Maintain original logic
    private var occupancyIcon: String {
        if space.occupancyPercentage <= 33 {
            return "checkmark.circle.fill"
        } else if space.occupancyPercentage <= 66 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    /// Get color based on availability percentage
    private func getAvailabilityColor(percentage: Int) -> Color {
        if percentage >= 66 {
            return .green
        } else if percentage >= 33 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Map view
struct MapView: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String

    var body: some View {
        Map(
            initialPosition: MapCameraPosition.region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        ) {
            Marker(locationName, coordinate: coordinate)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StudySpaceDetailView(
            space: SpaceResult(
                id: "1",
                name: "Main Library - Quiet Study Area",
                description:
                    "A dedicated quiet study space located on the 2nd floor of the Main Library. This area is perfect for individual study and offers a peaceful environment with natural lighting and comfortable seating. Please maintain silence in this area.",
                freeSeats: 25,
                totalSeats: 100,
                occupancyPercentage: 75
            ))
    }
}
