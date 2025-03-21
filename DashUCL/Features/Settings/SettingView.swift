/*
 * Comprehensive settings view with user preferences and app configuration options.
 * Provides controls for theme selection, notification preferences, and app behavior.
 * Implements section-based UI with grouped lists for intuitive settings organization.
 * Integrates with shared service managers for persistent settings storage.
 */

//
//  SettingView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/02/2025.
//

import SwiftUI

struct SettingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isNotificationsEnabled = false
    @State private var isCourseRemindersEnabled = true
    @State private var isSigningOut = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @State private var showPrivacyPolicySheet = false
    @State private var showTermsAndConditionsSheet = false
    @State private var searchText = ""

    var body: some View {
        ZStack {
            // Use system default background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Main content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {

                    // Account Section
                    SettingsGroup(title: "Account") {
                        NavigationLink(destination: AccountInformationView()) {
                            SettingsItemView(icon: "person.circle.fill", title: "Account Profile")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // App Settings
                    SettingsGroup(title: "App Settings") {
                        NavigationLink(destination: AppearanceSettingsView()) {
                            SettingsItemView(icon: "paintbrush.fill", title: "Appearance")
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: LanguageSettingsView()) {
                            SettingsItemView(icon: "globe", title: "Language")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)

                    // Notifications Section
                    SettingsGroup(title: "Notifications") {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .padding(.trailing, 8)

                            Text("Enable Notifications")
                                .font(.system(size: 17))

                            Spacer()

                            Toggle("", isOn: $isNotificationsEnabled)
                                .labelsHidden()
                                .tint(Color.green)
                                .onChange(of: isNotificationsEnabled) { _, newValue in
                                    if newValue {
                                        // 请求通知权限
                                        notificationManager.requestNotificationAuthorization {
                                            granted in
                                            isNotificationsEnabled = granted
                                            appSettings.notificationsEnabled = granted

                                            // 如果授权成功并且课程提醒已启用，重新安排课程提醒
                                            if granted && isCourseRemindersEnabled {
                                                notificationManager.toggleCourseReminders(
                                                    enabled: true)
                                            }
                                        }
                                    } else {
                                        // 禁用通知
                                        appSettings.notificationsEnabled = false

                                        // 取消所有课程提醒
                                        notificationManager.toggleCourseReminders(enabled: false)
                                    }
                                }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(4)

                        if isNotificationsEnabled {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                        .frame(width: 24, height: 24)
                                        .padding(.trailing, 8)

                                    Text("Course Reminders")
                                        .font(.system(size: 17))

                                    Spacer()

                                    Toggle("", isOn: $isCourseRemindersEnabled)
                                        .labelsHidden()
                                        .tint(Color.green)
                                        .onChange(of: isCourseRemindersEnabled) { _, newValue in
                                            notificationManager.toggleCourseReminders(
                                                enabled: newValue)
                                        }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(4)

                                Divider()
                                    .padding(.leading, 48)

                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                        .frame(width: 24, height: 24)
                                        .padding(.trailing, 8)

                                    Text("Reminder Time")
                                        .font(.system(size: 17))

                                    Spacer()

                                    Menu {
                                        ForEach(
                                            AppConfiguration.NotificationConfig.reminderTimeOptions,
                                            id: \.self
                                        ) { minutes in
                                            Button(action: {
                                                // 通过NotificationManager更新提醒时间
                                                notificationManager.updateCourseReminderTime(
                                                    minutes: minutes)
                                            }) {
                                                if minutes == appSettings.courseReminderTime {
                                                    Label(
                                                        "\(minutes) minutes",
                                                        systemImage: "checkmark")
                                                } else {
                                                    Text("\(minutes) minutes")
                                                }
                                            }
                                        }
                                    } label: {
                                        Text("\(appSettings.courseReminderTime) minutes")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(4)

                                // 如果有待处理的提醒，显示一个状态信息
                                if notificationManager.hasPendingClassReminders {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 8)

                                        Text("You have active course reminders")
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)

                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Support Section
                    SettingsGroup(title: "Support") {
                        // 使用NavigationLink替代Button和sheet
                        NavigationLink(destination: HelpSupportView()) {
                            SettingsItemView(
                                icon: "questionmark.circle.fill", title: "Help & Support")
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Buttons for Privacy and Terms
                        Button(action: {
                            showPrivacyPolicy()
                        }) {
                            SettingsItemView(icon: "lock.fill", title: "Privacy Policy")
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            showTermsAndConditions()
                        }) {
                            SettingsItemView(
                                icon: "doc.text.fill", title: "Terms and Conditions")
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: AboutView()) {
                            SettingsItemView(icon: "info.circle.fill", title: "About DashUCL")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)

                    // Sign Out Button - Modern style
                    Button(action: {
                        isSigningOut = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)  // 设置导航栏背景为超薄材料
        .onAppear {
            // 检查通知设置
            isNotificationsEnabled = appSettings.notificationsEnabled

            // 同步课程提醒状态
            isCourseRemindersEnabled = appSettings.courseRemindersEnabled

            // 同步通知授权状态
            notificationManager.checkNotificationAuthorizationStatus()

            // 如果通知未授权，但设置中显示为已启用，则同步状态
            if !notificationManager.isNotificationsAuthorized && isNotificationsEnabled {
                isNotificationsEnabled = false
                appSettings.notificationsEnabled = false
            }

            // 更新待处理的提醒状态
            notificationManager.updatePendingRemindersStatus()

            // 添加通知观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowPrivacyPolicy"),
                object: nil,
                queue: .main
            ) { _ in
                showPrivacyPolicy()
            }

            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowTermsAndConditions"),
                object: nil,
                queue: .main
            ) { _ in
                showTermsAndConditions()
            }
        }
        .onDisappear {
            // 移除通知观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ShowPrivacyPolicy"),
                object: nil
            )

            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ShowTermsAndConditions"),
                object: nil
            )
        }
        .sheet(isPresented: $showPrivacyPolicySheet) {
            SettingsPrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsAndConditionsSheet) {
            SettingsTermsAndConditionsView()
        }
        .alert("Sign Out", isPresented: $isSigningOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                performSignOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private func showPrivacyPolicy() {
        showPrivacyPolicySheet = true
    }

    private func showTermsAndConditions() {
        showTermsAndConditionsSheet = true
    }

    private func performSignOut() {
        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        AuthManager.shared.signOut()
    }
}

#Preview {
    NavigationStack {
        SettingView()
    }
}
