//
//  HelpSupportView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/03/2025.
//

import SwiftUI
import UIKit

// Import MessageUI conditionally to avoid issues with previews
#if canImport(MessageUI)
    import MessageUI
#endif

// Add app icon display utility
struct AppIconView: View {
    @Environment(\.colorScheme) private var colorScheme
    var size: CGFloat = 80

    var body: some View {
        Group {
            if let iconImage = UIImage(
                named: colorScheme == .dark ? "InAppIconDark" : "InAppIconLight")
            {
                Image(uiImage: iconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                // Fallback mechanism: if direct loading fails, try different name formats
                Image(colorScheme == .dark ? "InAppIcon/InAppIconDark" : "InAppIcon/InAppIconLight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .onAppear {
            // Try multiple formats with debug output
            #if DEBUG
                // Try multiple formats with debug output
                let directName = colorScheme == .dark ? "InAppIconDark" : "InAppIconLight"
                let pathName =
                    colorScheme == .dark ? "InAppIcon/InAppIconDark" : "InAppIcon/InAppIconLight"

                print("Loading app icon - Direct name: \(directName)")
                print("Loading app icon - Path name: \(pathName)")

                if UIImage(named: directName) == nil {
                    print("⚠️ Direct app icon not found: \(directName)")
                } else {
                    print("✅ Direct app icon found: \(directName)")
                }

                if UIImage(named: pathName) == nil {
                    print("⚠️ Path app icon not found: \(pathName)")
                } else {
                    print("✅ Path app icon found: \(pathName)")
                }
            #endif
        }
    }
}

struct HelpSupportView: View {
    @State private var showContactForm = false
    @State private var showMailView = false
    @State private var showMailError = false
    @Environment(\.colorScheme) private var colorScheme

    // Email configuration
    private let supportEmail = "kaibin.zhang.23@ucl.ac.uk"

    // Check if mail can be sent
    private var canSendMail: Bool {
        #if canImport(MessageUI)
            return MFMailComposeViewController.canSendMail()
        #else
            return false
        #endif
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Contact Support Section
                    contactSupportSection
                        .padding(.top, 8)

                    // UCL Support Resources
                    uclResourcesSection

                    // App Information with Logo
                    appInfoSection
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactForm) {
            ContactSupportView(supportEmail: supportEmail)
        }
        // Only show mail view if MessageUI is available
        #if canImport(MessageUI)
            .sheet(isPresented: $showMailView) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(
                        supportEmail: supportEmail, subject: "DashUCL Support",
                        showMailError: $showMailError)
                }
            }
        #endif
        .alert("Email Not Available", isPresented: $showMailError) {
            Button("OK", role: .cancel) {}
            Button("Copy Email") {
                UIPasteboard.general.string = supportEmail
            }
        } message: {
            Text(
                "It seems your device doesn't have mail configured. You can send an email to \(supportEmail) manually."
            )
        }
    }

    // MARK: - View Components

    private var contactSupportSection: some View {
        VStack(spacing: 0) {
            Text("How can we help?")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Contact Form Button
            Button(action: {
                showContactForm = true
            }) {
                HStack {
                    Text("Contact Form")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)

            // Email Button
            Button(action: {
                if canSendMail {
                    showMailView = true
                } else {
                    showMailError = true
                }
            }) {
                HStack {
                    Text("Email Support")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
    }

    private var uclResourcesSection: some View {
        VStack(spacing: 0) {
            Text("UCL Resources")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                // UCL Student Support
                Link(destination: URL(string: "https://www.ucl.ac.uk/students/")!) {
                    HStack {
                        Text("UCL Student Support")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.leading, 16)

                // UCL Library Services
                Link(destination: URL(string: "https://www.ucl.ac.uk/library/using-library")!) {
                    HStack {
                        Text("UCL Library Services")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    private var appInfoSection: some View {
        VStack(alignment: .center, spacing: 16) {
            // Use AppIconView
            AppIconView(size: 80)
                .padding(.top, 8)

            Text("dashUCL")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Your all-in-one UCL student companion app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Divider()
                .padding(.horizontal, 40)

            HStack(spacing: 30) {
                VStack {
                    Text("Version")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("1.0.")
                        .font(.system(size: 15, weight: .medium))
                }

                VStack {
                    Text("Build")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("2025.03.20")
                        .font(.system(size: 15, weight: .medium))
                }

                VStack {
                    Text("Release")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Beta")
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .padding(.bottom, 16)

            // Copyright Info
            Text("© 2025 Kaibin Zhang.")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.bottom, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Contact Form

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var showAlert = false
    @State private var isLoading = false
    let supportEmail: String

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section(header: Text("Message")) {
                    TextField("Subject", text: $subject)

                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Describe your issue or question...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: $message)
                            .frame(minHeight: 150)
                    }
                }

                Section {
                    Button(action: {
                        isLoading = true
                        // Simulate sending message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                            showAlert = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Message")
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.green)
                    .disabled(isLoading || name.isEmpty || email.isEmpty || message.isEmpty)
                }

                Section(footer: Text("Your message will be sent to \(supportEmail)")) {
                    // Empty section for footer only
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Message Sent", isPresented: $showAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your message. We'll get back to you as soon as possible.")
            }
        }
    }
}

// MARK: - Mail View
// Only include MailView when MessageUI is available
#if canImport(MessageUI)
    struct MailView: UIViewControllerRepresentable {
        let supportEmail: String
        let subject: String
        @Binding var showMailError: Bool
        @Environment(\.presentationMode) var presentation

        class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
            @Binding var presentation: PresentationMode
            @Binding var showMailError: Bool

            init(presentation: Binding<PresentationMode>, showMailError: Binding<Bool>) {
                _presentation = presentation
                _showMailError = showMailError
            }

            func mailComposeController(
                _ controller: MFMailComposeViewController,
                didFinishWith result: MFMailComposeResult,
                error: Error?
            ) {
                if result == .failed && error != nil {
                    showMailError = true
                }
                $presentation.wrappedValue.dismiss()
            }
        }

        func makeCoordinator() -> Coordinator {
            return Coordinator(presentation: presentation, showMailError: $showMailError)
        }

        func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>)
            -> MFMailComposeViewController
        {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = context.coordinator
            vc.setToRecipients([supportEmail])
            vc.setSubject(subject)
            return vc
        }

        func updateUIViewController(
            _ uiViewController: MFMailComposeViewController,
            context: UIViewControllerRepresentableContext<MailView>
        ) {
            // No updates needed
        }
    }
#endif

#Preview {
    NavigationStack {
        HelpSupportView()
    }
}
