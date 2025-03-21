import SwiftUI

struct RefreshableView<Content: View>: View {
    var content: Content
    var isRefreshing: Bool
    var onRefresh: () -> Void

    @State private var refreshOffset: CGFloat = 0
    @State private var refreshThreshold: CGFloat = 80
    @State private var isRefreshIndicatorShowing = false
    @State private var hasTriggeredRefresh = false

    init(isRefreshing: Bool, onRefresh: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 刷新指示器 / Refresh indicator
            VStack {
                if isRefreshIndicatorShowing || isRefreshing {
                    VStack(spacing: 8) {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .rotationEffect(
                                    .degrees(refreshOffset > refreshThreshold ? 180 : 0)
                                )
                                .animation(
                                    .easeInOut(duration: 0.2),
                                    value: refreshOffset > refreshThreshold)
                        }

                        Text(
                            isRefreshing
                                ? "Refreshing..."
                                : (refreshOffset > refreshThreshold
                                    ? "Release to refresh" : "Pull to refresh")
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    .padding(.top, 8)
                }
            }
            .zIndex(1)

            // 内容 / Content
            ScrollView {
                ZStack(alignment: .top) {
                    // 这个矩形用于检测滚动位置 / This rectangle is used to detect scroll position
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: RefreshableScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scrollView")).minY
                        )
                    }
                    .frame(height: 0)

                    // 实际内容 / Actual content
                    VStack {
                        // 添加一个空间，当下拉时显示刷新指示器 / Add a space to show refresh indicator when pulling down
                        if isRefreshIndicatorShowing || isRefreshing {
                            Spacer()
                                .frame(height: 60)
                        }

                        content
                    }
                }
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(RefreshableScrollOffsetPreferenceKey.self) { offset in
                refreshOffset = offset

                // 当用户下拉超过阈值时显示指示器 / Show indicator when user pulls down beyond threshold
                if offset > refreshThreshold && !isRefreshing && !isRefreshIndicatorShowing {
                    isRefreshIndicatorShowing = true
                    hasTriggeredRefresh = false
                }

                // 当用户释放并且下拉超过阈值时触发刷新 / Trigger refresh when user releases and has pulled beyond threshold
                if offset < 10 && isRefreshIndicatorShowing && !isRefreshing && !hasTriggeredRefresh
                    && refreshOffset > refreshThreshold
                {
                    hasTriggeredRefresh = true
                    onRefresh()
                }

                // 当刷新完成且用户没有继续下拉时隐藏指示器 / Hide indicator when refresh is complete and user is not pulling down
                if offset < 10 && !isRefreshing && isRefreshIndicatorShowing && hasTriggeredRefresh
                {
                    isRefreshIndicatorShowing = false
                    hasTriggeredRefresh = false
                }
            }
            .onChange(of: isRefreshing) { oldValue, newValue in
                // 当刷新状态从true变为false时，隐藏指示器 / Hide indicator when refresh state changes from true to false
                if oldValue && !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isRefreshIndicatorShowing = false
                        hasTriggeredRefresh = false
                    }
                }
            }
        }
    }
}

// 用于跟踪滚动位置的PreferenceKey / PreferenceKey for tracking scroll position
struct RefreshableScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    RefreshableView(
        isRefreshing: false,
        onRefresh: {
            print("Refreshing...")
        }
    ) {
        VStack(spacing: 20) {
            ForEach(0..<20, id: \.self) { index in
                Text("Item \(index)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
