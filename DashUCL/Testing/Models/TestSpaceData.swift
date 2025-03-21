import Foundation
import MapKit
import SwiftUI

/// Test Space Data
/// Provides mock data for study spaces and computer clusters
enum TestSpaceData {
    // MARK: - Study Space Data

    // 20 study spaces randomly selected from real data
    static let studySpaces: [SpaceResult] = [
        SpaceResult(
            id: "sci-lib-1",
            name: "Science Library - Level 2",
            description: "Quiet study area with individual desks and power outlets",
            freeSeats: 45,
            totalSeats: 80,
            occupancyPercentage: 44
        ),
        SpaceResult(
            id: "sci-lib-2",
            name: "Science Library - Level 3",
            description: "Silent study zone with comfortable seating",
            freeSeats: 32,
            totalSeats: 60,
            occupancyPercentage: 47
        ),
        SpaceResult(
            id: "main-lib-1",
            name: "Main Library - Reading Room",
            description: "Historic reading room with traditional study desks",
            freeSeats: 28,
            totalSeats: 100,
            occupancyPercentage: 72
        ),
        SpaceResult(
            id: "main-lib-2",
            name: "Main Library - Group Study Area",
            description: "Collaborative space for group work and discussions",
            freeSeats: 15,
            totalSeats: 50,
            occupancyPercentage: 70
        ),
        SpaceResult(
            id: "student-centre-1",
            name: "Student Centre - Ground Floor",
            description: "Modern study space with 24/7 access",
            freeSeats: 120,
            totalSeats: 200,
            occupancyPercentage: 40
        ),
        SpaceResult(
            id: "student-centre-2",
            name: "Student Centre - Level 1",
            description: "Quiet study area with panoramic views",
            freeSeats: 85,
            totalSeats: 150,
            occupancyPercentage: 43
        ),
        SpaceResult(
            id: "ioe-lib",
            name: "IOE Library - Newsam Library",
            description: "Specialized education resources and study spaces",
            freeSeats: 42,
            totalSeats: 80,
            occupancyPercentage: 48
        ),
        SpaceResult(
            id: "bartlett-lib",
            name: "Bartlett Library",
            description: "Architecture and planning focused study space",
            freeSeats: 18,
            totalSeats: 40,
            occupancyPercentage: 55
        ),
        SpaceResult(
            id: "cruciform-hub",
            name: "Cruciform Hub",
            description: "Medical sciences study space with group areas",
            freeSeats: 35,
            totalSeats: 120,
            occupancyPercentage: 71
        ),
        SpaceResult(
            id: "senate-house",
            name: "Senate House Library",
            description: "Historic library with extensive collections",
            freeSeats: 65,
            totalSeats: 150,
            occupancyPercentage: 57
        ),
        SpaceResult(
            id: "graduate-hub",
            name: "Graduate Hub",
            description: "Dedicated space for postgraduate students",
            freeSeats: 25,
            totalSeats: 40,
            occupancyPercentage: 38
        ),
        SpaceResult(
            id: "language-space",
            name: "Language & Study Centre",
            description: "Resources for language learning and quiet study",
            freeSeats: 30,
            totalSeats: 60,
            occupancyPercentage: 50
        ),
        SpaceResult(
            id: "ssees-lib",
            name: "SSEES Library",
            description: "Slavonic and East European studies resources",
            freeSeats: 22,
            totalSeats: 50,
            occupancyPercentage: 56
        ),
        SpaceResult(
            id: "ucl-east-lib",
            name: "UCL East Library",
            description: "New campus library with modern facilities",
            freeSeats: 80,
            totalSeats: 120,
            occupancyPercentage: 33
        ),
        SpaceResult(
            id: "bloomsbury-theatre",
            name: "Bloomsbury Theatre Study Space",
            description: "Quiet study area near the theatre",
            freeSeats: 15,
            totalSeats: 30,
            occupancyPercentage: 50
        ),
        SpaceResult(
            id: "anatomy-building",
            name: "Anatomy Building - Study Room",
            description: "Medical students focused study area",
            freeSeats: 12,
            totalSeats: 40,
            occupancyPercentage: 70
        ),
        SpaceResult(
            id: "chandler-house",
            name: "Chandler House - Language Sciences",
            description: "Specialized study space for language sciences",
            freeSeats: 18,
            totalSeats: 35,
            occupancyPercentage: 49
        ),
        SpaceResult(
            id: "bentham-house",
            name: "Bentham House - Law Library",
            description: "Law students focused study environment",
            freeSeats: 25,
            totalSeats: 80,
            occupancyPercentage: 69
        ),
        SpaceResult(
            id: "pearson-building",
            name: "Pearson Building - Geography",
            description: "Geography department study space",
            freeSeats: 20,
            totalSeats: 45,
            occupancyPercentage: 56
        ),
        SpaceResult(
            id: "rockefeller-building",
            name: "Rockefeller Building - Study Area",
            description: "Medical sciences quiet study zone",
            freeSeats: 15,
            totalSeats: 35,
            occupancyPercentage: 57
        ),
    ]

