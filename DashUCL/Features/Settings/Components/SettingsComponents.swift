//
//  SettingsComponents.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI

// 设置组
struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                .padding(.bottom, 4)

            VStack(spacing: 1) {
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// 设置项视图 - 用于导航链接
struct SettingsItem<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            SettingsItemView(icon: icon, title: title)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 设置项视图 - 基础视图组件
struct SettingsItemView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
                .padding(.trailing, 8)

            if let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(4)
    }
}

// 设置项视图 - 没有图标，用于子视图
struct SettingsItemNoIcon: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack {
            if let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(4)
    }
}

// 设置项 - 没有图标的导航链接，用于子视图
struct SettingsItemLinkNoIcon<Destination: View>: View {
    let title: String
    let destination: Destination
    var subtitle: String? = nil

    var body: some View {
        NavigationLink(destination: destination) {
            SettingsItemNoIcon(title: title, subtitle: subtitle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 自定义修饰符，已不再用于样式设置，仅作为兼容性过渡
struct TitleDisplayModeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func titleDisplayMode() -> some View {
        modifier(TitleDisplayModeModifier())
    }
}
