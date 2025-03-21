import SwiftUI

/// UCL Organization Structure Browser View - Provides hierarchical browsing of UCL faculty structure
struct UCLHierarchyView: View {
    // MARK: - Properties
    @StateObject private var repository = UCLOrganizationRepository.shared
    @State private var searchText = ""
    @State private var showCategoryFilter = false
    @State private var selectedCategoryFilter: UCLOrganizationUnit.OrganizationType? = nil
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.colorScheme) var colorScheme

    // Map storing expanded states, using ID as key
    @State private var expandedFaculties: Set<String> = []
    // Department IDs to auto-expand at initialization
    @State private var targetUnitID: String? = nil

    // MARK: - View Body
    var body: some View {
        ZStack {
            // Background color
            backgroundView

            VStack(spacing: 0) {
                // Search bar
                searchBarView

                // Category filter
                if showCategoryFilter {
                    filterCategoriesView
                }

                // Separator line
                dividerView

                // Content area
                if searchText.isEmpty && selectedCategoryFilter == nil {
                    // Outline view grouped by faculty
                    outlineContentView
                } else {
                    // Search or filter results
                    searchResultsView
                }
            }
        }
        .navigationTitle("UCL Structure")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            checkForTargetUnit()
        }
    }

    // MARK: - Subviews

    // Background view
    private var backgroundView: some View {
        (colorScheme == .dark
            ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
            : Color(UIColor.systemBackground))
            .ignoresSafeArea()
    }

    // Search bar view
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24)
                    .opacity(0.8)

                TextField("Search departments, schools...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.95))
            }

            // Filter button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showCategoryFilter.toggle()
                }
            } label: {
                Image(
                    systemName:
                        "line.3.horizontal.decrease.circle\(showCategoryFilter ? ".fill" : "")"
                )
                .font(.system(size: 24))
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // Category filter view
    private var filterCategoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All options
                CategoryFilterPill(
                    title: "All",
                    isSelected: selectedCategoryFilter == nil,
                    color: .blue
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategoryFilter = nil
                    }
                }

                // Type options
                ForEach(UCLOrganizationUnit.OrganizationType.allCases, id: \.self) { category in
                    CategoryFilterPill(
                        title: category.rawValue,
                        isSelected: selectedCategoryFilter == category,
                        color: category.color
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategoryFilter = category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // Separator line view
    private var dividerView: some View {
        Divider()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.2), Color.gray.opacity(0.1),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal)
    }

    // Outline content view
    private var outlineContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Display UCL top-level organizational structure
                organizationHeaderView

                // Academic structure section
                academicStructureView

                // Administrative structure section
                administrativeStructureView

                Spacer(minLength: 40)
            }
        }
    }

    // Organization structure title view
    private var organizationHeaderView: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 2) {
                Text("UCL Organizational Structure")
                    .font(.headline)
                    .padding(.bottom, 8)

                Text(
                    "UCL is organized into 11 faculties, each containing departments, institutes and research centers."
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // Academic structure view
    private var academicStructureView: some View {
        VStack(spacing: 0) {
            OutlineSectionHeader(title: "Academic Structure", iconName: "building.columns")
                .padding(.top, 16)

            // Assemble faculty and department tree structure
            ForEach(repository.faculties) { faculty in
                facultyRow(for: faculty)

                // If expanded, display sub-departments
                if expandedFaculties.contains(faculty.id), let departments = faculty.children {
                    ForEach(Array(departments.enumerated()), id: \.element.id) {
                        index, department in
                        departmentRow(for: department, isLastChild: index == departments.count - 1)
                    }
                }
            }
        }
    }

    // Single faculty row
    private func facultyRow(for faculty: UCLOrganizationUnit) -> some View {
        OutlineFacultyRow(
            faculty: faculty,
            isExpanded: expandedFaculties.contains(faculty.id),
            onTap: {
                navigationManager.navigateToDetail(.departmentExplore(id: faculty.id))
            },
            onToggle: {
                withAnimation(.spring(response: 0.3)) {
                    if expandedFaculties.contains(faculty.id) {
                        expandedFaculties.remove(faculty.id)
                    } else {
                        expandedFaculties.insert(faculty.id)
                    }
                }
            }
        )
    }

    // Single department row
    private func departmentRow(for department: UCLOrganizationUnit, isLastChild: Bool = false)
        -> some View
    {
        OutlineDepartmentRow(
            department: department,
            onTap: {
                navigationManager.navigateToDetail(.departmentExplore(id: department.id))
            },
            isLastChild: isLastChild
        )
    }

    // Administrative structure view
    private var administrativeStructureView: some View {
        VStack(spacing: 0) {
            OutlineSectionHeader(title: "Administrative Structure", iconName: "gear")
                .padding(.top, 16)

            // Get total directory of administrative departments
            if let adminDivision = repository.getUnit(byID: "ADMIN_DIV") {
                adminSectionView(for: adminDivision)
            } else {
                // If total directory not found, use original filtering method to display administrative units
                let adminUnits = repository.organizationMap.values.filter { unit in
                    unit.type == .administrative
                        || (unit.type == .other && isAdministrativeByName(unit.name))
                }

                if !adminUnits.isEmpty {
                    // Group and display administrative units
                    ForEach(groupAdministrativeUnits(adminUnits), id: \.key) { group in
                        adminGroupRow(title: group.key, units: group.value)
                    }
                } else {
                    Text("No administrative units found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }

    // 行政部门部分视图
    private func adminSectionView(for adminDivision: UCLOrganizationUnit) -> some View {
        VStack(spacing: 0) {
            // 行政部门顶级目录行
            OutlineFacultyRow(
                faculty: adminDivision,
                isExpanded: expandedFaculties.contains(adminDivision.id),
                onTap: {
                    navigationManager.navigateToDetail(.departmentExplore(id: adminDivision.id))
                },
                onToggle: {
                    withAnimation(.spring(response: 0.3)) {
                        if expandedFaculties.contains(adminDivision.id) {
                            expandedFaculties.remove(adminDivision.id)
                        } else {
                            expandedFaculties.insert(adminDivision.id)
                        }
                    }
                }
            )

            // 如果展开，显示主要行政部门类别
            if expandedFaculties.contains(adminDivision.id),
                let adminCategories = adminDivision.children
            {
                ForEach(Array(adminCategories.enumerated()), id: \.element.id) { index, category in
                    adminCategoryRow(for: category, isLastChild: index == adminCategories.count - 1)
                }
            }
        }
    }

    // 行政部门类别行视图
    private func adminCategoryRow(for category: UCLOrganizationUnit, isLastChild: Bool = false)
        -> some View
    {
        VStack(spacing: 0) {
            // 使用新的子分类行组件
            UCLHierarchyOutlineSubCategoryRow(
                unit: category,
                isExpanded: expandedFaculties.contains(category.id),
                isLastChild: isLastChild,
                onTap: {
                    navigationManager.navigateToDetail(.departmentExplore(id: category.id))
                },
                onToggle: {
                    withAnimation(.spring(response: 0.3)) {
                        if expandedFaculties.contains(category.id) {
                            expandedFaculties.remove(category.id)
                        } else {
                            expandedFaculties.insert(category.id)
                        }
                    }
                }
            )

            // 如果展开，显示该类别下的具体部门
            if expandedFaculties.contains(category.id), let units = category.children {
                ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                    // 使用与学术部门相同的样式显示行政部门
                    departmentRow(for: unit, isLastChild: index == units.count - 1)
                }
            }
        }
    }

    // 根据名称判断是否为行政部门
    private func isAdministrativeByName(_ name: String) -> Bool {
        let name = name.lowercased()
        return name.contains("office") || name.contains("service") || name.contains("division")
            || name.contains("registry") || name.contains("administration")
            || name.contains("human resources") || name.contains("finance")
            || name.contains("library")
    }

    // 对行政单位进行分组
    private func groupAdministrativeUnits(_ units: [UCLOrganizationUnit]) -> [(
        key: String, value: [UCLOrganizationUnit]
    )] {
        let groups: [String: [UCLOrganizationUnit]] = Dictionary(grouping: units) { unit in
            // 根据单位名称确定分组
            if unit.name.contains("Office of the President") || unit.name.contains("Provost") {
                return "Office of the President and Provost"
            } else if unit.name.contains("ISD") || unit.name.contains("Information Services") {
                return "Information Services Division"
            } else if unit.name.contains("Estates") || unit.name.contains("Facilities") {
                return "Estates and Facilities Division"
            } else {
                return "Other Support Services"
            }
        }

        // 转换为排序后的数组
        return groups.sorted { $0.key < $1.key }
    }

    // 行政部门组行视图
    private func adminGroupRow(title: String, units: [UCLOrganizationUnit]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 组标题
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground).opacity(0.3))

            // 组内部门
            ForEach(units.sorted(by: { $0.name < $1.name })) { unit in
                departmentRow(for: unit)
            }

            Divider()
                .padding(.leading)
        }
    }

    // 检查是否需要自动展开到特定部门
    private func checkForTargetUnit() {
        if let unitID = navigationManager.targetOrganizationUnitID {
            expandPathToUnit(unitID: unitID)
            navigationManager.targetOrganizationUnitID = nil
        }
    }

    // 展开路径到指定部门
    private func expandPathToUnit(unitID: String) {
        // 找到部门
        guard let unit = repository.getUnit(byID: unitID) else { return }

        // 构建路径
        var current = unit
        var path: [String] = [current.id]

        // 向上追溯父级单位，构建完整路径
        while let parentID = current.parentID, let parent = repository.getUnit(byID: parentID) {
            path.append(parent.id)
            current = parent
        }

        // 将路径上的所有单位ID添加到expandedFaculties集合中
        path.forEach { expandedFaculties.insert($0) }

        // 设置目标单位，用于滚动到视图
        targetUnitID = unitID
    }

    // 搜索结果视图
    private var searchResultsView: some View {
        let results = filteredResults

        return Group {
            if results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try another search term or filter")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Text("Found \(results.count) results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)

                    ForEach(results) { unit in
                        // 使用按钮替代NavigationLink，避免滑动效果
                        Button {
                            // 直接使用navigationManager导航
                            navigationManager.navigateToDetail(.departmentExplore(id: unit.id))
                        } label: {
                            HierarchySearchResultRow(unit: unit)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // 返回按钮
    private var backButton: some View {
        Button(action: {
            // 直接返回到搜索页面
            navigationManager.navigateToRoot()
            navigationManager.navigateTo(.search)
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                Text("Back")
            }
        }
    }

    // MARK: - Helper Methods

    // 根据搜索文本和选择的分类过滤结果
    private var filteredResults: [UCLOrganizationUnit] {
        var results: [UCLOrganizationUnit]

        // 先应用搜索
        if !searchText.isEmpty {
            results = repository.searchUnits(query: searchText)
        } else {
            // 如果没有搜索词但有分类筛选，使用所有单位
            results = Array(repository.organizationMap.values)
        }

        // 再应用分类筛选
        if let category = selectedCategoryFilter {
            results = results.filter { $0.type == category }
        }

        return results
    }
}

// MARK: - 大纲组件

/// 大纲部分标题
struct OutlineSectionHeader: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .imageScale(.medium)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground).opacity(0.5))
    }
}

/// 学院行组件
struct OutlineFacultyRow: View {
    let faculty: UCLOrganizationUnit
    let isExpanded: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // 展开/折叠按钮 - 添加更明显的边界
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .frame(width: 22, height: 22)

                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 4)

                // 类型颜色标识 - 稍微粗一点
                RoundedRectangle(cornerRadius: 3)
                    .fill(faculty.type.color)
                    .frame(width: 6, height: 26)
                    .padding(.trailing, 6)
                    .padding(.leading, 4)

                // 学院信息和导航
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(faculty.name.replacingOccurrences(of: " Faculty", with: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if let children = faculty.children {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)

                                Text("\(children.count) departments")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(Color.clear)

            // 添加一条细线，视觉上更加区分不同的学院
            if !isExpanded {
                Divider()
                    .padding(.horizontal)
                    .opacity(0.5)
            }
        }
    }
}

