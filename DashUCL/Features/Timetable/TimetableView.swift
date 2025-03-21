/*
 * Interactive timetable view for displaying UCL class schedules with weekly calendar navigation.
 * Features expandable event cards with detailed course information and location integration.
 * Implements pull-to-refresh functionality, date selection, and smooth transitions between views.
 * Uses MVVM architecture with optimized rendering for performance with large event lists.
 */

// Import theme constants
import MapKit
// Import RefreshableView component
import SwiftUI
import UIKit

// LoadingCircleView is located in DashUCL/UI/Components/LoadingCircleView.swift

struct TimetableView: View {
    @StateObject private var viewModel = TimetableViewModel()
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String? = nil
    @State private var isViewAppeared = false
    @State private var contentViewRefreshID = UUID()  // Add a state variable to force refresh content view
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var navigationManager = NavigationManager.shared

    // Date picker top offset (calculated from bottom of week calendar)
    private let datePickerTopOffset: CGFloat = 16

    private var monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    // Normalize date, keep only year, month, and day components
    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }

    var body: some View {
        ZStack {
            // Main content view - remove NavigationStack
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // -- Background content --
                    ThemeConstants.primaryBackground
                        .frame(height: geometry.size.height)
                        .zIndex(0)

                    // -- Main content --
                    VStack(spacing: 0) {  // Add VStack consistent with SpaceView
                        // Condition: If loading and no event data, show loading view
                        if viewModel.isLoading && viewModel.selectedDateEvents.isEmpty {
                            // Use LoadingCircleView directly in main content area
                            LoadingCircleView(
                                title: "Loading Timetable",
                                description: "Fetching your class schedule"
                            )
                            .onAppear {
                                print("[TimetableView] Showing loading indicator")
                            }
                        } else {
                            // Put all content into ScrollView, including month selector
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 12) {  // Reduce overall spacing
                                    // Month display area - move into ScrollView
                                    HStack {
                                        // Left month display area
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                showDatePicker.toggle()
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Text(monthYearFormatter.string(from: selectedDate))
                                                    .font(.title3.bold())
                                                    .foregroundColor(.primary)

                                                Image(systemName: "chevron.down")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .rotationEffect(
                                                        Angle(degrees: showDatePicker ? 180 : 0))
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background {
                                                Capsule()
                                                    .fill(Color(.systemGray6).opacity(0.7))
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Spacer()

                                        // Show loading status indicator (instead of refresh button)
                                        if viewModel.isLoading {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .font(.body)
                                                Text("Updating")
                                                    .font(.footnote)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .foregroundColor(.secondary)
                                            .background {
                                                Capsule()
                                                    .strokeBorder(
                                                        Color.secondary.opacity(0.3),
                                                        lineWidth: 1.5
                                                    )
                                            }
                                            .opacity(0.7)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 20)  // Top increase spacing to make month year display further from title bar

                                    // Week calendar view - stay in ScrollView
                                    WeekCalendarView(
                                        selectedDate: $selectedDate,
                                        showDatePicker: $showDatePicker,
                                        hasEvents: viewModel.hasEvents(on:)
                                    )
                                    .padding(.horizontal)
                                    .padding(.top, 4)  // Reduce distance from month selector
                                    .zIndex(2)

                                    // Course content area, cancel independent contentView component
                                    if !viewModel.isLoading {
                                        // Only show EventsContentView in non-loading state
                                        EventsContentView(
                                            events: viewModel.selectedDateEvents,
                                            selectedDate: selectedDate,
                                            colorForEventType: viewModel.colorForEventType,
                                            refreshID: contentViewRefreshID
                                        )
                                        .id(contentViewRefreshID)  // Add ID to the entire content area to ensure reconstruction during refresh
                                        .padding(.top, 8)  // Reduce distance with week calendar view
                                    }
                                }
                            }
                            .zIndex(1)
                            .id(contentViewRefreshID)  // Add ID to the entire content area to ensure reconstruction during refresh
                        }
                    }
                }
            }
            .navigationTitle("Timetable")
            .navigationBarTitleDisplayMode(.large)
            .appStandardStatusBar()
            .onChange(of: selectedDate) { oldValue, newValue in
                if oldValue != newValue {
                    // Ensure to update events using normalized date
                    let normalizedDate = normalizeDate(newValue)

                    // Add log output
                    #if DEBUG
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        print(
                            "[TimetableView] Date changed to \(dateFormatter.string(from: newValue))"
                        )
                    #endif

                    // Use Task to wrap update operation, avoid UI thread blocking
                    Task {
                        // Update events
                        viewModel.updateEventsForDate(normalizedDate)

                        // Force refresh content view
                        await MainActor.run {
                            contentViewRefreshID = UUID()
                        }
                    }
                }
            }
            .onChange(of: navigationManager.timetableSelectedDate) { oldValue, newValue in
                // Ensure date actually changed
                if Calendar.current.startOfDay(for: oldValue)
                    != Calendar.current.startOfDay(for: newValue)
                {
                    // Update selected date
                    selectedDate = newValue

                    #if DEBUG
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        print(
                            "[TimetableView] NavigationManager date changed to \(dateFormatter.string(from: newValue))"
                        )
                    #endif
                }
            }
            .alert("Loading Failed", isPresented: $showErrorAlert) {
                Button("OK") { showErrorAlert = false }
            } message: {
                Text(errorMessage ?? viewModel.errorMessage ?? "Unable to load timetable data")
            }
            .onAppear {
                // Mark view has appeared
                if !isViewAppeared {
                    isViewAppeared = true

                    // Delay loading a bit to ensure view is fully mounted
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        Task {
                            do {
                                try await viewModel.fetchTimetable()

                                // Ensure initial load uses normalized date
                                await MainActor.run {
                                    let normalizedDate = normalizeDate(selectedDate)
                                    viewModel.updateEventsForDate(normalizedDate)
                                }
                            } catch {
                                // Use ErrorHelper to handle error
                                await MainActor.run {
                                    let errorDesc = error.localizedDescription
                                    // Check if it's an authentication error
                                    let isAuthError =
                                        errorDesc.contains("Authentication required")
                                        || errorDesc.contains("Unauthorized")
                                        || errorDesc.contains("Token")
                                        || errorDesc.contains("access token")

                                    if !isAuthError || !viewModel.isTestMode {
                                        errorMessage = errorDesc
                                        showErrorAlert = true
                                    } else {
                                        print("Suppressed auth error alert: \(errorDesc)")
                                    }
                                }
                            }
                        }
                    }
                }

                // Check if there's a date set from another view
                if Calendar.current.startOfDay(for: navigationManager.timetableSelectedDate)
                    != Calendar.current.startOfDay(for: selectedDate)
                {
                    // Update selected date
                    selectedDate = navigationManager.timetableSelectedDate
                }
            }

            // Click blank area to close transparent overlay for date picker
            if showDatePicker {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showDatePicker = false
                        }
                    }
                    .zIndex(90)
            }

            // Date picker modal layer - only show when showDatePicker is true
            if showDatePicker {
                DatePickerPopover(
                    isPresented: $showDatePicker,
                    selectedDate: $selectedDate
                )
                .offset(y: -40)  // Move selector position up
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }

    // MARK: - Component extraction

    // "time ago" string conversion function
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Events Content View
struct EventsContentView: View {
    let events: [TimetableEvent]
    let selectedDate: Date
    let colorForEventType: (String, String) -> Color
    let refreshID: UUID  // Add a refreshID parameter to force refresh view

