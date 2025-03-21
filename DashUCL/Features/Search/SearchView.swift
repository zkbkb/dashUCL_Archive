import SwiftUI
import UIKit

// 导入主题常量

// MARK: - ScrollOffsetPreferenceKey
struct SearchScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 渐进式模糊头部组件
struct SearchProgressiveBlurHeader: View {
    let safeAreaTop: CGFloat
    let scrollOffset: CGFloat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 使用统一的主题背景色
            Rectangle()
                .fill(ThemeConstants.primaryBackground)
                .frame(height: safeAreaTop)
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - 搜索激活时的背景模糊效果
struct SearchActiveBlurBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // 使用统一的主题背景色
        Rectangle()
            .fill(ThemeConstants.primaryBackground)
            .ignoresSafeArea()
    }
}

// MARK: - 搜索视图
struct SearchView: View {
    // MARK: - 状态管理
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏 (包含返回按钮)
            searchBarWithBackButton
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(ThemeConstants.primaryBackground)
                .zIndex(1)  // 确保搜索栏始终在最上层

            Divider()
                .padding(.horizontal)

            // 内容区域 - 使用VStack而不是ZStack
            if !searchText.isEmpty {
                // 搜索结果区域
                if viewModel.isSearching {
                    SearchLoadingView()
                        .background(ThemeConstants.groupedBackground)
                        .transition(.opacity)
                } else if viewModel.hasResults {
                    searchResultList
                        .transition(.opacity)
                } else if !searchText.isEmpty {
                    NoResultsView(query: searchText)
                        .background(ThemeConstants.groupedBackground)
                        .transition(.opacity)
                }
            } else {
                // 空状态 - 初始搜索页面
                emptyStateView
                    .transition(.opacity)
            }
        }
        .background(ThemeConstants.primaryBackground.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .appStandardStatusBar(showDivider: false)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSearching)
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasResults)
        .animation(.easeInOut(duration: 0.2), value: searchText)
        .onAppear {
            // 记录导航栏详细信息以便调试
            print("SearchView appeared, navigationPath: \(navigationManager.navigationPath.count)")

            // 自动聚焦到搜索栏
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFieldFocused = true
            }

            // 处理初始搜索查询
            if !navigationManager.searchQuery.isEmpty {
                searchText = navigationManager.searchQuery
                isSearchFieldFocused = navigationManager.shouldFocusSearchField

                Task {
                    await viewModel.searchPeople(query: searchText)

                    // 清除导航管理器中的查询，避免下次打开时重复搜索
                    DispatchQueue.main.async {
                        navigationManager.searchQuery = ""
                        navigationManager.shouldFocusSearchField = false
                    }
                }
            }
        }
        // 当搜索视图消失时，清除状态
        .onDisappear {
            // 记录导航栏详细信息以便调试
            print(
                "SearchView disappeared, navigationPath: \(navigationManager.navigationPath.count)")

            searchText = ""
            isSearchFieldFocused = false
            viewModel.clearResults()
        }
    }

    // MARK: - 带返回按钮的搜索栏
    private var searchBarWithBackButton: some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button {
                // 添加轻微震动反馈
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                // 使用导航管理器返回，而不是直接dismiss
                navigationManager.navigateBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
            }

            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .opacity(0.8)

                TextField("Search people", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused($isSearchFieldFocused)
                    .font(.system(size: 15))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            viewModel.clearResults()
                        }
                    }
                    .onSubmit {
                        executeSearch()
                    }

                // 清除按钮
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.clearResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .transition(.opacity)
                }

                // 搜索按钮
                if !searchText.isEmpty {
                    Button {
                        executeSearch()
                    } label: {
                        Text("Go")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
            )
        }
    }

    // MARK: - 搜索结果列表
    private var searchResultList: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.peopleResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("People")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top, 16)

                        ForEach(viewModel.peopleResults) { person in
                            PersonResultRow(person: person)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .background(ThemeConstants.groupedBackground)
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 100, height: 100)
                )

            Text("Search UCL")
                .font(.title2)
                .fontWeight(.bold)

            Text("Find people, departments, or resources")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeConstants.groupedBackground)
    }

    // MARK: - 执行搜索
    private func executeSearch() {
        guard !searchText.isEmpty else { return }

        // 添加轻微震动反馈
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // 隐藏键盘
        isSearchFieldFocused = false

        Task {
            // 执行搜索
            await viewModel.searchPeople(query: searchText)
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .environmentObject(NavigationManager.shared)
    }
}