/// 部门行组件
struct OutlineDepartmentRow: View {
    let department: UCLOrganizationUnit
    let onTap: () -> Void
    // 添加是否为最后一个子项的标志，用于决定连接线的绘制方式
    var isLastChild: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // 缩进和更优雅的层级连接线
                ZStack(alignment: .leading) {
                    // 垂直连接线 - 如果不是最后一个子项，则延伸到下一个项目
                    if !isLastChild {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                            .padding(.leading, 30)
                    } else {
                        // 如果是最后一个子项，垂直线只延伸到一半
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1, height: 14)
                            .padding(.leading, 30)
                            .padding(.top, -10)  // 调整位置使其连接到上方
                    }

                    // 水平连接线
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 15, height: 1)
                        .padding(.leading, 15)
                }
                .frame(width: 38, height: 24)

                // 类型颜色标识
                RoundedRectangle(cornerRadius: 2)
                    .fill(department.type.color)
                    .frame(width: 3, height: 20)
                    .padding(.trailing, 4)

                // 部门名称
                Text(department.name)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 搜索结果行
struct HierarchySearchResultRow: View {
    let unit: UCLOrganizationUnit
    @StateObject private var repository = UCLOrganizationRepository.shared
    @State private var parentUnit: UCLOrganizationUnit?
    @State private var hierarchyPath: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // 类型颜色标识
                RoundedRectangle(cornerRadius: 2)
                    .fill(unit.type.color)
                    .frame(width: 4, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(unit.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 显示组织层级路径
            if !hierarchyPath.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(hierarchyPath.joined(separator: " > "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 12)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            loadHierarchyPath()
        }
    }

    private func loadHierarchyPath() {
        // 获取父级单位并构建层级路径
        var current = unit
        var path: [String] = []

        while let parentID = current.parentID, let parent = repository.getUnit(byID: parentID) {
            path.insert(parent.name, at: 0)
            current = parent

            // 限制层级深度，避免过长
            if path.count >= 2 {
                break
            }
        }

        hierarchyPath = path
    }
}

/// 分类筛选器药丸
struct CategoryFilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
        .shadow(color: isSelected ? color.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
}

/// 子分类行组件 - 专为行政部门类别等使用，有更明显的层级连接线
struct UCLHierarchyOutlineSubCategoryRow: View {
    let unit: UCLOrganizationUnit
    let isExpanded: Bool
    let isLastChild: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // 缩进和层级连接线显示
                ZStack(alignment: .leading) {
                    // 竖直连接线 - 根据是否是最后一个子项决定是否继续向下延伸
                    if !isLastChild {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                            .padding(.leading, 30)
                    } else {
                        // 如果是最后一个子项，连接线只延伸一半高度
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1, height: 20)
                            .padding(.leading, 30)
                            .padding(.top, -20)
                    }

                    // 水平连接线
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 15, height: 1)
                        .padding(.leading, 15)
                }
                .frame(width: 38, height: 40)

                // 展开/折叠按钮
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                // 类型颜色标识
                RoundedRectangle(cornerRadius: 3)
                    .fill(unit.type.color)
                    .frame(width: 5, height: 24)
                    .padding(.trailing, 4)

                // 子分类信息和导航
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
