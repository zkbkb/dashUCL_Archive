import SwiftUI
import WebKit

// Optimized WebView Component
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool

    // Custom configuration
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Set UI style, show scrollbar
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.indicatorStyle = .default

        // Add right scrollbar style enhancement
        webView.scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: 0, right: -2)

        // Enable touch scrolling
        webView.scrollView.isScrollEnabled = true

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Prevent duplicate loading of the same URL
        if !context.coordinator.hasLoadedUrl {
            let request = URLRequest(
                url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            uiView.load(request)
            context.coordinator.hasLoadedUrl = true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var hasLoadedUrl = false

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
        {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.hasError = false
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }

            // Add custom CSS enhancement scrollbar style
            let css = """
                ::-webkit-scrollbar {
                    width: 6px;
                    height: 6px;
                }
                ::-webkit-scrollbar-track {
                    background: rgba(0,0,0,0.1);
                }
                ::-webkit-scrollbar-thumb {
                    background: rgba(0,0,0,0.2);
                    border-radius: 3px;
                }
                """

            // Inject CSS
            let script =
                "var style = document.createElement('style'); style.innerHTML = '\(css)'; document.head.appendChild(style);"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func webView(
            _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error
        ) {
            handleError(error)
        }

        func webView(
            _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            handleError(error)
        }

        private func handleError(_ error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = true
                print("WebView error: \(error.localizedDescription)")
            }
        }
    }
}

struct TermsAndConditionsView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var showScrollIndicator: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    // Webpage URL
    private let termsURL = URL(string: "https://auth.support/terms")!

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color - Use iOS dark mode standard dark gray (RGB: 28, 28, 30)
                (colorScheme == .dark
                    ? Color(UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
                    : Color(UIColor.systemBackground))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top security area and drag indicator
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 36, height: 5)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    // Add bottom divider
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.gray.opacity(0.3)),
                        alignment: .bottom
                    )
                    // Add slight shadow effect
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)

                    // Use WebView instead of original content
                    ZStack {
                        WebView(url: termsURL, isLoading: $isLoading, hasError: $hasError)
                            .overlay(
                                // Custom scroll indicator
                                Group {
                                    if showScrollIndicator {
                                        HStack {
                                            Spacer()
                                            Capsule()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 3)
                                                .padding(.vertical, 40)
                                                .padding(.trailing, 2)
                                        }
                                        .allowsHitTesting(false)
                                    }
                                }
                            )

                        if isLoading {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading Terms & Conditions...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemBackground).opacity(0.7))
                        }

                        if hasError {
                            VStack(spacing: 16) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)

                                Text("Unable to Load Terms")
                                    .font(.headline)

                                Text("Please check your internet connection and try again.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)

                                Button(action: {
                                    isLoading = true
                                    hasError = false
                                    // Reset loading state, allow re-loading
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        _ = URLRequest(
                                            url: termsURL,
                                            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                                        UIApplication.shared.open(
                                            termsURL, options: [:], completionHandler: nil)
                                        dismiss()
                                    }
                                }) {
                                    Text("Open in Browser")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemBackground))
                        }
                    }

                    // Fixed bottom button
                    ZStack(alignment: .bottom) {
                        // Bottom gradient background
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color(UIColor.systemBackground).opacity(0),
                                    Color(UIColor.systemBackground),
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)

                        // Button placed on gradient background above, not blocked
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(height: 110)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Terms and Conditions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))

                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct LoginPrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var showScrollIndicator: Bool = true

    // Webpage URL
    private let privacyURL = URL(string: "https://auth.support/privacy")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top security area and drag indicator
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                // Add slightly different background color
                .background(Color(UIColor.systemBackground).opacity(0.97))
                // Add bottom divider
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .bottom
                )
                // Add slight shadow effect
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)

                // Use WebView instead of original content
                ZStack {
                    WebView(url: privacyURL, isLoading: $isLoading, hasError: $hasError)
                        .overlay(
                            // Custom scroll indicator
                            Group {
                                if showScrollIndicator {
                                    HStack {
                                        Spacer()
                                        Capsule()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 3)
                                            .padding(.vertical, 40)
                                            .padding(.trailing, 2)
                                    }
                                    .allowsHitTesting(false)
                                }
                            }
                        )

                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading Privacy Policy...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground).opacity(0.7))
                    }

                    if hasError {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)

                            Text("Unable to Load Privacy Policy")
                                .font(.headline)

                            Text("Please check your internet connection and try again.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)

                            Button(action: {
                                isLoading = true
                                hasError = false
                                // Reset loading state, allow re-loading
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    _ = URLRequest(
                                        url: privacyURL,
                                        cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                                    UIApplication.shared.open(
                                        privacyURL, options: [:], completionHandler: nil)
                                    dismiss()
                                }
                            }) {
                                Text("Open in Browser")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                    }
                }

                // Fixed bottom button
                ZStack(alignment: .bottom) {
                    // Bottom gradient background
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color(UIColor.systemBackground).opacity(0),
                                Color(UIColor.systemBackground),
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)

                    // Button placed on gradient background above, not blocked
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(height: 110)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))

                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview("Terms and Conditions") {
    TermsAndConditionsView()
}

#Preview("Privacy Policy") {
    LoginPrivacyPolicyView()
}
