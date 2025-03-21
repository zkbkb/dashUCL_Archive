import Foundation
import MapKit

/// UCL Building Coordinates Data
struct UCLBuildingCoordinates {
    /// Building coordinates mapping table - Using precise coordinates provided by UCL API
    static let buildingCoordinates: [String: CLLocationCoordinate2D] = [
        // Main libraries and study spaces
        "Main Library": CLLocationCoordinate2D(latitude: 51.524776, longitude: -0.133583),
        "Science Library": CLLocationCoordinate2D(latitude: 51.5235, longitude: -0.1329),
        "Student Centre": CLLocationCoordinate2D(latitude: 51.5252, longitude: -0.1328),
        "Institute of Education Library": CLLocationCoordinate2D(
            latitude: 51.5226, longitude: -0.1295),
        "Cruciform Hub": CLLocationCoordinate2D(latitude: 51.524776, longitude: -0.133583),
        "SSEES Library": CLLocationCoordinate2D(latitude: 51.525371, longitude: -0.131646),
        "Great Ormond Street Institute of Child Health Library": CLLocationCoordinate2D(
            latitude: 51.523166, longitude: -0.120194),
        "UCL Bartlett Library": CLLocationCoordinate2D(latitude: 51.5265, longitude: -0.1295),
        "Language & Speech Science Library": CLLocationCoordinate2D(
            latitude: 51.5257, longitude: -0.1244),
        "The Joint Library of Ophthalmology": CLLocationCoordinate2D(
            latitude: 51.5265, longitude: -0.0887),
        "School of Pharmacy Library": CLLocationCoordinate2D(
            latitude: 51.525196, longitude: -0.121928),
        "Institute of Archaeology Library": CLLocationCoordinate2D(
            latitude: 51.5254, longitude: -0.1313),
        "Royal Free Hospital Medical Library": CLLocationCoordinate2D(
            latitude: 51.5526, longitude: -0.1672),
        "Graduate Hub": CLLocationCoordinate2D(latitude: 51.5245, longitude: -0.1341),
        "Queen Square Library - Neurology": CLLocationCoordinate2D(
            latitude: 51.52184, longitude: -0.12282),
        "Institute of Orthopaedics Library": CLLocationCoordinate2D(
            latitude: 51.6177, longitude: -0.3027),
        "UCL East Library (Marshgate)": CLLocationCoordinate2D(
            latitude: 51.5386, longitude: -0.0209),

        // Computer clusters and ISD spaces
        "Anatomy Hub": CLLocationCoordinate2D(latitude: 51.5241, longitude: -0.1339),
        "Torrington Place": CLLocationCoordinate2D(latitude: 51.521906, longitude: -0.134348),
        "Foster Court": CLLocationCoordinate2D(latitude: 51.5235, longitude: -0.1320),
        "Christopher Ingold Building": CLLocationCoordinate2D(
            latitude: 51.525193, longitude: -0.132246),
        "Bedford Way Buildings": CLLocationCoordinate2D(latitude: 51.5226, longitude: -0.1281),
        "Chadwick Building": CLLocationCoordinate2D(latitude: 51.5241, longitude: -0.1310),
        "Gordon Square and Taviton Street": CLLocationCoordinate2D(
            latitude: 51.5243, longitude: -0.1309),
        "GOSICH - Wolfson Centre": CLLocationCoordinate2D(
            latitude: 51.523166, longitude: -0.120194),
        "Chandler House": CLLocationCoordinate2D(latitude: 51.525952, longitude: -0.122779),
        "Roberts Building": CLLocationCoordinate2D(latitude: 51.522995, longitude: -0.132153),
        "Pearson Building": CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.1336),
        "Gordon House": CLLocationCoordinate2D(latitude: 51.5245, longitude: -0.1307),
        "Bentham House": CLLocationCoordinate2D(latitude: 51.5254, longitude: -0.1313),
        "SENIT Suite": CLLocationCoordinate2D(latitude: 51.5219, longitude: -0.1340),

