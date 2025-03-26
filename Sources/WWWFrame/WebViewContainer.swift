import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var webViewControllerWrapper: WebViewControllerWrapper
    
    var body: some View {
        ZStack {
            // WebView
            WebViewRepresentable(webView: webViewControllerWrapper.webView)
                .edgesIgnoringSafeArea(.all)
            
            // Loading indicator
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

// Status bar configurator for iOS 15+
struct StatusBarHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .statusBar(hidden: true)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Nothing to update
    }
} 