import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var webViewControllerWrapper: WebViewControllerWrapper
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Черный фон для всего экрана и SafeArea
                Color.black
                    .ignoresSafeArea()
                
                // WebView без отступов - отступы будут добавлены программно через UIKit
                WebViewRepresentable(webView: webViewControllerWrapper.webView)
                    .ignoresSafeArea()
                
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
}

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Nothing to update
    }
} 