import SwiftUI

/// 用于从人员搜索结果中点击部门名称导航到部门详情的视图
struct DepartmentDetailLinkView: View {
    let departmentName: String
    @StateObject private var repository = UCLOrganizationRepository.shared
    @State private var departmentUnit: UCLOrganizationUnit?
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        Button {
            // 触发导航到组织结构视图
            navigationManager.navigateFromPersonToDepartment(departmentName: departmentName)

            // 打印调试信息
            if let unit = departmentUnit {
                print("点击部门: \(departmentName), 找到单位: \(unit.name), ID: \(unit.id)")
            } else {
                print("点击部门: \(departmentName), 但未在本地找到匹配单位，将由NavigationManager处理")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 10))

                Text(departmentName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(Capsule())
            .contentShape(Capsule())  // 确保整个胶囊都可点击
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 尝试查找部门（仅用于本地显示目的）
            findDepartment()
        }
    }

    private func findDepartment() {
        // 添加调试输出
        print("开始查找部门: \(departmentName)")

        // 特殊处理部门名称的常见前缀
        let cleanedName =
            departmentName
            .replacingOccurrences(of: "Dept of ", with: "")
            .replacingOccurrences(of: "Department of ", with: "")
            .replacingOccurrences(of: "School of ", with: "")
            .replacingOccurrences(of: "Institute of ", with: "")
            .replacingOccurrences(of: "Division of ", with: "")
            .replacingOccurrences(of: "Div of ", with: "")  // 添加对"Div of"前缀的处理
            .replacingOccurrences(of: "Faculty of ", with: "")
            .replacingOccurrences(of: "UCL ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("清理后的部门名称: \(cleanedName)")

        // 使用更宽松的匹配策略
        let searchResults = repository.searchUnits(query: cleanedName)
        print("搜索结果数量: \(searchResults.count)")

        // 直接显示搜索结果
        for (index, result) in searchResults.prefix(5).enumerated() {
            print("搜索结果 #\(index+1): \(result.name), ID: \(result.id), 类型: \(result.type.rawValue)")
        }

        if let exactMatch = searchResults.first(where: { unit in
            unit.name.lowercased() == cleanedName.lowercased()
        }) {
            departmentUnit = exactMatch
            print("找到精确匹配部门: \(exactMatch.name), ID: \(exactMatch.id)")
        } else if let partialMatch = searchResults.first(where: { unit in
            unit.name.lowercased().contains(cleanedName.lowercased())
        }) {
            departmentUnit = partialMatch
            print("找到部分匹配部门: \(partialMatch.name), ID: \(partialMatch.id), 原名: \(departmentName)")
        } else if !searchResults.isEmpty {
            // 任意结果
            let partialMatchAny = searchResults.first!
            departmentUnit = partialMatchAny
            print(
                "找到任意匹配部门: \(partialMatchAny.name), ID: \(partialMatchAny.id), 原名: \(departmentName)"
            )
        } else {
            print("无法找到部门: \(departmentName)")

            // 尝试使用部分名称匹配
            let keywords = cleanedName.split(separator: " ")
            print("尝试使用关键词匹配: \(keywords)")

            for keyword in keywords where keyword.count > 3 {
                let results = repository.searchUnits(query: String(keyword))
                print("关键词 '\(keyword)' 搜索结果数量: \(results.count)")

                if let match = results.first {
                    departmentUnit = match
                    print("通过关键词找到部门: \(match.name), ID: \(match.id), 关键词: \(keyword)")
                    break
                }
            }

            // 如果仍未找到，尝试硬编码常见部门名称映射
            if departmentUnit == nil {
                let hardcodedMappings: [String: String] = [
                    "Computer Science": "COMPS_ENG",
                    "Chemistry": "CHEM_MPS",
                    "Physics": "PHYS_MPS",
                    "Mathematics": "MATH_MPS",
                    "Statistical Science": "STAT_MPS",
                    "Engineering": "ENG_SCI",
                    "Biosciences": "BIOSC_LIF",  // 添加生物科学映射
                ]

                for (deptName, deptID) in hardcodedMappings {
                    if cleanedName.lowercased().contains(deptName.lowercased()) {
                        if let unit = repository.getUnit(byID: deptID) {
                            departmentUnit = unit
                            print("通过硬编码映射找到部门: \(unit.name), ID: \(deptID), 原名: \(departmentName)")
                            break
                        }
                    }
                }
            }
        }

        // 最终结果
        if let unit = departmentUnit {
            print("最终找到部门: \(unit.name), ID: \(unit.id)")
        } else {
            print("最终未找到部门 \(departmentName)")

            // 应急方案：如果完全找不到匹配，使用计算机科学系作为默认值
            if let defaultUnit = repository.getUnit(byID: "COMPS_ENG") {
                departmentUnit = defaultUnit
                print("使用默认部门: \(defaultUnit.name), ID: \(defaultUnit.id)")
            }
        }
    }
}
