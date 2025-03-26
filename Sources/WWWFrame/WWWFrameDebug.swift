import UIKit
import Security

/// Класс для отладки проблем с APNS токеном и другими аспектами фреймворка
public class WWWFrameDebug {
    
    /// Получает текущий APNS токен из Keychain
    /// - Returns: Строковое представление APNS токена или nil, если токен не найден
    public static func getCurrentAPNSToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "APNSTokenKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let tokenData = item as? Data {
            // Преобразуем данные в строку
            let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            return tokenString
        } else {
            print("WWWFrame Debug: No APNS token found in keychain, status: \(status)")
            return nil
        }
    }
    
    /// Проверяет статус Keychain и пытается очистить его от проблемных записей
    public static func cleanupKeychain() -> Bool {
        print("WWWFrame Debug: Cleaning up keychain items for APNSTokenKey")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "APNSTokenKey"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("WWWFrame Debug: Successfully cleaned up keychain items")
            return true
        } else if status == errSecItemNotFound {
            print("WWWFrame Debug: No items found to clean up")
            return true
        } else {
            print("WWWFrame Debug: Failed to clean up keychain items with status: \(status)")
            return false
        }
    }
    
    /// Проверяет наличие разрешения на push уведомления
    public static func checkPushNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            print("WWWFrame Debug: Push notification permission: \(isAuthorized ? "Granted" : "Not granted")")
            completion(isAuthorized)
        }
    }
    
    /// Регистрирует устройство для получения push уведомлений
    public static func registerForPushNotifications() {
        print("WWWFrame Debug: Manually registering for push notifications")
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
} 