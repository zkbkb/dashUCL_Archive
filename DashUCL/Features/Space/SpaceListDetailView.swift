import SwiftUI

/// Space List Detail View
struct SpaceListDetailView: View {
    // MARK: - Properties
    let category: SpaceView.SpaceCategory
    @StateObject private var viewModel = SpaceViewModel.shared
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background color
            (colorScheme == .dark
                ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
                : Color(UIColor.systemBackground))
                .ignoresSafeArea()

            VStack {
                // Search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Content area
                if viewModel.isLoading && viewModel.allSpaces.isEmpty {
                    loadingView
                } else if filteredSpaces.isEmpty {
                    emptyResultsView
                } else {
                    listContent
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            print("[SpaceListDetailView] View appeared, checking if data needs to be loaded")
            // Check if data is already loaded
            if viewModel.allSpaces.isEmpty {
                print("[SpaceListDetailView] No cached data, start loading")
                await viewModel.loadInitialData()
            } else {
                print("[SpaceListDetailView] Using already loaded cached data")
            }
        }
    }

    // MARK: - Computed Properties

    /// Space list filtered by category and search
    private var filteredSpaces: [SpaceResult] {
        let spaces = viewModel.allSpaces.filter { space in
            // Apply search filter
            if !searchText.isEmpty {
                guard
                    space.name.lowercased().contains(searchText.lowercased())
                        || space.description.lowercased().contains(searchText.lowercased())
                else {
                    return false
                }
            }

            // Apply category filter
            switch category {
            case .studySpaces:
                // Match library spaces (Library Spaces)
                return space.name.lowercased().contains("library")
                    || space.description.lowercased().contains("library")
                    || space.name.lowercased().contains("[lib]")
                    || (!space.name.lowercased().contains("computer")
                        && !space.description.lowercased().contains("computer")
                        && !space.name.lowercased().contains("[isd]"))
            case .computerClusters:
                // Match computer clusters (ISD Spaces)
                return space.name.lowercased().contains("computer")
                    || space.description.lowercased().contains("computer")
                    || space.name.lowercased().contains("cluster")
                    || space.name.lowercased().contains("[isd]")
            }
        }

        // Sort by availability, show spaces with high availability first
        return spaces.sorted { $0.occupancyPercentage < $1.occupancyPercentage }
    }

    // MARK: - Components

    /// List content
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Show space list
                ForEach(filteredSpaces, id: \.id) { space in
                    StudySpaceResultRow(space: space)
                        .padding(.horizontal)
                }

                // Bottom space
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .refreshable {
            print("[SpaceListDetailView] User triggered pull-to-refresh, forcing data refresh")
            // Force data refresh, don't use cache
            viewModel.cacheEnabled = false
            await viewModel.refreshSpacesData()
            viewModel.cacheEnabled = true
            print("[SpaceListDetailView] Pull-to-refresh completed")
        }
    }

    /// Search bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search spaces", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        )
    }

    /// Loading view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading study spaces...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    /// Empty result view
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 100)
                )

            Text("No spaces found")
                .font(.title3)
                .fontWeight(.semibold)

            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No spaces available in this category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        SpaceListDetailView(category: .studySpaces)
    }
}
