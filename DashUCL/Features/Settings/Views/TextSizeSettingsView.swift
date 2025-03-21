//
//  TextSizeSettingsView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI

struct TextSizeSettingsView: View {
    @State private var textSize: Double = 1.0
    @State private var boldText: Bool = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Text Size Slider Section
                    SettingsGroup(title: "Text Size") {
                        VStack(spacing: 16) {
                            // Sample Text
                            VStack(spacing: 8) {
                                Text("Sample Text")
                                    .font(.headline)
                                    .scaleEffect(textSize)

                                Text("This is how your text will appear throughout the app.")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .scaleEffect(textSize)
                                    .fontWeight(boldText ? .bold : .regular)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)

                            // Size Slider
                            VStack(spacing: 8) {
                                HStack {
                                    Text("A")
                                        .font(.system(size: 14))

                                    Slider(value: $textSize, in: 0.8...1.4, step: 0.1)
                                        .tint(.green)

                                    Text("A")
                                        .font(.system(size: 24))
                                }

                                // Size Labels
                                HStack {
                                    Text("Smaller")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("Default")
                                        .font(.caption)
                                        .foregroundColor(textSize == 1.0 ? .primary : .secondary)

                                    Spacer()

                                    Text("Larger")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(4)

                        // Bold Text Toggle
                        HStack {
                            Text("Bold Text")
                                .font(.system(size: 17))

                            Spacer()

                            Toggle("", isOn: $boldText)
                                .labelsHidden()
                                .tint(Color.green)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)

                    // Text Settings Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Text Settings")
                            .font(.headline)
                            .padding(.bottom, 4)

                        Text(
                            "Text size and bold settings help improve readability. Larger text and bold formatting can make content easier to read."
                        )
                        .font(.body)
                        .foregroundColor(.secondary)

                        Text(
                            "These settings only affect text within the DashUCL app and do not change system-wide text settings on your device."
                        )
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Text Size")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load saved text size settings
            if let savedTextSize = UserDefaults.standard.object(forKey: "appTextSize") as? Double {
                textSize = savedTextSize
            }

            if let savedBoldText = UserDefaults.standard.object(forKey: "appBoldText") as? Bool {
                boldText = savedBoldText
            }
        }
    }
}

#Preview {
    NavigationStack {
        TextSizeSettingsView()
    }
}
