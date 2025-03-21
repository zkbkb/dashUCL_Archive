//
//  AppearanceSettingsView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appSettings = AppSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Theme Section with Theme Cards
                    SettingsGroup(title: "Theme") {
                        VStack(spacing: 16) {
                            // Theme Cards
                            HStack(spacing: 12) {
                                ForEach(ThemeOption.allCases, id: \.self) { option in
                                    ThemeCard(
                                        option: option,
                                        isSelected: themeManager.currentTheme == option,
                                        action: {
                                            withAnimation(
                                                .spring(response: 0.3, dampingFraction: 0.7)
                                            ) {
                                                themeManager.setTheme(option)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // About Appearance Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Appearance Settings")
                            .font(.headline)
                            .padding(.bottom, 4)

                        Text(
                            "The theme setting controls the overall look of the app. You can choose between light mode, dark mode, or follow your device's system setting."
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Theme Card Component
struct ThemeCard: View {
    let option: ThemeOption
    let isSelected: Bool
    let action: () -> Void

    // Preview background colors based on theme
    private var previewBackgroundColor: Color {
        switch option {
        case .light:
            // Always use a light color regardless of system theme
            return Color.white
        case .dark:
            // Always use a dark color regardless of system theme
            return Color.black
        case .system:
            // Use a neutral color with a slight hint of the current theme
            return colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)
        }
    }

    // Preview content color based on theme
    private var previewContentColor: Color {
        switch option {
        case .light:
            // Always dark text on light background
            return Color.black
        case .dark:
            // Always light text on dark background
            return Color.white
        case .system:
            // Adapt based on the current system theme
            return colorScheme == .dark ? Color.white : Color.black
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Theme Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(previewBackgroundColor)
                        .frame(height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isSelected ? Color(.systemGray) : Color.gray.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1)
                        )
                        // Add a subtle shadow to help distinguish light cards in dark mode
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)

                    // Preview Content
                    VStack(spacing: 4) {
                        Image(systemName: themeIcon(for: option))
                            .font(.system(size: 18))
                            .foregroundColor(previewContentColor)

                        Text("Aa")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(previewContentColor)
                    }
                }

                // Theme Name
                Text(option.displayName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(.label) : Color(.secondaryLabel))

                // Selection Indicator
                Circle()
                    .fill(isSelected ? Color(.systemGray) : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Helper method to get icon for each theme option
    private func themeIcon(for option: ThemeOption) -> String {
        switch option {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gear"
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
