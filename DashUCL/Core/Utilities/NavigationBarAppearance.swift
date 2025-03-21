/*
 * Utility for configuring global navigation bar appearance across the app.
 * Sets up consistent styling for dark and light mode navigation bars.
 * Applies appropriate background colors, text attributes, and button styling.
 * Ensures navigation elements maintain UCL brand identity and accessibility standards.
 */

//
//  NavigationBarAppearance.swift
//  DashUCL
//  Created on 2025-03-15
//

import SwiftUI
import UIKit

// Global navigation bar appearance settings
struct NavigationBarAppearance {
    static func configure() {
        // Create a standard navigation bar appearance object
        let standardAppearance = UINavigationBarAppearance()
        // Use default transparent background configuration instead of default background
        standardAppearance.configureWithOpaqueBackground()

        // Configure navigation bar in standard mode - Use appropriate background color based on color mode
        if UITraitCollection.current.userInterfaceStyle == .dark {
            // Dark mode uses standard dark gray (RGB: 28, 28, 30)
            standardAppearance.backgroundColor = UIColor(
                red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
            // Ensure text and icons are visible on dark background
            standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            // Light mode uses system background color
            standardAppearance.backgroundColor = .systemBackground
            // Light mode uses system text color
            standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        }
        standardAppearance.shadowColor = .clear  // Remove bottom shadow

        // Create scroll edge appearance - Use the same settings, no longer use transparent effect
        // This solves the problem of the navigation bar turning black when scrolling
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithOpaqueBackground()

        if UITraitCollection.current.userInterfaceStyle == .dark {
            scrollEdgeAppearance.backgroundColor = UIColor(
                red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
            scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            scrollEdgeAppearance.backgroundColor = .systemBackground
            scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        }
        scrollEdgeAppearance.shadowColor = .clear

        // Create compact layout appearance
        let compactAppearance = UINavigationBarAppearance()
        compactAppearance.configureWithOpaqueBackground()

        // Set background color and text attributes for compact layout appearance
        if UITraitCollection.current.userInterfaceStyle == .dark {
            compactAppearance.backgroundColor = UIColor(
                red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
            compactAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            compactAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            compactAppearance.backgroundColor = .systemBackground
            compactAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            compactAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        }
        compactAppearance.shadowColor = .clear

        // Apply appearance settings to global navigation bar
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        UINavigationBar.appearance().compactAppearance = compactAppearance

        // Ensure navigation bar is completely opaque - This is key
        UINavigationBar.appearance().isTranslucent = false

        // ConfigureTabBar appearance
        configureTabBarAppearance()
    }

    // ExtractTabBar configuration to separate method
    private static func configureTabBarAppearance() {
        // SetTabBar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()

        if UITraitCollection.current.userInterfaceStyle == .dark {
            // Dark mode uses standard dark gray
            tabBarAppearance.backgroundColor = UIColor(
                red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
        } else {
            // Light mode uses system background color
            tabBarAppearance.backgroundColor = .systemBackground
        }

        // ApplyTabBar appearance settings
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }

        // EnsureTabBar is opaque
        UITabBar.appearance().isTranslucent = false
    }
}
