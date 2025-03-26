import SwiftUI
import WebKit

class WebViewHostingController<Content: View>: UIHostingController<Content> {
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настройка для черной безопасной области
        view.backgroundColor = .black
        
        // Важно для корректной работы с SafeArea
        overrideUserInterfaceStyle = .dark
        
        // Настраиваем WebView для правильных отступов
        findAndConfigureWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Обновляем отступы в WebView при изменении размеров
        updateWebViewInsets()
    }
    
    // Ищем WebViewControllerWrapper в иерархии вью и настраиваем отступы
    private func findAndConfigureWebView() {
        view.findWebViewControllerWrapper { webViewWrapper in
            // Устанавливаем начальные отступы
            let safeArea = self.view.safeAreaInsets
            webViewWrapper.setContentInsets(top: safeArea.top, bottom: safeArea.bottom)
            
            // Устанавливаем черный цвет для фона WebView
            webViewWrapper.webView.backgroundColor = .black
            webViewWrapper.webView.scrollView.backgroundColor = .black
        }
    }
    
    // Обновляем отступы в WebView при изменении размеров
    private func updateWebViewInsets() {
        view.findWebViewControllerWrapper { webViewWrapper in
            let safeArea = self.view.safeAreaInsets
            webViewWrapper.setContentInsets(top: safeArea.top, bottom: safeArea.bottom)
        }
    }
    
    // Обработка поворота экрана
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Обновляем отступы в WebView
            self.updateWebViewInsets()
        })
    }
}

// Расширение для поиска WebViewControllerWrapper
extension UIView {
    func findWebViewControllerWrapper(completion: @escaping (WebViewControllerWrapper) -> Void) {
        for subview in subviews {
            // Проверяем, является ли subview WebView
            if let webView = subview as? WKWebView,
               let wrapper = findWrapper(for: webView) {
                completion(wrapper)
                return
            }
            
            // Рекурсивно ищем в дочерних subview
            subview.findWebViewControllerWrapper(completion: completion)
        }
    }
    
    private func findWrapper(for webView: WKWebView) -> WebViewControllerWrapper? {
        // Просматриваем родительскую иерархию для поиска WebViewControllerWrapper
        var currentView: UIView? = webView
        while currentView != nil {
            if let parent = currentView?.superview?.next as? WebViewControllerWrapper {
                return parent
            }
            currentView = currentView?.superview
        }
        return nil
    }
} 