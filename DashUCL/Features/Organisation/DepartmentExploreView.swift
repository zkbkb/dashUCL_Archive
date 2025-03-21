import SwiftUI

/// Department Explore View - Combines department detail card with UCL organization hierarchy view
struct DepartmentExploreView: View {
    // Currently displayed organization unit
    @State var currentUnit: UCLOrganizationUnit
    // Record set of expanded department IDs
    @State private var expandedUnitIDs: Set<String> = []
    // Navigation manager
    @EnvironmentObject private var navigationManager: NavigationManager
    // Organization repository
    @StateObject private var repository = UCLOrganizationRepository.shared
    // View model for loading unit-related data
    @StateObject private var viewModel = OrganizationUnitViewModel()
    // State variable to control whether initial expansion has been handled
    @State private var hasProcessedInitialExpand = false
    // Environment variables
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // Background color - Use iOS dark mode standard dark gray
            (colorScheme == .dark
                ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
                : Color(UIColor.systemBackground))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top department card
                ScrollView {
                    VStack(spacing: 16) {
                        // Department information card
                        DepartmentCardView(
                            unit: currentUnit, hierarchyPath: viewModel.hierarchyPath)

                        Divider()
                            .padding(.top, 4)

                        // UCL organizational structure section
                        organizationStructureView
                    }
                    .padding()
                }
            }
            .navigationTitle("Department Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // Load current unit data
                viewModel.loadData(for: currentUnit)
                // Expand path
                expandPathToCurrentUnit()
            }
        }
    }

    // Organizational structure view section
    private var organizationStructureView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UCL Structure")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Tap to view details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Academic structure
            academicStructureView

            // Administrative structure
            administrativeStructureView
        }
    }

    // Academic structure
    private var academicStructureView: some View {
        VStack(spacing: 0) {
            OutlineSectionHeader(title: "Academic Structure", iconName: "building.columns")
                .padding(.top, 8)

            // Tree structure of faculties and their departments
            ForEach(repository.faculties) { faculty in
                facultyRow(for: faculty)

                // If expanded, show sub-departments
                if expandedUnitIDs.contains(faculty.id), let departments = faculty.children {
                    ForEach(Array(departments.enumerated()), id: \.element.id) {
                        index, department in
                        departmentRow(for: department, isLastChild: index == departments.count - 1)
                    }
                }
            }
        }
    }

    // Administrative structure
    private var administrativeStructureView: some View {
        VStack(spacing: 0) {
            OutlineSectionHeader(title: "Administrative Structure", iconName: "gear")
                .padding(.top, 16)

            // Administrative department display
            if let adminDivision = repository.getUnit(byID: "ADMIN_DIV") {
                adminSectionView(for: adminDivision)
            } else {
                Text("No administrative units found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    // Faculty row
    private func facultyRow(for faculty: UCLOrganizationUnit) -> some View {
        OutlineFacultyRow(
            faculty: faculty,
            isExpanded: expandedUnitIDs.contains(faculty.id),
            onTap: {
                // Update current unit instead of navigating
                updateCurrentUnit(faculty)
            },
            onToggle: {
                withAnimation(.spring(response: 0.3)) {
                    if expandedUnitIDs.contains(faculty.id) {
                        expandedUnitIDs.remove(faculty.id)
                    } else {
                        expandedUnitIDs.insert(faculty.id)
                    }
                }
            }
        )
    }

    // Department row
    private func departmentRow(for department: UCLOrganizationUnit, isLastChild: Bool = false)
        -> some View
    {
        OutlineDepartmentRow(
            department: department,
            onTap: {
                // Update current unit instead of navigating
                updateCurrentUnit(department)
            },
            isLastChild: isLastChild
        )
    }

    // Administrative section view
    private func adminSectionView(for adminDivision: UCLOrganizationUnit) -> some View {
        VStack(spacing: 0) {
            // Administrative department top directory row
            OutlineFacultyRow(
                faculty: adminDivision,
                isExpanded: expandedUnitIDs.contains(adminDivision.id),
                onTap: {
                    // Update current unit instead of navigating
                    updateCurrentUnit(adminDivision)
                },
                onToggle: {
                    withAnimation(.spring(response: 0.3)) {
                        if expandedUnitIDs.contains(adminDivision.id) {
                            expandedUnitIDs.remove(adminDivision.id)
                        } else {
                            expandedUnitIDs.insert(adminDivision.id)
                        }
                    }
                }
            )

            // If expanded, show main administrative department category, add level lines
            if expandedUnitIDs.contains(adminDivision.id),
                let adminCategories = adminDivision.children
            {
                ForEach(Array(adminCategories.enumerated()), id: \.element.id) { index, category in
                    adminCategoryRow(for: category, isLastChild: index == adminCategories.count - 1)
                }
            }
        }
    }

    // Administrative department category row view
    private func adminCategoryRow(for category: UCLOrganizationUnit, isLastChild: Bool = false)
        -> some View
    {
        VStack(spacing: 0) {
            // Use new sub-category row component, ensure consistency with UCLHierarchyView visual
            OutlineSubCategoryRow(
                unit: category,
                isExpanded: expandedUnitIDs.contains(category.id),
                isLastChild: isLastChild,
                onTap: {
                    // Update current unit instead of navigating
                    updateCurrentUnit(category)
                },
                onToggle: {
                    withAnimation(.spring(response: 0.3)) {
                        if expandedUnitIDs.contains(category.id) {
                            expandedUnitIDs.remove(category.id)
                        } else {
                            expandedUnitIDs.insert(category.id)
                        }
                    }
                }
            )

            // If expanded, show specific departments under that category
            if expandedUnitIDs.contains(category.id), let units = category.children {
                ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                    // Use same style as academic departments to display administrative departments
                    departmentRow(for: unit, isLastChild: index == units.count - 1)
                }
            }
        }
    }

    // Update current displayed unit
    private func updateCurrentUnit(_ unit: UCLOrganizationUnit) {
        withAnimation {
            currentUnit = unit
            // Load new unit data
            viewModel.loadData(for: unit)
            // Automatically scroll to top
            // Note: In actual implementation, additional ScrollViewReader may be needed to scroll to top
        }
    }

    // Expand path to current unit
    private func expandPathToCurrentUnit() {
        guard !hasProcessedInitialExpand else { return }

        // Find unit's parent path
        var current = currentUnit
        var path: [String] = [current.id]

        // Trace back to parent units to build complete path
        while let parentID = current.parentID, let parent = repository.getUnit(byID: parentID) {
            path.append(parent.id)
            current = parent
        }

        // Add all unit IDs in the path to expandedUnitIDs set
        withAnimation(.spring(response: 0.3)) {
            path.forEach { expandedUnitIDs.insert($0) }
        }

        hasProcessedInitialExpand = true
    }
}

/// Department card view - Displayed at the top current department card
struct DepartmentCardView: View {
    let unit: UCLOrganizationUnit
    let hierarchyPath: [UCLOrganizationUnit]
    @StateObject private var repository = UCLOrganizationRepository.shared

    var body: some View {
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

            // If it's UCL root organization, show UCL introduction
            if unit.id == "UCL" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(
                        "University College London (UCL) is a multi-disciplinary university located in London, UK. Founded in 1826, it is one of the top-ranked universities globally, organized into 11 faculties with various departments, institutes and research centers."
                    )
                    .font(.body)
                    .foregroundColor(.primary)
                }
            }
            // Show organization hierarchy path (breadcrumbs), only display for non-UCL root organization
            else if hierarchyPath.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Organization")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 0) {
                        Text("UCL")
                            .foregroundColor(.blue)

                        if hierarchyPath.count > 1 {
                            ForEach(hierarchyPath.dropFirst().dropLast(), id: \.id) { pathUnit in
                                Text(" > ")
                                    .foregroundColor(.secondary)

                                Text(pathUnit.name)
                                    .foregroundColor(.blue)
                            }

                            Text(" > ")
                                .foregroundColor(.secondary)

                            Text(unit.name)
                                .foregroundColor(.primary)
                        }
                    }
                    .font(.subheadline)
                }
            }

            // Add a simple description information area (if any)
            if let description = getUnitDescription(for: unit), unit.id != "UCL" {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    // Get department description information (simulated data)
    private func getUnitDescription(for unit: UCLOrganizationUnit) -> String? {
        // Simple simulated some description information
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

/// Sub-category row component - Specifically for administrative department category, etc., with more obvious level connection lines
struct OutlineSubCategoryRow: View {
    let unit: UCLOrganizationUnit
    let isExpanded: Bool
    let isLastChild: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Indent and level connection line display
                ZStack(alignment: .leading) {
                    // Vertical connection line - Based on whether it's the last child, whether to continue extending downward
                    // If it's the last child, the connection line only extends half height
                    if !isLastChild {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                            .padding(.leading, 30)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1, height: 20)
                            .padding(.leading, 30)
                            .padding(.top, -20)
                    }

                    // Horizontal connection line
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 15, height: 1)
                        .padding(.leading, 15)
                }
                .frame(width: 38, height: 40)

                // Expand/collapse button
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                // Type color identification
                RoundedRectangle(cornerRadius: 3)
                    .fill(unit.type.color)
                    .frame(width: 5, height: 24)
                    .padding(.trailing, 4)

                // Sub-category information and navigation
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(unit.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        if let children = unit.children {
                            Text("\(children.count) units")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color.clear)
        }
    }
}

#Preview {
    NavigationStack {
        if let computerScience = UCLOrganizationRepository.shared.getUnit(byID: "COMPS_ENG") {
            DepartmentExploreView(currentUnit: computerScience)
                .environmentObject(NavigationManager.shared)
        } else {
            Text("Unit not found")
        }
    }
}
