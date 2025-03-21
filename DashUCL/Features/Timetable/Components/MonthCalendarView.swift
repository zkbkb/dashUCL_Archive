import SwiftUI

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonthOffset = 0
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    // Update month formatter
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private var monthDays: [Date?] {
        let start = startOfMonth
        let firstWeekday = calendar.component(.weekday, from: start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: start)?.count ?? 0

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in 1...daysInMonth {
            if let date = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: start) {
                if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: date) {
                    days.append(dayDate)
                }
            }
        }

        let remainingDays = 42 - days.count
        days.append(contentsOf: Array(repeating: nil, count: remainingDays))

        return days
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation bar
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                        .imageScale(.medium)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(monthFormatter.string(from: startOfMonth))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .imageScale(.medium)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.bottom, 8)

            // Calendar main section
            VStack(spacing: 12) {
                // Weekday headers
                HStack {
                    ForEach(daysInWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }

                // Calendar grid - Modern design
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            }
                        } else {
                            Color.clear
                                .frame(height: 36)
                        }
                    }
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.5))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { gesture in
                    let isLeftSwipe = gesture.translation.width < 0
                    withAnimation(.spring(response: 0.3)) {
                        if isLeftSwipe {
                            nextMonth()
                        } else {
                            previousMonth()
                        }
                    }
                }
        )
    }

    private var startOfMonth: Date {
        let today = Date()
        var components = calendar.dateComponents([.year, .month], from: today)
        components.day = 1
        guard let startDate = calendar.date(from: components) else { return today }
        return calendar.date(byAdding: .month, value: currentMonthOffset, to: startDate) ?? today
    }

    private func nextMonth() {
        withAnimation(.spring(response: 0.3)) {
            currentMonthOffset += 1
        }
    }

    private func previousMonth() {
        withAnimation(.spring(response: 0.3)) {
            currentMonthOffset -= 1
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 36, height: 36)
            } else if isToday {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 1.5)
                    .frame(width: 36, height: 36)
            }

            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

extension Calendar {
    fileprivate func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

#Preview {
    MonthCalendarView(selectedDate: .constant(Date()))
        .padding()
}
