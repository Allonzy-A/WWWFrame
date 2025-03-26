import UIKit

/// Утилиты для отладки работы с APNS токеном
public struct WWWFrameDebug {
    /// Возвращает текущий APNS токен, если он был получен
    public static func getCurrentAPNSToken() -> String? {
        if let tokenData = getTokenDataFromKeychain() {
            let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            return tokenString
        }
        return nil
    }
    
    /// Ручная установка APNS токена (для случаев, когда автоматическое получение не работает)
    public static func manuallySetAPNSToken(_ tokenData: Data) {
        FrameworkManager.shared.setAPNSToken(tokenData)
    }
    
    /// Возвращает информацию о том, зарегистрировано ли приложение для пуш-уведомлений
    public static func isRegisteredForRemoteNotifications() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    /// Запрашивает регистрацию для пуш-уведомлений
    public static func requestRemoteNotificationsRegistration() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // Получение токена из Keychain
    private static func getTokenDataFromKeychain() -> Data? {
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