    // Add cache property to avoid repeated calculations
    private let formattedDate: String

    // Add state variable to control event list lazy loading
    @State private var isViewReady = false
    // Add state variable to track current expanded card ID to ensure only one card is expanded at a time
    @State private var expandedCardId: String? = nil
    // Add state variable to prevent repeated clicks during animation
    @State private var isAnimating = false

    init(
        events: [TimetableEvent], selectedDate: Date,
        colorForEventType: @escaping (String, String) -> Color, refreshID: UUID
    ) {
        self.events = events
        self.selectedDate = selectedDate
        self.colorForEventType = colorForEventType
        self.refreshID = refreshID

        // Pre-calculate date format string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.formattedDate = dateFormatter.string(from: selectedDate)
    }

    var body: some View {
        if events.isEmpty {
            emptyEventsView
        } else {
            eventsListView
        }
    }

    // Extract empty events view as separate component
    private var emptyEventsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Classes Scheduled")
                .font(.headline)

            Text("No classes or activities scheduled for this day")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Add frame modifier to ensure entire view is centered
        .background(Color(.systemBackground))  // Add background color to adapt to dark mode
        .onAppear {
            #if DEBUG
                print("[TimetableView] Showing 'No Classes' view for date: \(formattedDate)")
            #endif
        }
    }

    // Extract events list view as separate component - optimize performance
    private var eventsListView: some View {
        ScrollView {
            // Background
            Color.clear
                .onAppear {
                    // Optimize lazy loading logic to reduce unnecessary state updates
                    if !isViewReady {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isViewReady = true
                        }
                    }
                }

            if isViewReady {
                eventsContentStack
            } else {
                // Show loading indicator
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color(.systemBackground))
            }
        }
        // Use more precise condition to disable scrolling
        .scrollDisabled(events.count <= 3)
        // Reduce unnecessary log output
        .onAppear {
            #if DEBUG
                print("[TimetableView] Showing \(events.count) events")
            #endif
        }
    }

    // Extract events content stack as separate component - optimize rendering performance
    private var eventsContentStack: some View {
        // Use LazyVStack to lazily render only visible content
        LazyVStack(spacing: 16) {
            // Directly use events as ForEach data source to avoid conversion overhead
            ForEach(events) { event in
                // Use event's id property instead of UUID string to reduce string operation overhead
                EventCardView(
                    event: event,
                    eventColor: colorForEventType(event.sessionType, event.sessionTypeStr),
                    isExpanded: expandedCardId == event.id.uuidString,
                    onToggleExpand: toggleCardExpansion
                )
                .padding(.horizontal)
                // Use stable ID to avoid unnecessary view reconstruction
                .id(event.id)
            }
        }
        .padding(.vertical)
        // Use simpler animation to reduce performance overhead
        .animation(.default, value: isViewReady)
    }

    // Optimized card expansion logic, use Task and MainActor to ensure animation completes correctly
    private func toggleCardExpansion(id: String) {
        // If already animating, return immediately to prevent repeated triggering
        guard !isAnimating else { return }

        // Set animation flag
        isAnimating = true

        // Create a Task to allow asynchronous processing
        Task { @MainActor in
            // Use withAnimation for animation
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                // Use simple condition switch to reduce calculation complexity
                expandedCardId = (expandedCardId == id) ? nil : id
            }

            // Add small delay to ensure animation has enough time to complete
            try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

            // Reset flag after animation completes
            isAnimating = false
        }
    }
}

