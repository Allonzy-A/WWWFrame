import SwiftUI

class WebViewHostingController<Content: View>: UIHostingController<Content> {
    // Черные слои для SafeArea
    private var topSafeAreaOverlay: UIView!
    private var bottomSafeAreaOverlay: UIView!
    private var leftSafeAreaOverlay: UIView!
    private var rightSafeAreaOverlay: UIView!
    
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
        
        // Создаем и добавляем черные оверлеи для всех сторон SafeArea
        setupSafeAreaOverlays()
        
        // Ищем и настраиваем WebView для правильных отступов
        findAndConfigureWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Обновляем размеры оверлеев при изменении layout
        updateSafeAreaOverlays()
        
        // Обновляем отступы в WebView при изменении размеров
        updateWebViewInsets()
    }
    
    private func setupSafeAreaOverlays() {
        // Верхний оверлей
        topSafeAreaOverlay = UIView()
        topSafeAreaOverlay.backgroundColor = .black
        topSafeAreaOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        // Нижний оверлей
        bottomSafeAreaOverlay = UIView()
        bottomSafeAreaOverlay.backgroundColor = .black
        bottomSafeAreaOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        // Левый оверлей
        leftSafeAreaOverlay = UIView()
        leftSafeAreaOverlay.backgroundColor = .black
        leftSafeAreaOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        // Правый оверлей
        rightSafeAreaOverlay = UIView()
        rightSafeAreaOverlay.backgroundColor = .black
        rightSafeAreaOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем все оверлеи на view
        view.addSubview(topSafeAreaOverlay)
        view.addSubview(bottomSafeAreaOverlay)
        view.addSubview(leftSafeAreaOverlay)
        view.addSubview(rightSafeAreaOverlay)
        
        updateSafeAreaOverlays()
        
        // Убедимся, что оверлеи находятся поверх других вью
        view.bringSubviewToFront(topSafeAreaOverlay)
        view.bringSubviewToFront(bottomSafeAreaOverlay)
        view.bringSubviewToFront(leftSafeAreaOverlay)
        view.bringSubviewToFront(rightSafeAreaOverlay)
    }
    
    private func updateSafeAreaOverlays() {
        let safeArea = view.safeAreaInsets
        
        // Обновляем размеры и позиции оверлеев
        topSafeAreaOverlay.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: safeArea.top)
        bottomSafeAreaOverlay.frame = CGRect(x: 0, y: view.bounds.height - safeArea.bottom, width: view.bounds.width, height: safeArea.bottom)
        leftSafeAreaOverlay.frame = CGRect(x: 0, y: safeArea.top, width: safeArea.left, height: view.bounds.height - safeArea.top - safeArea.bottom)
        rightSafeAreaOverlay.frame = CGRect(x: view.bounds.width - safeArea.right, y: safeArea.top, width: safeArea.right, height: view.bounds.height - safeArea.top - safeArea.bottom)
    }
    
    // Ищем WebViewControllerWrapper в иерархии вью и настраиваем отступы
    private func findAndConfigureWebView() {
        view.findWebViewControllerWrapper { webViewWrapper in
            // Устанавливаем начальные отступы
            let safeArea = view.safeAreaInsets
            webViewWrapper.setContentInsets(top: safeArea.top, bottom: safeArea.bottom)
        }
    }
    
    // Обновляем отступы в WebView при изменении размеров
    private func updateWebViewInsets() {
        view.findWebViewControllerWrapper { webViewWrapper in
            let safeArea = view.safeAreaInsets
            webViewWrapper.setContentInsets(top: safeArea.top, bottom: safeArea.bottom)
        }
    }
    
    // Обработка поворота экрана
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Обновляем размеры оверлеев при повороте экрана
            self.updateSafeAreaOverlays()
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