        // Other campuses and buildings
        "East Campus - Marshgate": CLLocationCoordinate2D(latitude: 51.5403, longitude: -0.0123),
        "Marshgate - Hosts": CLLocationCoordinate2D(latitude: 51.5403, longitude: -0.0123),
        "East Campus - Pool St": CLLocationCoordinate2D(latitude: 51.5403, longitude: -0.0123),
        "40 Bernard Street": CLLocationCoordinate2D(latitude: 51.5267, longitude: -0.1277),
        "30 Guildford Street": CLLocationCoordinate2D(latitude: 51.5225, longitude: -0.1202),
        "UCL Geography NWW110A": CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.1336),

        // Additional buildings from UCL API's roombookings/rooms endpoint
        "Medical School Building": CLLocationCoordinate2D(
            latitude: 51.523504, longitude: -0.134937),
        "Birkbeck Malet Street": CLLocationCoordinate2D(
            latitude: 51.5218725, longitude: -0.1305394),
        "Rockefeller Building": CLLocationCoordinate2D(latitude: 51.5235, longitude: -0.1349),
        "Cruciform Building": CLLocationCoordinate2D(latitude: 51.524776, longitude: -0.133583),
        "Wilkins Building": CLLocationCoordinate2D(latitude: 51.524776, longitude: -0.133583),
        "Darwin Building": CLLocationCoordinate2D(latitude: 51.5226, longitude: -0.1323),
        "Drayton House": CLLocationCoordinate2D(latitude: 51.5226, longitude: -0.1305),
        "Engineering Building": CLLocationCoordinate2D(latitude: 51.5229, longitude: -0.1317),
        "Engineering Front Building": CLLocationCoordinate2D(latitude: 51.5229, longitude: -0.1317),
        "Malet Place Engineering Building": CLLocationCoordinate2D(
            latitude: 51.5229, longitude: -0.1317),
        "Torrington Place (1-19)": CLLocationCoordinate2D(
            latitude: 51.521906, longitude: -0.134348),
        "UCL at Here East": CLLocationCoordinate2D(latitude: 51.5469, longitude: -0.0225),
        "UCL East - One Pool Street": CLLocationCoordinate2D(latitude: 51.5403, longitude: -0.0123),
        "UCL East - Marshgate": CLLocationCoordinate2D(latitude: 51.5403, longitude: -0.0123),

        // Bloomsbury area
        "Bloomsbury": CLLocationCoordinate2D(latitude: 51.522121, longitude: -0.129420),
    ]

    /// Building alias mapping - Map different names to standard building names
    static let buildingAliases: [String: String] = [
        // Library aliases
        "Main Library": "Main Library",
        "Science Library": "Science Library",
        "UCL Institute of Education Library": "Institute of Education Library",
        "IOE Library": "Institute of Education Library",
        "Cruciform Hub": "Cruciform Hub",
        "SSEES Library": "SSEES Library",
        "Great Ormond Street Institute of Child Health Library":
            "Great Ormond Street Institute of Child Health Library",
        "GOSICH Library": "Great Ormond Street Institute of Child Health Library",
        "Child Health Library": "Great Ormond Street Institute of Child Health Library",
        "Bartlett Library": "UCL Bartlett Library",
        "Language & Speech Science Library": "Language & Speech Science Library",
        "Royal Free Medical Library": "Royal Free Hospital Medical Library",
        "School of Pharmacy Library": "School of Pharmacy Library",
        "UCL East Library": "UCL East Library (Marshgate)",
        "UCL Student Centre": "Student Centre",
        "Institute of Archaeology Library": "Institute of Archaeology Library",
        "Joint Library of Ophthalmology": "The Joint Library of Ophthalmology",
        "Institute of Ophthalmology": "The Joint Library of Ophthalmology",
        "Queen Square Library": "Queen Square Library - Neurology",
        "Graduate Hub": "Graduate Hub",

        // Building aliases
        "Cruciform": "Cruciform Building",
        "Cruciform Building": "Cruciform Building",
        "Wilkins": "Wilkins Building",
        "Main Building": "Wilkins Building",
        "Darwin": "Darwin Building",
        "Drayton": "Drayton House",
        "Engineering": "Engineering Building",
        "Engineering Front": "Engineering Front Building",
        "MPEB": "Malet Place Engineering Building",
        "Malet Place": "Malet Place Engineering Building",
        "Torrington": "Torrington Place",
        "Torrington Place": "Torrington Place",
        "Here East": "UCL at Here East",
        "One Pool Street": "UCL East - One Pool Street",
        "Pool Street": "UCL East - One Pool Street",
        "Marshgate": "UCL East - Marshgate",
        "UCL East Marshgate": "UCL East - Marshgate",

        // Computer cluster aliases
        "Anatomy": "Anatomy Hub",
        "Foster": "Foster Court",
        "Christopher Ingold": "Christopher Ingold Building",
        "Bedford Way": "Bedford Way Buildings",
        "Chadwick": "Chadwick Building",
        "Gordon Square": "Gordon Square and Taviton Street",
        "Taviton Street": "Gordon Square and Taviton Street",
        "Wolfson Centre": "GOSICH - Wolfson Centre",
        "Chandler": "Chandler House",
        "Roberts": "Roberts Building",
        "Pearson": "Pearson Building",
        "Gordon House": "Gordon House",
        "Bentham": "Bentham House",
        "SENIT": "SENIT Suite",
    ]

    /// Get building coordinates
    /// - Parameter buildingName: Building name
    /// - Returns: Coordinates, returns UCL main campus coordinates if not found
    static func getCoordinate(for buildingName: String) -> CLLocationCoordinate2D {
        // Clean name - Remove prefix and extra spaces
        let cleanedName = cleanBuildingName(buildingName)

        // 1. Try using alias mapping
        if let standardName = mapBuildingAlias(cleanedName),
            let coordinate = buildingCoordinates[standardName]
        {
            return coordinate
        }

        // 2. Try direct match
        if let coordinate = buildingCoordinates[cleanedName] {
            return coordinate
        }

        // 3. Try partial match - First check if it contains complete building name
        for (key, coordinate) in buildingCoordinates {
            if cleanedName.lowercased().contains(key.lowercased()) {
                return coordinate
            }
        }

        // 4. Try partial match - Check if building name contains keywords
        for (key, coordinate) in buildingCoordinates {
            if key.lowercased().contains(cleanedName.lowercased()) {
                return coordinate
            }
        }

        // 5. Try extracting location keywords and matching
        let locationKeywords = extractLocationKeywords(from: cleanedName)
        for keyword in locationKeywords {
            for (key, coordinate) in buildingCoordinates {
                if key.lowercased().contains(keyword.lowercased()) {
                    return coordinate
                }
            }
        }

        // Default returns UCL main campus coordinates
        return CLLocationCoordinate2D(latitude: 51.5248, longitude: -0.1336)
    }

    /// Clean building name
    /// - Parameter name: Original name
    /// - Returns: Cleaned name
    private static func cleanBuildingName(_ name: String) -> String {
        return
            name
            .replacingOccurrences(of: "Library: ", with: "")
            .replacingOccurrences(of: "[LIB]", with: "")
            .replacingOccurrences(of: "[ISD]", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Map building alias to standard name
    /// - Parameter name: Building name
    /// - Returns: Standard name, returns nil if no mapping
    private static func mapBuildingAlias(_ name: String) -> String? {
        // Direct lookup mapping
        if let mappedName = buildingAliases[name] {
            return mappedName
        }

        // Try partial match
        for (key, value) in buildingAliases {
            if name.lowercased().contains(key.lowercased()) {
                return value
            }
        }

        return nil
    }

    /// Extract location keywords from name
    /// - Parameter name: Building name
    /// - Returns: Keywords array
    private static func extractLocationKeywords(from name: String) -> [String] {
        var keywords: [String] = []

        // Split name and extract possible location keywords
        let components = name.components(separatedBy: CharacterSet(charactersIn: " -:,"))
        for component in components {
            let cleaned = component.trimmingCharacters(in: .whitespaces)
            if cleaned.count > 3 {  // Ignore too short words
                keywords.append(cleaned)
            }
        }

        return keywords
    }
}
