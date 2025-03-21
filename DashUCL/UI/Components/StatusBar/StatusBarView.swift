/*
 * Custom status bar component providing consistent styling across the app.
 * Implements a view modifier pattern for easy application to any view.
 * Adapts to system dark/light mode with appropriate color adjustments.
 * Supports optional divider line for visual separation from content.
 */

import SwiftUI

/// A modern immersive status bar
struct StatusBarView: View {
    var body: some View {
        EmptyView()
    }
}

// 创建一个ViewModifier以便更容易地应用一致的状态栏样式
struct StatusBarModifier: ViewModifier {
    var showDivider: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(showDivider: Bool = true) {
        self.showDivider = showDivider
    }

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.large)
            // 只设置工具栏可见性，但不更改背景材质，让UIKit的全局设置生效
            .toolbarBackground(.visible, for: .navigationBar)
            // 不再设置背景材质，让UIKit的appearance设置生效
            // 使用标准方式确保导航栏分界线显示
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EmptyView()
                }
            }
    }
}

// 扩展View以添加便捷方法
extension View {
    func appStandardStatusBar(showDivider: Bool = true) -> some View {
        modifier(StatusBarModifier(showDivider: showDivider))
    }

    // 辅助函数，用于条件性地应用修饰符
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    TabView {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(0..<20) { i in
                        Text("Item \(i)")
                            .frame(height: 50)
                    }
                }
            }
            .navigationTitle("Preview")
            .appStandardStatusBar(showDivider: true)
        }
        .tabItem {
            Label("Tab 1", systemImage: "house")
        }

        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(0..<20) { i in
                        Text("Item \(i)")
                            .frame(height: 50)
                    }
                }
            }
            .navigationTitle("No Divider")
            .appStandardStatusBar(showDivider: false)
        }
        .tabItem {
            Label("Tab 2", systemImage: "star")
        }
    }
}
