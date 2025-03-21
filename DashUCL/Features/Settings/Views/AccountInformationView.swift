//
//  AccountInformationView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI

// MARK: - Information Row Component
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(4)
    }
}

// MARK: - Main View
struct AccountInformationView: View {
    @StateObject private var userModel = UserModel.shared
    @StateObject private var testEnvironment = TestEnvironment.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showGroups = false

    // 检查UPI和Username是否相同
    private var isUPIAndUsernameIdentical: Bool {
        getUCLID() == getUsername()
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Personal Information Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Personal Information")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)

                        VStack(spacing: 1) {
                            InfoRow(label: "Full Name", value: getFullName())
                            InfoRow(label: "Email", value: getEmail())
                            InfoRow(label: "Department", value: getDepartment())
                            InfoRow(label: "User Type", value: getUserType())
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal)

                    // UCL Account Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UCL Account Information")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)

                        VStack(spacing: 1) {
                            InfoRow(label: "UPI", value: getUCLID())

                            // 只有当UPI和Username不同时才显示Username
                            if !isUPIAndUsernameIdentical {
                                InfoRow(label: "Username", value: getUsername())
                            }

                            InfoRow(label: "Status", value: "Active")
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal)

                    // Groups Section - In-place expandable
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UCL Groups")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)

                        VStack(spacing: 1) {
                            DisclosureGroup(
                                isExpanded: $showGroups,
                                content: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(getUserGroups().sorted(), id: \.self) { group in
                                            Text(group)
                                                .font(.footnote)
                                                .padding(.vertical, 2)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                },
                                label: {
                                    Text("UCL Groups (For Developers)")
                                        .font(.subheadline)
                                }
                            )
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(4)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("UCL Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Helper methods to get user information
    private func getFullName() -> String {
        return testEnvironment.isTestMode
            ? testEnvironment.mockUserProfile.fullName : userModel.fullName
    }

    private func getEmail() -> String {
        return testEnvironment.isTestMode ? testEnvironment.mockUserProfile.email : userModel.email
    }

    private func getDepartment() -> String {
        return testEnvironment.isTestMode
            ? testEnvironment.mockUserProfile.department : userModel.department
    }

    private func getUserType() -> String {
        let groups =
            testEnvironment.isTestMode
            ? testEnvironment.mockUserProfile.uclGroups : userModel.uclGroups

        if groups.contains("ucl-ug") || groups.contains("all-ug") {
            return "Undergraduate Student"
        } else if groups.contains("ucl-pg") || groups.contains("all-pg") {
            return "Postgraduate Student"
        } else if groups.contains("ucl-staff") {
            return "Staff Member"
        } else {
            return "UCL Member"
        }
    }

    private func getUCLID() -> String {
        return testEnvironment.isTestMode ? testEnvironment.mockUserProfile.upi : userModel.upi
    }

    private func getUsername() -> String {
        return testEnvironment.isTestMode ? testEnvironment.mockUserProfile.cn : userModel.cn
    }

    private func getUserGroups() -> [String] {
        return testEnvironment.isTestMode
            ? testEnvironment.mockUserProfile.uclGroups : userModel.uclGroups
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AccountInformationView()
    }
}
