/*
 * Main container view that implements the app's tab-based navigation structure.
 * Manages navigation between Home, Timetable, Spaces, Search, and Settings tabs.
 * Integrates with NavigationManager for consistent navigation state across the app.
 * Implements custom tab bar styling and handles deep linking to specific views.
 */

//
//  HomeView.swift
//  DashUCL
//
//  Created by Zhang Kaibin on 17/02/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    // Control whether all tabs show navigation bar separator
    private let showNavBarDivider = true
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            TabView(selection: $viewModel.selectedTab) {
                HomeTabView()
                    .appStandardStatusBar(showDivider: showNavBarDivider)
                    .tabItem {
                        Label(
                            TabBarItem.home.title,
                            systemImage: TabBarItem.home.iconName)
                    }
                    .tag(TabBarItem.home)

                NavigationStack {
                    TimetableView()
                        .appStandardStatusBar(showDivider: showNavBarDivider)
                }
                .tabItem {
                    Label(
                        TabBarItem.timetable.title,
                        systemImage: TabBarItem.timetable.iconName)
                }
                .tag(TabBarItem.timetable)

                NavigationStack {
                    SpaceView()
                        .appStandardStatusBar(showDivider: showNavBarDivider)
                }
                .tabItem {
                    Label(
                        TabBarItem.spaces.title,
                        systemImage: TabBarItem.spaces.iconName)
                }
                .tag(TabBarItem.spaces)
            }
            .tint(viewModel.selectedTab.color)
            .toolbar(.visible, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .uclStructure:
                    UCLHierarchyView()
                case .organizationUnit(let id):
                    organizationUnitDestinationView(id: id)
                case .departmentExplore(let id):
                    departmentExploreDestinationView(id: id)
                case .roomDetail(let id):
                    Text("Room Detail: \(id)")
                case .spaceDetail(let id):
                    if id == SpaceView.SpaceCategory.studySpaces.rawValue {
                        SpaceListDetailView(category: .studySpaces)
                    } else if id == SpaceView.SpaceCategory.computerClusters.rawValue {
                        SpaceListDetailView(category: .computerClusters)
                    } else {
                        Text("Unknown Space Category: \(id)")
                    }
                case .studySpaces:
                    SpaceView()
                case .settings:
                    SettingView()
                case .search:
                    SearchView()
                default:
                    EmptyView()
                }
            }
            .onChange(of: navigationManager.activeDestination) { oldValue, newDestination in
                switch newDestination {
                case .search, .uclStructure, .studySpaces, .settings:
                    // These views are navigated through navigationDetail, no need to switch tabs
                    // Note: Do not perform any navigation operations here to avoid duplicate navigation
                    break
                case .timetable:
                    viewModel.selectedTab = .timetable
                case .spaces:
                    viewModel.selectedTab = .spaces
                default:
                    break
                }
            }
        }
        .environmentObject(navigationManager)
    }

    private func organizationUnitDestinationView(id: String) -> some View {
        print("Attempting to navigate to organization unit, ID: \(id)")

        if let unit = UCLOrganizationRepository.shared.getUnit(byID: id) {
            print("Found organization unit: \(unit.name), ID: \(id), type: \(unit.type.rawValue)")
            // Use DepartmentExploreView to display organization unit details
            return AnyView(DepartmentExploreView(currentUnit: unit))
        } else {
            print("Organization unit not found, ID: \(id), using UCL root organization")
            // When specified ID is not found, open DepartmentExploreView using UCL root organization unit
            if let uclUnit = UCLOrganizationRepository.shared.getUnit(byID: "UCL") {
                return AnyView(DepartmentExploreView(currentUnit: uclUnit))
            } else {
                // Only show error view if even the UCL root organization cannot be found (which rarely happens)
                return AnyView(
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)

                        Text("Organization unit not found")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("ID: \(id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                )
            }
        }
    }

    private func departmentExploreDestinationView(id: String) -> some View {
        print("Attempting to navigate to department explore view, ID: \(id)")

        if let unit = UCLOrganizationRepository.shared.getUnit(byID: id) {
            print(
                "Found organization unit for department explore: \(unit.name), ID: \(id), type: \(unit.type.rawValue)"
            )
            // Add extra logging for specific departments
            print(
                "Special note: Successfully found Division of Biosciences (BIOSC_LIF), creating DepartmentExploreView"
            )
            return AnyView(DepartmentExploreView(currentUnit: unit))
        } else {
            print("Organization unit not found, ID: \(id), using UCL root organization")
            // When specified ID is not found, use UCL root organization unit
            if let uclUnit = UCLOrganizationRepository.shared.getUnit(byID: "UCL") {
                print("Using UCL root organization unit as fallback")
                return AnyView(DepartmentExploreView(currentUnit: uclUnit))
            } else {
                // Only show error view if even the UCL root organization cannot be found (this rarely happens)
                print("Critical error: UCL root organization not found!")
                return AnyView(
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)

                        Text("Department not found")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("ID: \(id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                )
            }
        }
    }
}

#Preview {
    HomeView()
}
