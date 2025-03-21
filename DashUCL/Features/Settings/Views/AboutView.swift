//
//  AboutView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPrivacyPolicy = false
    @State private var showCredits = false
    @State private var showTermsAndConditions = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // App Logo and Version
                    VStack(spacing: 16) {
                        AppIconView(size: 100)

                        VStack(spacing: 4) {
                            Text("DashUCL")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Version 1.0.0 (Beta)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)

                    // App Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About DashUCL")
                            .font(.headline)

                        Text(
                            "DashUCL is a app designed specifically for UCL students. It provides easy access to essential real-time campus information."
                        )
                        .font(.body)
                        .foregroundColor(.secondary)

                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)

                    // Documentation
                    SettingsGroup(title: "Documentation") {
                        Button(action: {
                            // Navigate to Privacy Policy
                            showPrivacyPolicy = true
                        }) {
                            SettingsItemNoIcon(title: "Privacy Policy")
                        }

                        Button(action: {
                            // Navigate to Terms and Conditions
                            showTermsAndConditions = true
                        }) {
                            SettingsItemNoIcon(title: "Terms and Conditions")
                        }

                        NavigationLink(destination: CreditsView()) {
                            SettingsItemNoIcon(title: "Credits & Acknowledgements")
                        }
                    }
                    .padding(.horizontal)

                    // Contact Information
                    SettingsGroup(title: "Contact") {
                        Link(destination: URL(string: "mailto:kaibin.zhang.23@ucl.ac.uk")!) {
                            SettingsItemNoIcon(title: "Email Developer")
                        }
                        Link(destination: URL(string: "https://auth.support")!) {
                            SettingsItemNoIcon(title: "DashUCL Website")
                        }
                        Link(destination: URL(string: "https://uclapi.com")!) {
                            SettingsItemNoIcon(title: "UCL API Website")
                        }
                    }
                    .padding(.horizontal)

                    // Copyright
                    Text("© 2025 Kaibin Zhang\nAll Rights Reserved")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPrivacyPolicy) {
            SettingsPrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsAndConditions) {
            SettingsTermsAndConditionsView()
        }
    }
}

struct CreditsView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Development Team
                    SettingsGroup(title: "Developer") {
                        ForEach(
                            [
                                "zkb - Frontend Developer",
                                "zkb - Backend Developer",
                            ], id: \.self
                        ) { member in
                            HStack {
                                Text(member)
                                    .font(.system(size: 17))

                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)

                    // Acknowledgements
                    SettingsGroup(title: "Acknowledgements") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This app utilizes the following services:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            ForEach(
                                [
                                    "UCL API Services",
                                    "Supabase Cloud Services",
                                ], id: \.self
                            ) { item in
                                Text("• \(item)")
                                    .font(.system(size: 15))
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)

                    Text(
                        "Special thanks to the UCL API team for their insightful creation of UCL API, which still performs well years after its release."
                    )
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
