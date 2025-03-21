/*
 * UIViewRepresentable wrapper for WKWebView to display web content in SwiftUI.
 * Implements loading states, error handling, and UI customization for web pages.
 * Used in settings screens to display terms, privacy policy, and external documentation.
 * Manages navigation delegation and custom scrolling behavior.
 */

import SwiftUI
import WebKit

struct SettingsWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool

    // Custom configuration
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Set UI style, show scrollbars
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.indicatorStyle = .default

        // Enhance right-side scrollbar style
        webView.scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: 0, right: -2)

        // Enable touch scrolling
        webView.scrollView.isScrollEnabled = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 防止重复加载相同URL
        if !context.coordinator.hasLoadedUrl {
            let request = URLRequest(
                url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            webView.load(request)
            context.coordinator.hasLoadedUrl = true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SettingsWebView
        var hasLoadedUrl = false

        init(_ parent: SettingsWebView) {
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

            // 添加自定义CSS增强滚动条样式
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

            // 注入CSS
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
