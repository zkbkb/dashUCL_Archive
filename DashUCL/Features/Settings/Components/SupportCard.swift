import SwiftUI

struct SupportCard: View {
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Support & About")
                    .font(.title2)
                    .bold()

                ForEach(
                    [
                        ("Help & Support", "questionmark.circle.fill"),
                        ("Privacy Policy", "hand.raised.fill"),
                        ("Terms of Service", "doc.text.fill"),
                        ("About DashUCL", "info.circle.fill"),
                    ], id: \.0
                ) { item in
                    NavigationLink {
                        Text(item.0)
                    } label: {
                        Label(item.0, systemImage: item.1)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
}

#Preview {
    SupportCard()
        .padding()
}
