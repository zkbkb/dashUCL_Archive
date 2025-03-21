import SwiftUI
import UIKit

/// Organization Unit Detail View
struct OrganizationUnitDetailView: View {
    let unit: UCLOrganizationUnit
    @StateObject private var viewModel = OrganizationUnitViewModel()
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background color - Use iOS dark mode standard dark gray (RGB: 28, 28, 30)
            (colorScheme == .dark
                ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
                : Color(UIColor.systemBackground))
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Unit information card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(unit.type.color)
                                .frame(width: 24, height: 24)

                            Text(unit.type.rawValue)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }

                        Text(unit.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Divider()

                        // Display parent unit path (breadcrumbs)
                        if viewModel.parentUnit != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Organization")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 0) {
                                    Button(action: {
                                        // Navigate to top level
                                        if let root = viewModel.rootUnit {
                                            viewModel.selectedUnit = root
                                        }
                                    }) {
                                        Text("UCL")
                                            .foregroundColor(.blue)
                                    }

                                    if viewModel.hierarchyPath.count > 1 {
                                        ForEach(
                                            viewModel.hierarchyPath.dropFirst().dropLast(), id: \.id
                                        ) { pathUnit in
                                            Text(" > ")
                                                .foregroundColor(.secondary)

                                            Button(action: {
                                                viewModel.selectedUnit = pathUnit
                                            }) {
                                                Text(pathUnit.name)
                                                    .foregroundColor(.blue)
                                            }
                                        }

                                        Text(" > ")
                                            .foregroundColor(.secondary)

                                        Text(unit.name)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .font(.subheadline)
                            }

                            Divider()
                        }

                        // No longer display unit ID
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Add a simple description area (if available)
                    if let description = getUnitDescription(for: unit) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Child units list
                    if let children = unit.children, !children.isEmpty {
                        Text("Sub-Units")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)

                        ForEach(children) { child in
                            OrganizationUnitRow(unit: child) {
                                viewModel.selectedUnit = child
                            }
                        }
                    }

                    // Sibling units (brothers)
                    if !viewModel.siblingUnits.isEmpty {
                        Text("Related Units")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)

                        ForEach(viewModel.siblingUnits) { sibling in
                            OrganizationUnitRow(unit: sibling, isSmaller: true) {
                                viewModel.selectedUnit = sibling
                            }
                        }
                    }

                    // Related personnel
                    if !viewModel.relatedPeople.isEmpty {
                        Text("People")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)

                        ForEach(viewModel.relatedPeople) { person in
                            PersonResultRow(person: person)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(unit.name)
        .onAppear {
            viewModel.loadData(for: unit)
        }
        .onChange(of: viewModel.selectedUnit) { _, newUnit in
            if let selectedUnit = newUnit, selectedUnit.id != unit.id {
                // Use NavigationLink to programmatically trigger navigation
                viewModel.isNavigatingToSelectedUnit = true
            }
        }
        .navigationDestination(isPresented: $viewModel.isNavigatingToSelectedUnit) {
            if let selectedUnit = viewModel.selectedUnit {
                OrganizationUnitDetailView(unit: selectedUnit)
            }
        }
    }

    // Get department description (mock data, in actual application can be fetched from API or local storage)
    private func getUnitDescription(for unit: UCLOrganizationUnit) -> String? {
        // Here you can add some test description for the main department
        // In actual application, this information should be fetched from backend API or stored in local data
        let descriptions: [String: String] = [
            "COMPS_ENG":
                "The Department of Computer Science at UCL is one of the largest computer science departments in the UK. It was established in 1980 and conducts world-leading research in areas including artificial intelligence, software systems, and human-computer interaction.",

            "ART":
                "The Faculty of Arts and Humanities at UCL brings together scholars and students from across the spectrum of arts and humanities disciplines, fostering innovative research and interdisciplinary collaboration.",

            "BRN":
                "The Faculty of Brain Sciences undertakes world-leading research and teaching in areas including neurology, psychology, language sciences, and psychiatry. Its work addresses causes, cures and care for conditions that affect the brain and behavior.",

            "ENG":
                "The Faculty of Engineering Sciences combines innovative research with high-quality teaching across chemical, civil, electrical, mechanical and other engineering disciplines to address global challenges.",

            "LIF":
                "The Faculty of Life Sciences brings together expertise in genetics, cell biology, neuroscience and pharmacology to understand the fundamental processes of life and develop new approaches to combat disease.",
        ]

        return descriptions[unit.id]
    }
}

/// Organization Unit Row View
struct OrganizationUnitRow: View {
    let unit: UCLOrganizationUnit
    var isSmaller: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Vertical color bar
                Rectangle()
                    .fill(unit.type.color)
                    .frame(width: 4, height: isSmaller ? 40 : 50)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(unit.name)
                        .font(isSmaller ? .subheadline : .headline)
                        .foregroundColor(.primary)

                    Text(unit.type.rawValue)
                        .font(isSmaller ? .caption : .subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Organization Unit View Model
class OrganizationUnitViewModel: ObservableObject {
    @Published var parentUnit: UCLOrganizationUnit?
    @Published var rootUnit: UCLOrganizationUnit?
    @Published var siblingUnits: [UCLOrganizationUnit] = []
    @Published var relatedPeople: [Features.Search.PersonResult] = []
    @Published var hierarchyPath: [UCLOrganizationUnit] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedUnit: UCLOrganizationUnit?
    @Published var isNavigatingToSelectedUnit = false

    private let organizationRepository = UCLOrganizationRepository.shared
    private let networkService = NetworkService()

    func loadData(for unit: UCLOrganizationUnit) {
        Task { @MainActor in
            isLoading = true
            error = nil

            // Get parent unit
            parentUnit = organizationRepository.getParent(for: unit.id)

            // Get root unit
            rootUnit = organizationRepository.getUnit(byID: "UCL")

            // Get sibling units
            siblingUnits = organizationRepository.getSiblings(for: unit.id)

            // Build hierarchy path
            buildHierarchyPath(for: unit)

            // Get related people
            await loadRelatedPeople(unitName: unit.name)

            isLoading = false
        }
    }

    private func buildHierarchyPath(for unit: UCLOrganizationUnit) {
        var path: [UCLOrganizationUnit] = [unit]
        var currentUnit = unit

        // Trace back to higher levels
        while let parentID = currentUnit.parentID,
            let parent = organizationRepository.getUnit(byID: parentID)
        {
            path.insert(parent, at: 0)
            currentUnit = parent
        }

        hierarchyPath = path
    }

    @MainActor
    private func loadRelatedPeople(unitName: String) async {
        // Search related people via API
        do {
            // Use department name as search condition
            let endpoint = APIEndpoint.searchPeople(query: unitName)
            let data = try await networkService.fetchJSON(endpoint: endpoint)

            if let peopleData = data["people"] as? [[String: Any]] {
                // Filter people belonging to this unit
                self.relatedPeople =
                    peopleData
                    .filter { person in
                        let department = person["department"] as? String ?? ""
                        return department.lowercased().contains(unitName.lowercased())
                    }
                    .compactMap { personData -> Features.Search.PersonResult? in
                        guard let name = personData["name"] as? String,
                            let email = personData["email"] as? String
                        else { return nil }

                        return Features.Search.PersonResult(
                            id: email,
                            name: name,
                            email: email,
                            department: personData["department"] as? String ?? "",
                            position: personData["position"] as? String ?? ""
                        )
                    }
            }
        } catch {
            print("Error loading related people: \(error)")
        }
    }
}
