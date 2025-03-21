import SwiftUI

// Setting group enum
enum SettingGroup: String {
    case appearance = "Appearance"
    case notifications = "Notifications"
    case calendar = "Calendar & Sync"
    case accessibility = "Accessibility"
}

struct SettingsCard: View {
    @Binding var isDarkMode: Bool
    @Binding var useSystemTheme: Bool
    @Binding var isNotificationsEnabled: Bool
    @State private var fontSize: Double = 1.0
    @State private var reduceMotion: Bool = false
    @State private var highContrast: Bool = false
    @State private var syncCalendar: Bool = true
    @State private var autoExport: Bool = false
    @State private var courseReminder: Bool = true
    @State private var bookingReminder: Bool = true
    @State private var seatReminder: Bool = true

    // iOS 18 standard green
    private let accentColor = Color.green
    // Icon color
    private let iconColor = Color.secondary

    init(
        isDarkMode: Binding<Bool>,
        useSystemTheme: Binding<Bool>,
        isNotificationsEnabled: Binding<Bool>
    ) {
        self._isDarkMode = isDarkMode
        self._useSystemTheme = useSystemTheme
        self._isNotificationsEnabled = isNotificationsEnabled
    }

    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 32) {
                // Appearance
                SettingSection(title: SettingGroup.appearance.rawValue) {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingToggleRow(
                            title: "Follow System",
                            subtitle: "Use system appearance settings",
                            icon: "iphone",
                            isOn: $useSystemTheme,
                            accentColor: accentColor,
                            iconColor: iconColor
                        )

                        if !useSystemTheme {
                            SettingToggleRow(
                                title: "Dark Mode",
                                subtitle: "Use dark color scheme",
                                icon: "moon.fill",
                                isOn: $isDarkMode,
                                accentColor: accentColor,
                                iconColor: iconColor
                            )
                            .padding(.leading, 36)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, -16)

                // Notifications
                SettingSection(title: SettingGroup.notifications.rawValue) {
                    VStack(alignment: .leading, spacing: 20) {
                        SettingToggleRow(
                            title: "Enable Notifications",
                            subtitle: "Receive app notifications",
                            icon: "bell.fill",
                            isOn: $isNotificationsEnabled,
                            accentColor: accentColor,
                            iconColor: iconColor
                        )

                        if isNotificationsEnabled {
                            VStack(alignment: .leading, spacing: 16) {
                                SettingToggleRow(
                                    title: "Course Reminders",
                                    subtitle: "Notify before classes start",
                                    icon: "book.fill",
                                    isOn: $courseReminder,
                                    isEnabled: isNotificationsEnabled,
                                    accentColor: accentColor,
                                    iconColor: iconColor
                                )

                                SettingToggleRow(
                                    title: "Booking Reminders",
                                    subtitle: "Room and resource booking notifications",
                                    icon: "calendar.badge.clock",
                                    isOn: $bookingReminder,
                                    isEnabled: isNotificationsEnabled,
                                    accentColor: accentColor,
                                    iconColor: iconColor
                                )

                                SettingToggleRow(
                                    title: "Seat Reminders",
                                    subtitle: "Library seat expiration alerts",
                                    icon: "chair.fill",
                                    isOn: $seatReminder,
                                    isEnabled: isNotificationsEnabled,
                                    accentColor: accentColor,
                                    iconColor: iconColor
                                )
                            }
                            .padding(.leading, 36)
                            .tint(Color.green)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, -16)

                // Calendar & Sync
                SettingSection(title: SettingGroup.calendar.rawValue) {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingToggleRow(
                            title: "Sync with Calendar",
                            subtitle: "Add timetable to system calendar",
                            icon: "calendar",
                            isOn: $syncCalendar,
                            accentColor: accentColor,
                            iconColor: iconColor
                        )

                        SettingToggleRow(
                            title: "Auto Export",
                            subtitle: "Automatically export new events",
                            icon: "square.and.arrow.up",
                            isOn: $autoExport,
                            isEnabled: syncCalendar,
                            accentColor: accentColor,
                            iconColor: iconColor
                        )
                        .padding(.leading, 36)
                    }
                }

                Divider()
                    .padding(.horizontal, -16)

                // Accessibility
                SettingSection(title: SettingGroup.accessibility.rawValue) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Text Size
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Text Size")
                                        .font(.body.weight(.medium))
                                    Text("Adjust the size of text throughout the app")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "textformat.size")
                                    .font(.system(size: 20))
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(iconColor)
                            }

                            Slider(value: $fontSize, in: 0.8...1.2, step: 0.1) {
                                Text("Text Size")
                            } minimumValueLabel: {
                                Text("A").font(.footnote.weight(.medium))
                            } maximumValueLabel: {
                                Text("A").font(.title3.weight(.medium))
                            }
                            .padding(.leading, 36)
                            .tint(Color.green)
                        }

                        SettingToggleRow(
                            title: "Reduce Motion",
                            subtitle: "Minimize animations and motion effects",
                            icon: "hand.raised.fill",
                            isOn: $reduceMotion,
                            accentColor: accentColor,
                            iconColor: iconColor
                        )

                        SettingToggleRow(
                            title: "Increase Contrast",
                            subtitle: "Enhance visual distinction",
                            icon: "circle.circle.fill",
                            isOn: $highContrast,
                            accentColor: accentColor,
                            iconColor: iconColor
                        )
                    }
                }
            }
            .padding(20)
        }
    }
}

// 设置开关行组件
struct SettingToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    var isEnabled: Bool = true
    var accentColor: Color
    var iconColor: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 28, height: 28)
                    .foregroundColor(iconColor)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: accentColor))
        .disabled(!isEnabled)
    }
}

// 设置部分标题组件
struct SettingSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
    }
}

#Preview {
    ScrollView {
        SettingsCard(
            isDarkMode: .constant(false),
            useSystemTheme: .constant(true),
            isNotificationsEnabled: .constant(true)
        )
        .padding()
    }
    .background(Color(.systemBackground))
}
