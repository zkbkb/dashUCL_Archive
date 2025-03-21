import SwiftUI

struct TestModeToggleView: View {
    @ObservedObject private var testEnvironment = TestEnvironment.shared

    var body: some View {
        #if DEBUG
            HStack(spacing: 10) {
                //Text("Test")
                   // .font(.caption)
                 //   .foregroundColor(.secondary)

                Toggle("", isOn: $testEnvironment.isTestMode)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
       //     .padding(4)
            .background(Color(UIColor.systemBackground).opacity(0.8))
            .cornerRadius(8)
            .shadow(radius: 2)
        #endif
    }
}
