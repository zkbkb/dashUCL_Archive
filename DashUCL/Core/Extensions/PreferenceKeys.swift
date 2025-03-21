import SwiftUI

// MARK: - 通用自定义PreferenceKeys
/// 用于跟踪滚动视图的偏移量
public struct ScrollOffsetPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// 如果需要添加更多的PreferenceKey，可以在此文件中继续添加
