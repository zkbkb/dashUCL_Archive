import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// Person search result row component
struct PersonResultRow: View {
    let person: Features.Search.PersonResult
    @State private var showingEmailActions = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .trailing) {
            // Main content area
            HStack(spacing: 16) {
                // Vertical color bar
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 50)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 8) {
                    Text(person.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(person.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        if !person.department.isEmpty {
                            // Make department clickable for navigation to details
                            DepartmentDetailLinkView(departmentName: person.department)
                                .allowsHitTesting(true)  // Ensure clickable
                        }

                        if !person.position.isEmpty {
                            if !person.department.isEmpty {
                                // If there's department and position, add small separator dot
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(person.position)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 50)  // Ensure enough space for email button
            }

            // Email button - now placed at the top layer of ZStack
            if !person.email.isEmpty {
                Button(action: {
                    showingEmailActions = true
                }) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        .confirmationDialog("Contact Options", isPresented: $showingEmailActions) {
            Button("Copy Email Address") {
                #if canImport(UIKit)
                    UIPasteboard.general.string = person.email
                #endif
            }

            Button("Send Email") {
                openMail(to: person.email)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Contact \(person.name)")
        }
    }

    // Open mail application
    private func openMail(to email: String) {
        #if canImport(UIKit)
            if let url = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(url)
            }
        #endif
    }
}

#Preview {
    PersonResultRow(
        person: Features.Search.PersonResult(
            id: "test@ucl.ac.uk",
            name: "John Smith",
            email: "test@ucl.ac.uk",
            department: "Computer Science",
            position: "Professor"
        )
    )
    .padding()
}
