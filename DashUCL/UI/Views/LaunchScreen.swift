import SwiftUI
import UIKit

// Key for caching device launch screen size information
private let kLaunchScreenSizeKey = "com.dashucl.launchscreen.size"

struct LaunchScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var imageLoadError: Bool = false

    // Default image size for first launch - iPhone 16 Pro
    private let defaultLaunchImage = "Launch-6.3"

    // Lazy loaded launch screen image name, prioritize getting from cache to avoid calculation each time
    private var cachedLaunchImage: String {
        // First check if there is a cached size
        if let cachedSize = UserDefaults.standard.string(forKey: kLaunchScreenSizeKey) {
            return cachedSize
        }

        // If no cache, return default size
        return defaultLaunchImage
    }

    // Detect current device size and cache result
    private func detectAndCacheScreenSize() {
        let bounds = UIScreen.main.bounds
        let height = bounds.height

        var detectedImageName: String

        if height > 900 {
            detectedImageName = "Launch-6.7"  // Large screen devices
        } else if height > 870 {
            detectedImageName = "Launch-6.3"  // iPhone 16 Pro
        } else if height > 850 {
            detectedImageName = "Launch-6.1"  // Medium screen
        } else if height > 800 {
            detectedImageName = "Launch-5.8"  // Small screen devices
        } else if height > 700 {
            detectedImageName = "Launch-5.5"  // Smaller screen
        } else {
            detectedImageName = "Launch-4.7"  // Smallest screen
        }

        // Verify image exists
        if UIImage(named: detectedImageName) != nil {
            // Cache detected size
            // Store detected size in cache
            UserDefaults.standard.set(detectedImageName, forKey: kLaunchScreenSizeKey)
        } else {
            // If the image for detected size doesn't exist, use default value and cache it
            UserDefaults.standard.set(defaultLaunchImage, forKey: kLaunchScreenSizeKey)
        }
    }

    var body: some View {
        ZStack {
            // Background color as base layer
            Color(uiColor: colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()
                .zIndex(0)

            // Use cached launch screen image
            if !imageLoadError {
                Image(cachedLaunchImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .zIndex(1)
            }
        }
        .onAppear {
            // Check if image exists
            if UIImage(named: cachedLaunchImage) == nil {
                // If cached image doesn't exist, try loading default image
                if UIImage(named: defaultLaunchImage) == nil {
                    // If default image also doesn't exist, mark error
                    self.imageLoadError = true
                }
            }

            // Detect and cache screen size in background, without affecting launch performance
            DispatchQueue.global(qos: .background).async {
                detectAndCacheScreenSize()
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
