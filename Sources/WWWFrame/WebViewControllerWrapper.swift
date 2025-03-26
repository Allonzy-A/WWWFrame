import SwiftUI
import WebKit

class WebViewControllerWrapper: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var url: URL
    @Published var isLoading: Bool = true
    
    let webView: WKWebView
    
    init(url: URL) {
        self.url = url
        
        // Configure web view with cache and cookies enabled
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init()
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        // Hide status bar
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.statusBarManager?.isStatusBarHidden = true
        }
        
        // Load the URL
        loadURL()
    }
    
    func loadURL() {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        print("WWWFrame: WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("WWWFrame: WebView failed to load: \(error.localizedDescription)")
    }
    
    // MARK: - WKUIDelegate
    
    // Handle alerts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // Handle camera permission requests
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        print("WWWFrame: Camera permission requested")
        decisionHandler(.prompt)
    }
} 