// MARK: - Event Card View
struct EventCardView: View {
    // Immutable properties
    let event: TimetableEvent
    let eventColor: Color
    let isExpanded: Bool
    let onToggleExpand: (String) -> Void

    // State properties
    @State private var isPressed = false
    @State private var showingMapAlert = false
    @Environment(\.colorScheme) private var colorScheme

    // Calculated properties
    private let eventIdString: String
    private let timeRange: String

    // Performance optimization: Pre-calculate time format
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    init(
        event: TimetableEvent,
        eventColor: Color,
        isExpanded: Bool,
        onToggleExpand: @escaping (String) -> Void
    ) {
        self.event = event
        self.eventColor = eventColor
        self.isExpanded = isExpanded
        self.onToggleExpand = onToggleExpand
        self.eventIdString = event.id.uuidString

        // Pre-calculate time range
        self.timeRange =
            "\(Self.timeFormatter.string(from: event.startTime)) - \(Self.timeFormatter.string(from: event.endTime))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: 0) {
                // Top time bar - new design element
                HStack(spacing: 0) {
                    // Left time display
                    HStack(spacing: 6) {
                        Text(Self.timeFormatter.string(from: event.startTime))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("-")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))

                        Text(Self.timeFormatter.string(from: event.endTime))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Spacer()

                    // Right course type tag
                    Text(event.sessionTypeStr)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(
                    LinearGradient(
                        colors: [eventColor, eventColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16, corners: [.topLeft, .topRight])

                // Main content area
                VStack(alignment: .leading, spacing: 12) {  // Increase internal element spacing
                    // Course name and expand/fold indicator
                    HStack(alignment: .top) {
                        // Course name
                        Text(event.module.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Expand/fold indicator
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .padding(.top, 16)  // Increase top internal padding

                    // Location information
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(eventColor.opacity(0.8))

                        // Location name and address first line
                        Text(
                            !event.location.address.isEmpty
                                ? "\(event.location.name), \(event.location.address.first ?? "")"
                                : event.location.name
                        )
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    }
                    .padding(.bottom, isExpanded ? 4 : 16)  // Increase bottom internal padding

                    // Expanded detailed information - use lazy loading
                    if isExpanded {
                        Divider()
                            .padding(.vertical, 8)

                        // Use LazyVStack to reduce一次性布局计算
                        LazyVStack(alignment: .leading, spacing: 16) {
                            detailsView
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark
                        ? Color(.systemGray6).opacity(0.7)
                        : Color(.systemBackground)
                )
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                    radius: 5, x: 0, y: 2
                )
        )
        .overlay(
            // Add a thin border
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(eventColor.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        // Simplified animation to reduce performance overhead
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        // Optimize click handling
        .onTapGesture {
            // Simplified click handling, use Task to delay expansion operation
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }

            // Use Task to separate UI feedback and expansion operation
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds delay
                isPressed = false
                onToggleExpand(eventIdString)
            }
        }
        // Add back alert for accidentally deleted
        .alert("Open in Maps", isPresented: $showingMapAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Open") {
                openLocationInMaps()
            }
        } message: {
            Text("Would you like to view this location in Maps?")
        }
    }

    // Detailed information view - simplified layout and rendering
    private var detailsView: some View {
        Group {
            // Use more compact layout to reduce view hierarchy
            VStack(alignment: .leading, spacing: 12) {
                // Only show corresponding information when there's a value
                if !event.sessionTitle.isEmpty {
                    detailRow(label: "Session", value: event.sessionTitle)
                }

                detailRow(label: "Department", value: event.module.departmentName)

                detailRow(label: "Module ID", value: event.module.moduleId)

                if !event.contact.isEmpty {
                    detailRow(label: "Contact", value: event.contact)
                }

                if !event.module.lecturer.email.isEmpty {
                    detailRow(label: "Email", value: event.module.lecturer.email)
                }

                // Address information - optimize rendering
                if !event.location.address.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        // Limit address display to 3 lines, reduce large rendering
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(event.location.address.prefix(3), id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }

                            // If address exceeds 3 lines, show "more..."
                            if event.location.address.count > 3 {
                                Text("+ \(event.location.address.count - 3) more lines")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
            }

            // Bottom button area - optimize rendering, reduce nested level
            HStack {
                Spacer()

                Button(action: {
                    openInMaps()
                }) {
                    Label("View in Maps", systemImage: "map.fill")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(eventColor.opacity(0.1))
                        )
                        .foregroundColor(eventColor)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)  // Increase bottom internal padding
        }
    }

    // Detail row component - optimize to single VStack
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // Handle click event - no longer used, merged into onTapGesture
    private func handleTap() {
        // Use simpler animation handling to reduce performance overhead
        isPressed = true

        // Use shorter delay time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
            onToggleExpand(eventIdString)
        }
    }

    // Open map
    private func openInMaps() {
        // Show confirmation dialog
        showingMapAlert = true
    }

    // Actual method to open map
    private func openLocationInMaps() {
        // Get address information
        let locationName = event.location.name
        let address = event.location.address.joined(separator: ", ")

        // Create map URL
        var urlComponents = URLComponents(string: "http://maps.apple.com/")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: "\(locationName), \(address)")
        ]

        if let url = urlComponents?.url {
            // Open map application
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    TimetableView()
}
