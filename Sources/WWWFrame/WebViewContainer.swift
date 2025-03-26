import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var webViewControllerWrapper: WebViewControllerWrapper
    
    var body: some View {
        ZStack {
            // Черный фон для всего экрана
            Color.black.ignoresSafeArea()
            
            // WebView контент
            WebViewRepresentable(webView: webViewControllerWrapper.webView)
                .background(Color.black)
            
            // Loading indicator поверх всего
            if webViewControllerWrapper.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .background(Color.black)
        .statusBar(hidden: true)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        // Устанавливаем черный фон
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Nothing to update
    }
} 