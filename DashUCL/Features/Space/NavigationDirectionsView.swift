import MapKit
import SwiftUI

// MARK: - Navigation Directions View
struct NavigationDirectionsView: View {
    let destination: CLLocationCoordinate2D
    let locationName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Map(
                    initialPosition: MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: destination,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                ) {
                    Marker(locationName, coordinate: destination)
                }
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    Text("Get directions to:")
                        .font(.headline)

                    Text(locationName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        // Walking navigation
                        DirectionButton(
                            title: "Walk",
                            icon: "figure.walk",
                            color: .green
                        ) {
                            openMapsForDirections(transportType: .walking)
                        }

                        // Public transport navigation
                        DirectionButton(
                            title: "Transit",
                            icon: "bus.fill",
                            color: .blue
                        ) {
                            openMapsForDirections(transportType: .transit)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding()
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Open maps app
    private func openMapsForDirections(transportType: MKDirectionsTransportType) {
        let placemark = MKPlacemark(coordinate: destination)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = locationName

        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: transportType == .walking
                ? MKLaunchOptionsDirectionsModeWalking : MKLaunchOptionsDirectionsModeTransit
        ]

        mapItem.openInMaps(launchOptions: launchOptions)
    }
}

// MARK: - Navigation Buttons
struct DirectionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationDirectionsView(
        destination: CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.1336),
        locationName: "UCL Main Library"
    )
}
