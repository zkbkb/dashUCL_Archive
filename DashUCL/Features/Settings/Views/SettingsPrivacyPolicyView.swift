//
//  SettingsPrivacyPolicyView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/02/2025.
//

import SwiftUI

struct SettingsPrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var showScrollIndicator: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    // 使用新的URL
    private let privacyURL = URL(string: "https://auth.support/privacy")!

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 使用iOS深色模式标准的深灰色
                (colorScheme == .dark
                    ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
                    : Color(UIColor.systemBackground))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部安全区域和拖动指示器
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 36, height: 5)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    // 添加底部分界线
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.gray.opacity(0.3)),
                        alignment: .bottom
                    )
                    // 添加轻微阴影效果
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)

                    // 使用WebView
                    ZStack {
                        SettingsWebView(url: privacyURL, isLoading: $isLoading, hasError: $hasError)
                            .overlay(
                                // 自定义滑动指示器
                                Group {
                                    if showScrollIndicator {
                                        HStack {
                                            Spacer()
                                            Capsule()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 3)
                                                .padding(.vertical, 40)
                                                .padding(.trailing, 2)
                                        }
                                        .allowsHitTesting(false)
                                    }
                                }
                            )

                        if isLoading {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading Privacy Policy...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemBackground).opacity(0.7))
                        }

                        if hasError {
                            VStack(spacing: 16) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)

                                Text("Unable to Load Privacy Policy")
                                    .font(.headline)

                                Text("Please check your internet connection and try again.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)

                                Button(action: {
                                    isLoading = true
                                    hasError = false
                                    // 重置加载状态，允许重新加载
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        _ = URLRequest(
                                            url: privacyURL,
                                            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                                        UIApplication.shared.open(
                                            privacyURL, options: [:], completionHandler: nil)
                                        dismiss()
                                    }
                                }) {
                                    Text("Open in Browser")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemBackground))
                        }
                    }

                    // Fixed bottom button
                    ZStack(alignment: .bottom) {
                        // 底部渐变背景
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color(UIColor.systemBackground).opacity(0),
                                    Color(UIColor.systemBackground),
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)

                        // 按钮放在渐变背景上面，不会被遮挡
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(height: 110)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))

                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsPrivacyPolicyView()
}
