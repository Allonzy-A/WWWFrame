import SwiftUI
import WebKit
import Combine

struct WebViewContainer: View {
    private let url: URL
    @State private var isLoading = true
    
    init(url: URL) {
        self.url = url
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            WebViewRepresentable(url: url, isLoading: $isLoading)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

struct WebViewRepresentable: UIViewControllerRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIViewController(context: Context) -> WebViewControllerWrapper {
        let controller = WebViewControllerWrapper(url: url)
        controller.navigationDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: WebViewControllerWrapper, context: Context) {
        // Ничего не делаем при обновлении
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
} 