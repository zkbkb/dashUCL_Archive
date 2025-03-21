import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekDates: [Date] = []
    @Binding var showDatePicker: Bool
    var hasEvents: ((Date) -> Bool)? = nil

    private let calendar = Calendar.current
    private let weekDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return formatter
    }()

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    // Add week formatter
    private let weekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            // Week navigation bar - Overall design improvement, remove edge separators
            ZStack {
                // Overall background - Remove explicit boundaries of Material background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial.opacity(0.8))  // Reduce opacity to make edges more blurry

                HStack(spacing: 0) {
                    // Forward button - No background, blend into overall design
                    Button(action: previousWeek) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.secondary)
                            .imageScale(.medium)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Subtle separator - Reduce opacity to make it more subtle
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))  // Reduce opacity
                        .frame(width: 1, height: 20)

                    Spacer()

                    // Week information display - Centered
                    Text(
                        "\(weekFormatter.string(from: startOfWeek)) - \(weekFormatter.string(from: endOfWeek))"
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                    Spacer()

                    // Subtle separator - Reduce opacity to make it more subtle
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))  // Reduce opacity
                        .frame(width: 1, height: 20)

                    // Backward button - No background, blend into overall design
                    Button(action: nextWeek) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .imageScale(.medium)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 44)
            // Remove shadow effect to reduce edge feeling
            // .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

            // Week view - More modern design
            HStack(spacing: 8) {
                ForEach(0..<7) { index in
                    if index < currentWeekDates.count {
                        let date = currentWeekDates[index]
                        ModernDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEvents: hasEvents?(date) == true
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Initialize current week dates
            updateWeekDates()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // When selected date changes, check if you need to update week view
            if !isDateInCurrentWeek(newValue) {
                updateWeekDates()
            }
        }
    }

    // Check if date is in current week
    private func isDateInCurrentWeek(_ date: Date) -> Bool {
        return currentWeekDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    // Update current week dates array
    private func updateWeekDates() {
        // Get start date of selected date's week (Sunday or Monday, depending on user calendar settings)
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Set Monday as the first day of the week

        let dateComponents = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        guard let startDate = calendar.date(from: dateComponents) else { return }

        // Generate week dates
        var weekDates: [Date] = []
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: startDate) {
                weekDates.append(normalizeDate(date))
            }
        }

        currentWeekDates = weekDates
    }

    // Normalize date, only keep year, month, and day components
    private func normalizeDate(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }

    private var startOfWeek: Date {
        return currentWeekDates.first ?? selectedDate
    }

    private var endOfWeek: Date {
        return currentWeekDates.last ?? selectedDate
    }

    private func previousWeek() {
        withAnimation(.spring(response: 0.3)) {
            if let firstDate = currentWeekDates.first,
                let newDate = calendar.date(byAdding: .day, value: -7, to: firstDate)
            {
                selectedDate = newDate
                updateWeekDates()
            }
        }
    }

    private func nextWeek() {
        withAnimation(.spring(response: 0.3)) {
            if let firstDate = currentWeekDates.first,
                let newDate = calendar.date(byAdding: .day, value: 7, to: firstDate)
            {
                selectedDate = newDate
                updateWeekDates()
            }
        }
    }
}

private struct ModernDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let calendar = Calendar.current
    private let weekDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 8) {
            // Day of week
            Text(weekDayFormatter.string(from: date))
                .font(.system(size: 13, weight: isToday || isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .mint : .secondary))

            // Date
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : (isToday ? .mint : .primary))

            // Event indicator
            if hasEvents {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.8) : Color.mint)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(getBackgroundFill())
        )
        // Only add subtle shadow for selected state, remove edge feeling
        .shadow(
            color: isSelected ? Color.mint.opacity(0.2) : .clear,
            radius: 4, x: 0, y: 2
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // Create a method to return the correct background fill
    private func getBackgroundFill() -> some ShapeStyle {
        if isSelected {
            return Color.mint  // Use fill color for selected state
        } else if isToday {
            return Color.mint.opacity(0.15)  // Use light fill for today
        } else {
            // More transparent background for normal dates, reduce edge feeling
            return Color(.systemBackground).opacity(0.5)
        }
    }
}

#Preview {
    WeekCalendarView(
        selectedDate: .constant(Date()),
        showDatePicker: .constant(false),
        hasEvents: { date in
            // Simulate events on Monday, Wednesday and Friday
            let weekday = Calendar.current.component(.weekday, from: date)
            return weekday == 2 || weekday == 4 || weekday == 6
        }
    )
    .padding()
}