    // MARK: - Computer Cluster Data

    // 20 computer clusters randomly selected from real data
    static let computerClusters: [SpaceResult] = [
        SpaceResult(
            id: "dms-watson-cc",
            name: "DMS Watson Building - Computer Cluster",
            description: "General purpose computer lab with specialized software",
            freeSeats: 28,
            totalSeats: 50,
            occupancyPercentage: 44
        ),
        SpaceResult(
            id: "foster-court-cc",
            name: "Foster Court - Computer Cluster",
            description: "24-hour access computer facilities",
            freeSeats: 15,
            totalSeats: 40,
            occupancyPercentage: 63
        ),
        SpaceResult(
            id: "malet-place-cc1",
            name: "Malet Place Engineering - Cluster 1",
            description: "Engineering software equipped computers",
            freeSeats: 22,
            totalSeats: 60,
            occupancyPercentage: 63
        ),
        SpaceResult(
            id: "malet-place-cc2",
            name: "Malet Place Engineering - Cluster 2",
            description: "High-performance computing facilities",
            freeSeats: 18,
            totalSeats: 40,
            occupancyPercentage: 55
        ),
        SpaceResult(
            id: "torrington-cc",
            name: "Torrington Place - Computer Suite",
            description: "Modern computer facilities with dual monitors",
            freeSeats: 35,
            totalSeats: 80,
            occupancyPercentage: 56
        ),
        SpaceResult(
            id: "ucl-east-cc",
            name: "UCL East - Pool Street Computer Lab",
            description: "New campus computing facilities",
            freeSeats: 40,
            totalSeats: 60,
            occupancyPercentage: 33
        ),
        SpaceResult(
            id: "sci-lib-cc",
            name: "Science Library - Computer Cluster",
            description: "Quiet computing environment with science software",
            freeSeats: 25,
            totalSeats: 50,
            occupancyPercentage: 50
        ),
        SpaceResult(
            id: "main-lib-cc",
            name: "Main Library - Computer Area",
            description: "General purpose computers in library setting",
            freeSeats: 15,
            totalSeats: 40,
            occupancyPercentage: 63
        ),
        SpaceResult(
            id: "cruciform-cc",
            name: "Cruciform Hub - Medical Computing",
            description: "Specialized medical software and resources",
            freeSeats: 12,
            totalSeats: 30,
            occupancyPercentage: 60
        ),
        SpaceResult(
            id: "ioe-cc",
            name: "IOE - Learning Technologies Suite",
            description: "Education focused computing resources",
            freeSeats: 18,
            totalSeats: 35,
            occupancyPercentage: 49
        ),
        SpaceResult(
            id: "bartlett-cc",
            name: "Bartlett - Architectural Computing",
            description: "Design software and high-performance workstations",
            freeSeats: 10,
            totalSeats: 40,
            occupancyPercentage: 75
        ),
        SpaceResult(
            id: "bloomsbury-cc",
            name: "Bloomsbury - Computer Teaching Room",
            description: "Dual purpose teaching and open access facility",
            freeSeats: 20,
            totalSeats: 45,
            occupancyPercentage: 56
        ),
        SpaceResult(
            id: "roberts-building-cc",
            name: "Roberts Building - Engineering Cluster",
            description: "Engineering software and simulation tools",
            freeSeats: 15,
            totalSeats: 50,
            occupancyPercentage: 70
        ),
        SpaceResult(
            id: "chandler-house-cc",
            name: "Chandler House - Language Lab",
            description: "Language learning software and audio facilities",
            freeSeats: 22,
            totalSeats: 30,
            occupancyPercentage: 27
        ),
        SpaceResult(
            id: "bentham-house-cc",
            name: "Bentham House - Law Computing",
            description: "Legal databases and research tools",
            freeSeats: 18,
            totalSeats: 40,
            occupancyPercentage: 55
        ),
        SpaceResult(
            id: "geography-cc",
            name: "Geography - GIS Lab",
            description: "Geographic Information Systems workstations",
            freeSeats: 12,
            totalSeats: 30,
            occupancyPercentage: 60
        ),
        SpaceResult(
            id: "physics-cc",
            name: "Physics Building - Computer Lab",
            description: "Physics simulation and data analysis workstations",
            freeSeats: 20,
            totalSeats: 35,
            occupancyPercentage: 43
        ),
        SpaceResult(
            id: "chemistry-cc",
            name: "Chemistry Building - Computational Suite",
            description: "Molecular modeling and computational chemistry",
            freeSeats: 15,
            totalSeats: 25,
            occupancyPercentage: 40
        ),
        SpaceResult(
            id: "student-centre-cc",
            name: "Student Centre - Digital Commons",
            description: "24/7 access computing facilities",
            freeSeats: 45,
            totalSeats: 100,
            occupancyPercentage: 55
        ),
        SpaceResult(
            id: "drayton-house-cc",
            name: "Drayton House - Economics Lab",
            description: "Statistical software and economic databases",
            freeSeats: 22,
            totalSeats: 40,
            occupancyPercentage: 45
        ),
    ]

