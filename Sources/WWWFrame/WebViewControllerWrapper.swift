import SwiftUI
import WebKit

class WebViewControllerWrapper: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var url: URL
    @Published var isLoading: Bool = true
    
    let webView: WKWebView
    
    init(url: URL) {
        self.url = url
        
        // Настраиваем WKWebView с базовыми параметрами
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Устанавливаем черный цвет для фона
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        super.init()
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        // Настройка стиля WebView
        webView.scrollView.backgroundColor = .black
        
        // Настраиваем WebView для лучшего отображения
        configureWebView()
        
        // Загрузка URL
        loadURL()
    }
    
    func loadURL() {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
    }
    
    // Настройка WebView для лучшего отображения
    private func configureWebView() {
        // Отключаем автоматические отступы, т.к. теперь используем фиксированные
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        
        // Настраиваем свойства WebView
        webView.clipsToBounds = true
        webView.layer.masksToBounds = true
        
        // Отключаем прокрутку за пределы контента для плавного опыта
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
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