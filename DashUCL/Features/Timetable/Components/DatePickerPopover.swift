import SwiftUI

struct DatePickerPopover: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    @State private var tempDate: Date
    @Environment(\.colorScheme) private var colorScheme

    // Adjust size to better fit the streamlined date picker
    private let popoverWidth: CGFloat = 350
    private let popoverHeight: CGFloat = 350  // Reduced height since there's no confirm button
    private let cornerRadius: CGFloat = 24

    init(isPresented: Binding<Bool>, selectedDate: Binding<Date>) {
        self._isPresented = isPresented
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }

    // Normalize date, keep only year, month, and day components
    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }

    var body: some View {
        // Use fixed size geometry reader to ensure fixed dimensions
        GeometryReader { _ in
            VStack(spacing: 0) {
                // Date picker
                DatePicker(
                    "",
                    selection: $tempDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.mint)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)  // Even vertical padding
                .onChange(of: tempDate) { oldValue, newValue in
                    // When user selects a date, automatically apply and close the picker
                    if oldValue != newValue {
                        // Slightly delay for user to see selection effect
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Use normalized date
                            selectedDate = normalizeDate(tempDate)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isPresented = false
                            }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Material.ultraThickMaterial)
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1),
                        radius: 20, x: 0, y: 10
                    )
            )
            .frame(width: popoverWidth, height: popoverHeight)  // Fixed overall size
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))  // Use clipShape instead of clipped to keep corners
        }
        .frame(width: popoverWidth, height: popoverHeight)  // Ensure GeometryReader doesn't expand
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)

        DatePickerPopover(
            isPresented: .constant(true),
            selectedDate: .constant(Date())
        )
    }
}