    // MARK: - Location Coordinate Data

    // Coordinate data for main buildings
    static let locationCoordinates: [String: CLLocationCoordinate2D] = [
        "Science Library": CLLocationCoordinate2D(latitude: 51.5253, longitude: -0.1339),
        "Main Library": CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.1331),
        "Student Centre": CLLocationCoordinate2D(latitude: 51.5252, longitude: -0.1326),
        "IOE Library": CLLocationCoordinate2D(latitude: 51.5227, longitude: -0.1281),
        "Bartlett Library": CLLocationCoordinate2D(latitude: 51.5229, longitude: -0.1317),
        "Cruciform Hub": CLLocationCoordinate2D(latitude: 51.5240, longitude: -0.1350),
        "Senate House Library": CLLocationCoordinate2D(latitude: 51.5218, longitude: -0.1305),
        "Graduate Hub": CLLocationCoordinate2D(latitude: 51.5245, longitude: -0.1335),
        "Language & Study Centre": CLLocationCoordinate2D(latitude: 51.5255, longitude: -0.1320),
        "SSEES Library": CLLocationCoordinate2D(latitude: 51.5259, longitude: -0.1310),
        "UCL East Library": CLLocationCoordinate2D(latitude: 51.5430, longitude: -0.0209),
        "Bloomsbury Theatre": CLLocationCoordinate2D(latitude: 51.5257, longitude: -0.1328),
        "Anatomy Building": CLLocationCoordinate2D(latitude: 51.5236, longitude: -0.1345),
        "Chandler House": CLLocationCoordinate2D(latitude: 51.5242, longitude: -0.1190),
        "Bentham House": CLLocationCoordinate2D(latitude: 51.5267, longitude: -0.1304),
        "Pearson Building": CLLocationCoordinate2D(latitude: 51.5251, longitude: -0.1341),
        "Rockefeller Building": CLLocationCoordinate2D(latitude: 51.5236, longitude: -0.1357),
        "DMS Watson Building": CLLocationCoordinate2D(latitude: 51.5253, longitude: -0.1339),
        "Foster Court": CLLocationCoordinate2D(latitude: 51.5245, longitude: -0.1325),
        "Malet Place Engineering": CLLocationCoordinate2D(latitude: 51.5240, longitude: -0.1330),
        "Torrington Place": CLLocationCoordinate2D(latitude: 51.5230, longitude: -0.1340),
        "Roberts Building": CLLocationCoordinate2D(latitude: 51.5235, longitude: -0.1320),
        "Physics Building": CLLocationCoordinate2D(latitude: 51.5245, longitude: -0.1345),
        "Chemistry Building": CLLocationCoordinate2D(latitude: 51.5250, longitude: -0.1350),
        "Drayton House": CLLocationCoordinate2D(latitude: 51.5225, longitude: -0.1300),
    ]

    // MARK: - Helper Methods

    /// Get all test space data (study spaces and computer clusters)
    static var allSpaces: [SpaceResult] {
        return studySpaces + computerClusters
    }

    /// Get location coordinates by space ID
    static func getCoordinateForSpace(_ spaceId: String) -> CLLocationCoordinate2D? {
        // Extract location name from space ID
        let components = spaceId.split(separator: "-")
        if components.count >= 2 {
            let locationKey = components[0...1].joined(separator: "-").replacingOccurrences(
                of: "-", with: " ")
            let capitalizedKey = locationKey.split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")

            // Try to match full name
            for (key, coordinate) in locationCoordinates {
                if key.contains(capitalizedKey) {
                    return coordinate
                }
            }
        }

        // Return UCL main campus coordinates by default
        return CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.1336)
    }
}
