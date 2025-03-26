import SwiftUI
import WebKit

class WebViewHostingController<Content: View>: UIHostingController<Content> {
    // Контейнеры для фиксированных отступов
    private var topSpacerView: UIView?
    private var bottomSpacerView: UIView?
    
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
        
        // Устанавливаем черный цвет фона
        view.backgroundColor = .black
        self.modalPresentationCapturesStatusBarAppearance = true
        
        findAndConfigureWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFixedInsets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // Ищем WebViewControllerWrapper в иерархии вью и настраиваем отступы
    private func findAndConfigureWebView() {
        view.findWebViewControllerWrapper { webViewWrapper in
            let webView = webViewWrapper.webView
            
            // Удаляем WebView из текущего superview
            webView.removeFromSuperview()
            
            // Создаем контейнеры для фиксированных отступов
            self.createFixedInsets(webView: webView)
            
            // Устанавливаем черный цвет для фона WebView
            webView.backgroundColor = .black
            webView.scrollView.backgroundColor = .black
            
            // Отключаем автоматическую настройку отступов
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            webView.scrollView.contentInset = .zero
        }
    }
    
    // Создаем фиксированные отступы для WebView
    private func createFixedInsets(webView: WKWebView) {
        // Создаем верхний и нижний отступы
        let topSpacer = UIView()
        topSpacer.backgroundColor = .black
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomSpacer = UIView()
        bottomSpacer.backgroundColor = .black
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        // Сохраняем ссылки
        self.topSpacerView = topSpacer
        self.bottomSpacerView = bottomSpacer
        
        // Устанавливаем tag для WebView чтобы его можно было легко найти
        webView.tag = 100
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем элементы на основное представление
        view.addSubview(topSpacer)
        view.addSubview(webView)
        view.addSubview(bottomSpacer)
        
        // Устанавливаем начальные размеры отступов
        updateFixedInsets()
    }
    
    // Обновляем размеры фиксированных отступов
    private func updateFixedInsets() {
        guard let topSpacer = topSpacerView, 
              let bottomSpacer = bottomSpacerView,
              let webView = view.viewWithTag(100) as? WKWebView else {
            return
        }
        
        // Удаляем все существующие ограничения для спейсеров и webView
        NSLayoutConstraint.deactivate(topSpacer.constraints)
        NSLayoutConstraint.deactivate(bottomSpacer.constraints)
        NSLayoutConstraint.deactivate(webView.constraints)
        
        let safeArea = view.safeAreaInsets
        
        // Увеличиваем верхний отступ для обхода камеры
        let topInset = safeArea.top + 45
        
        // Нижний отступ делаем минимальным
        let bottomInset = 5.0
        
        // Устанавливаем ограничения
        NSLayoutConstraint.activate([
            // Верхний отступ
            topSpacer.topAnchor.constraint(equalTo: view.topAnchor),
            topSpacer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topSpacer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topSpacer.heightAnchor.constraint(equalToConstant: topInset),
            
            // WebView между отступами
            webView.topAnchor.constraint(equalTo: topSpacer.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomSpacer.topAnchor),
            
            // Нижний отступ
            bottomSpacer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSpacer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: bottomInset)
        ])
        
        view.layoutIfNeeded()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.view.setNeedsLayout()
        })
    }
}

// Расширение для поиска WebViewControllerWrapper
extension UIView {
    func findWebViewControllerWrapper(completion: @escaping (WebViewControllerWrapper) -> Void) {
        for subview in subviews {
            if let webView = subview as? WKWebView,
               let wrapper = findWrapper(for: webView) {
                completion(wrapper)
                return
            }
            
            subview.findWebViewControllerWrapper(completion: completion)
        }
    }
    
    private func findWrapper(for webView: WKWebView) -> WebViewControllerWrapper? {
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