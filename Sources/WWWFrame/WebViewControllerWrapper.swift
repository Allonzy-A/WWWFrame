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
        
        // Устанавливаем маску для черной окраски краев экрана
        configureWebViewMasks()
        
        // Загрузка URL
        loadURL()
    }
    
    func loadURL() {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
    }
    
    // Устанавливает отступы для контента WebView
    func setContentInsets(top: CGFloat, bottom: CGFloat) {
        // Отступы для контента
        let insets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        webView.scrollView.contentInset = insets
        webView.scrollView.scrollIndicatorInsets = insets
        
        // Важно: отключаем автоматическую настройку отступов контента
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Обновляем маски для SafeArea
        updateSafeAreaMasks(top: top, bottom: bottom)
        
        print("WWWFrame: Setting WebView content insets - top: \(top), bottom: \(bottom)")
    }
    
    // Настройка маски для черной окраски краев экрана
    private func configureWebViewMasks() {
        // Устанавливаем свойства WebView для отображения маски
        webView.clipsToBounds = true
        webView.layer.masksToBounds = true
        
        // Отключаем прокрутку за пределы контента
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
    }
    
    // Обновляем маски для SafeArea
    private func updateSafeAreaMasks(top: CGFloat, bottom: CGFloat) {
        // Устанавливаем отступы от верхнего и нижнего края
        webView.scrollView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        // Отступы для индикаторов прокрутки
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        // Убеждаемся, что safe area не пересекается с контентом
        webView.scrollView.contentInsetAdjustmentBehavior = .never
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