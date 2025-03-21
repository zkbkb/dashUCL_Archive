/*
 * Dashboard view for browsing UCL study spaces and computer clusters with real-time availability.
 * Features a card-based UI with category filtering and visual indicators for space status.
 * Implements pull-to-refresh, scroll animations, and navigation to detailed space information.
 * Uses a shared ViewModel for consistent data access across related space views.
 */

// Import RefreshableView component
import MapKit
import SwiftUI

// Using ScrollOffsetPreferenceKey defined in Core/Extensions/PreferenceKeys

// Import theme constants

/// Study space browsing view - Dashboard style
struct SpaceView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SpaceViewModel.shared
    @State private var contentViewRefreshID = UUID()  // Add a state variable to force refresh content view
    @State private var isPullToRefreshing = false  // Add a state variable to mark if pull-to-refresh is active
    @State private var scrollOffset: CGFloat = 0  // Add state variable to track scroll offset
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager: NavigationManager

    // Space type tabs
    enum SpaceCategory: String, CaseIterable, Identifiable {
        case studySpaces = "Study Spaces"
        case computerClusters = "Computer Clusters"

        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .studySpaces:
                return "books.vertical.fill"
            case .computerClusters:
                return "desktopcomputer"
            }
        }

        var color: Color {
            switch self {
            case .studySpaces:
                return .blue
            case .computerClusters:
                return .purple
            }
        }

        var description: String {
            switch self {
            case .studySpaces:
                return "Libraries and quiet study areas across UCL campus"
            case .computerClusters:
                return "Computer labs and digital workspaces"
            }
        }

        var extendedDescription: String {
            switch self {
            case .studySpaces:
                return
                    "Find quiet reading areas, group study rooms, and library spaces ideal for focused work and research"
            case .computerClusters:
                return
                    "Locate computer labs with specialized software, printing facilities, and digital workspace equipment"
            }
        }
    }

    // Check if it's the main tab
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Body
    var body: some View {
        // Remove NavigationStack, directly use content view
        GeometryReader { geometry in
            // Get top safe area height
            let _ = geometry.safeAreaInsets.top  // Unused, use underscore

            ZStack(alignment: .top) {
                // -- Background content --
                ThemeConstants.primaryBackground
                    .frame(height: geometry.size.height)
                    .zIndex(0)

                // -- Main content --
                VStack(spacing: 0) {  // Change spacing to 0, consistent with HomeTabView
                    // Content area
                    if viewModel.isLoading && viewModel.allSpaces.isEmpty && !isPullToRefreshing {
                        // Use new LoadingCircleView component - only show when not pull-to-refresh
                        LoadingCircleView(
                            title: "Loading Spaces",
                            description: "Finding available study spaces across UCL"
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            // Add GeometryReader to track scroll position, consistent with HomeTabView
                            GeometryReader { scrollGeo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeo.frame(in: .named("scrollView")).minY
                                )
                            }
                            .frame(height: 0)  // 不占用空间

                            // 使用与HomeTabView一致的结构
                            VStack(spacing: 16) {  // 增加spacing到16，与HomeTabView保持一致
                                // 顶部安全区域空间不再需要，移除

                                // 状态指示栏 - 添加一些顶部边距，让它不会与下拉刷新动画重叠
                                flatOverviewBar
                                    .frame(height: 160)
                                    .id(contentViewRefreshID)  // 使用contentViewRefreshID确保内容视图在刷新时能够完全重建
                                    .padding(.horizontal, 16)
                                    .padding(.top, 20)  // 增加顶部内边距，给下拉刷新腾出足够空间

                                // 分界线
                                Divider()
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 16)

                                // 分类选项
                                VStack(spacing: 12) {
                                    gradientCategoryTile(for: .studySpaces)
                                        .frame(height: 200)

                                    gradientCategoryTile(for: .computerClusters)
                                        .frame(height: 200)
                                }
                                .padding(.horizontal, 16)

                                // 底部空间
                                Spacer(minLength: 20)
                            }
                        }
                        .coordinateSpace(name: "scrollView")  // 添加命名坐标空间，以便GeometryReader能正确跟踪滚动位置
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                            // 更新滚动偏移量
                            scrollOffset = offset
                        }
                        .refreshable {
                            print(
                                "[SpaceView] User triggered pull-to-refresh, forcing data refresh")
                            // 设置下拉刷新状态为true
                            isPullToRefreshing = true

                            // 强制刷新数据，不使用缓存
                            viewModel.cacheEnabled = false
                            await viewModel.refreshSpacesData()
                            viewModel.cacheEnabled = true

                            // 强制刷新内容视图
                            contentViewRefreshID = UUID()

                            // 下拉刷新完成，重置状态
                            isPullToRefreshing = false
                            print("[SpaceView] Pull-to-refresh completed")
                        }
                    }
                }
                .zIndex(1)
            }
        }
        // 保留导航标题并添加应用标准状态栏修饰符
        .navigationTitle("Space")
        .appStandardStatusBar()
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            // 如果加载状态从true变为false，确保重置下拉刷新状态
            if oldValue && !newValue {
                isPullToRefreshing = false
            }
        }
        .task {
            print("[SpaceView] View appeared, checking if data needs to be loaded")
            // 检查数据是否已经加载
            if viewModel.allSpaces.isEmpty {
                print("[SpaceView] No cached data, start loading")
                await viewModel.loadInitialData()
            } else {
                print("[SpaceView] Using already loaded cached data")
            }
        }
    }

    // "time ago" 字符串转换函数
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Components

    /// 扁平化的概览栏 - 无卡片设计
    private var flatOverviewBar: some View {
        // 准备数据
        let studySpaces = getFilteredSpaces(for: .studySpaces)
        let computerSpaces = getFilteredSpaces(for: .computerClusters)
        let allSpaces = studySpaces + computerSpaces
        let totalCount = allSpaces.count
        let highAvailabilitySpaces = allSpaces.filter { $0.occupancyPercentage < 33 }
        let mediumAvailabilitySpaces = allSpaces.filter {
            $0.occupancyPercentage >= 33 && $0.occupancyPercentage < 66
        }
        let lowAvailabilitySpaces = allSpaces.filter { $0.occupancyPercentage >= 66 }
        let highCount = highAvailabilitySpaces.count
        let mediumCount = mediumAvailabilitySpaces.count
        let lowCount = lowAvailabilitySpaces.count
        let totalSeats = allSpaces.reduce(0) { $0 + $1.totalSeats }
        let freeSeats = allSpaces.reduce(0) { $0 + $1.freeSeats }
        let freePercentage = totalSeats > 0 ? Double(freeSeats) / Double(totalSeats) * 100 : 0

        return VStack(alignment: .leading, spacing: 8) {  // 增加垂直间距，更加舒适
            // 标题和更新时间
            HStack {
                Text("Space Overview")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                // 最后更新时间
                if viewModel.lastUpdated != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(viewModel.lastUpdatedText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 主内容区域 - 水平布局
            HStack(spacing: 16) {
                // 左侧：可用性数字 - 添加圆角矩形背景
                Text("\(Int(freePercentage))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // 主背景 - 使用总可用度情况的颜色
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                            colors: [
                                                getAvailabilityColor(
                                                    percentage: freePercentage),
                                                getAvailabilityColor(percentage: freePercentage)
                                                    .opacity(0.8),
                                            ]
                                        ),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // 顶部高光效果
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .mask(
                                    RoundedRectangle(cornerRadius: 12)
                                        .scale(0.99)  // 稍微缩小一点，避免边缘重叠
                                        .frame(height: 15)
                                        .frame(maxHeight: .infinity, alignment: .top)
                                )
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                Spacer()

                // 右侧：分布指示 - 每种类型的空间数量
                HStack(spacing: 12) {  // 减小间距，更加紧凑
                    availabilityIndicator(count: highCount, color: .green, label: "High")
                    availabilityIndicator(count: mediumCount, color: .orange, label: "Medium")
                    availabilityIndicator(count: lowCount, color: .red, label: "Low")
                }
            }
            .padding(.vertical, 8)  // 调整垂直间距，使布局更加平衡

            // 可用性进度条组 - 增强版 - 调整垂直间距
            VStack(spacing: 6) {
                // 删除空间数量信息
                // 视觉化进度条
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 18)

                    // 进度条容器 - 使用GeometryReader和固定宽度比例
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            if totalCount > 0 {
                                // 计算宽度比例
                                let highWidth = CGFloat(highCount) / CGFloat(totalCount)
                                let mediumWidth = CGFloat(mediumCount) / CGFloat(totalCount)
                                let lowWidth = CGFloat(lowCount) / CGFloat(totalCount)

                                // 高可用性段 (绿色)
                                if highCount > 0 {
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geo.size.width * highWidth)
                                }

                                // 中等可用性段 (橙色)
                                if mediumCount > 0 {
                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(width: geo.size.width * mediumWidth)
                                }

                                // 低可用性段 (红色)
                                if lowCount > 0 {
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: geo.size.width * lowWidth)
                                }
                            }
                        }
                    }
                    .frame(height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // 添加细微立体感 - 顶部亮线
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(height: 18)
                        .mask(
                            // 只在顶部显示亮线
                            Rectangle()
                                .frame(height: 5)
                                .frame(maxHeight: .infinity, alignment: .top)
                        )
                }
                // 底部留出适当的空间，与分界线保持一致的距离
                .padding(.bottom, 2)
            }
        }
        .padding(.horizontal, 10)  // 调整水平内边距，使其更好地与下方卡片视觉对齐
    }

    /// 可用性指示器
    private func availabilityIndicator(count: Int, color: Color, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(color)
        }
    }

    /// 带渐变背景的分类卡片
    private func gradientCategoryTile(for category: SpaceCategory) -> some View {
        let spaces = getFilteredSpaces(for: category)
        let freeSeats = spaces.reduce(0) { $0 + $1.freeSeats }
        let totalSeats = spaces.reduce(0) { $0 + $1.totalSeats }
        let availabilityPercentage =
            totalSeats > 0 ? Double(freeSeats) / Double(totalSeats) * 100 : 0
        let spaceCount = spaces.count

        return NavigationLink(
            destination: SpaceLocationsView(category: category)
        ) {
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Text(category.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(spaceCount) Spaces")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)

                // 中间部分弹性撑开
                Spacer(minLength: 0)

                // 中间数据部分
                HStack(alignment: .bottom, spacing: 12) {
                    // 左侧数据
                    VStack(alignment: .leading, spacing: 4) {
                        // 可用百分比
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(availabilityPercentage))")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(.white)

                            Text("%")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // 状态标签
                        Text("Available")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.leading, 20)

                    Spacer()

                    // 右侧数据：可用座位
                    VStack(alignment: .trailing, spacing: 4) {
                        // 座位数量
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(freeSeats)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("/ \(totalSeats)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // 座位标签
                        Text("Seats Free")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 16)

                // 底部进度条
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)

                    // 进度
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.white)
                            .frame(
                                width: geo.size.width * CGFloat(availabilityPercentage / 100),
                                height: 6)
                    }
                }
                .frame(height: 6)

                // 点击箭头指示器
                HStack {
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .padding(.trailing, 16)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .background(
                ZStack {
                    // 主背景 - 使用分类颜色
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        category.color,
                                        category.color.opacity(0.8),
                                    ]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 顶部高光效果
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .mask(
                            RoundedRectangle(cornerRadius: 12)
                                .scale(0.99)  // 稍微缩小一点，避免边缘重叠
                                .frame(height: 15)
                                .frame(maxHeight: .infinity, alignment: .top)
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.25)
                    : Color.black.opacity(0.1),
                radius: colorScheme == .dark ? 5 : 3,
                x: 0,
                y: colorScheme == .dark ? 3 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    /// 获取特定类别的过滤空间
    private func getFilteredSpaces(for category: SpaceCategory) -> [SpaceResult] {
        // 首先过滤出有座位数据的空间
        let spacesWithData = viewModel.allSpaces.filter { $0.totalSeats > 0 }

        // 然后按类别过滤
        let spaces = spacesWithData.filter { space in
            switch category {
            case .studySpaces:
                // 匹配图书馆空间，排除计算机空间
                return !space.name.lowercased().contains("computer")
                    && !space.description.lowercased().contains("computer")
                    && !space.name.lowercased().contains("[isd]")
            case .computerClusters:
                // 匹配计算机集群
                return space.name.lowercased().contains("computer")
                    || space.description.lowercased().contains("computer")
                    || space.name.lowercased().contains("cluster")
                    || space.name.lowercased().contains("[isd]")
            }
        }

        // 按可用性排序，先显示高可用性的空间
        return spaces.sorted { $0.occupancyPercentage < $1.occupancyPercentage }
    }

    /// 计算空间集合的平均占用率
    private func calculateOccupancyPercentage(for spaces: [SpaceResult]) -> Double {
        guard !spaces.isEmpty else { return 0 }

        let totalOccupancy = spaces.reduce(0.0) { $0 + Double($1.occupancyPercentage) }
        return totalOccupancy / Double(spaces.count)
    }

    /// 根据可用性百分比获取颜色
    private func getAvailabilityColor(percentage: Double) -> Color {
        if percentage > 66 {
            return .green
        } else if percentage > 33 {
            return .orange
        } else {
            return .red
        }
    }

    /// 获取可用性状态文本
    private func getAvailabilityStatusText(percentage: Double) -> String {
        if percentage > 66 {
            return "High"
        } else if percentage > 33 {
            return "Medium"
        } else {
            return "Low"
        }
    }

    // 添加一个辅助方法来格式化最后更新时间
    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdated else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// 空间列表详细视图
struct SpaceListView: View {
    let category: SpaceView.SpaceCategory
    let spaces: [SpaceResult]
    var searchText: String = ""  // 保留参数但给一个默认空字符串值

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景色
            (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
                .ignoresSafeArea()

            VStack {
                if spaces.isEmpty {
                    emptyResultsView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // 显示空间列表
                            ForEach(spaces, id: \.id) { space in
                                StudySpaceResultRow(space: space)
                                    .padding(.horizontal)
                            }

                            // 底部空间
                            Spacer(minLength: 40)
                        }
                        .padding(.top, 16)
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 空结果视图
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 100)
                )

            Text("No spaces found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No spaces available in this category")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground))
    }
}

#Preview {
    SpaceView()
        .environmentObject(NavigationManager.shared)
}

// 添加用于跟踪滚动位置的PreferenceKey已移至Core/Extensions/PreferenceKeys.swift
