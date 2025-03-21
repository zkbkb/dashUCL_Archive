//
//  LanguageSettingsView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI

struct LanguageSettingsView: View {
    @State private var selectedLanguage = "English"
    let availableLanguages = ["English"]
    private let persistentStorage = PersistentStorage.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Language Selection Section
                    SettingsGroup(title: "App Language") {
                        ForEach(availableLanguages, id: \.self) { language in
                            Button(action: {
                                selectedLanguage = language
                                persistentStorage.saveValue(language, forKey: .appLanguage)
                            }) {
                                HStack {
                                    Text(language)
                                        .font(.system(size: 17))

                                    Spacer()

                                    if selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)

                    // Information Section
                    SettingsGroup(title: "Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Language Settings")
                                .font(.headline)
                                .padding(.bottom, 4)

                            Text(
                                "Currently, DashUCL is only available in English. We're working on adding support for more languages in future updates."
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                            Text(
                                "Your device language settings will be used for date and time formats."
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let savedLanguage = persistentStorage.loadString(forKey: .appLanguage) {
                selectedLanguage = savedLanguage
            }
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
