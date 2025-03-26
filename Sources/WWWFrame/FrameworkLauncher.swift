import SwiftUI

public struct FrameworkLauncher {
    /// Запускает фреймворк и автоматически настраивает получение APNS токена
    /// Все происходит без дополнительного кода со стороны пользователя
    public static func start() {
        FrameworkManager.shared.launch()
    }
    
    /// Проверяет статус APNS токена и выводит информацию в консоль
    /// Полезно для отладки проблем с токеном
    public static func debugPushNotificationStatus() {
        // Проверяем, зарегистрировано ли приложение для пуш-уведомлений
        let isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        print("WWWFrame Debug: App registered for remote notifications: \(isRegistered)")
        
        // Проверяем, есть ли у нас сохраненный токен
        if let tokenString = WWWFrameDebug.getCurrentAPNSToken() {
            print("WWWFrame Debug: Current APNS token: \(tokenString)")
        } else {
            print("WWWFrame Debug: No APNS token found in keychain")
        }
        
        // Проверяем настройки уведомлений
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("WWWFrame Debug: Notification settings - authorization status: \(settings.authorizationStatus.rawValue)")
            
            switch settings.authorizationStatus {
            case .authorized:
                print("WWWFrame Debug: Push notifications are authorized")
            case .denied:
                print("WWWFrame Debug: Push notifications are denied by user")
            case .notDetermined:
                print("WWWFrame Debug: Push notification permission not yet requested")
            case .provisional:
                print("WWWFrame Debug: Push notifications have provisional authorization")
            case .ephemeral:
                print("WWWFrame Debug: Push notifications have ephemeral authorization")
            @unknown default:
                print("WWWFrame Debug: Unknown authorization status")
            }
        }
        
        // Проверяем наличие проблем с Keychain
        if WWWFrameDebug.cleanupKeychain() {
            print("WWWFrame Debug: Keychain is in good state or has been cleaned up")
        } else {
            print("WWWFrame Debug: Warning - There may be issues with the keychain")
        }
        
        // Если приложение не зарегистрировано для пуш-уведомлений, предлагаем зарегистрироваться
        if !isRegistered {
            print("WWWFrame Debug: Attempting to register for push notifications")
            WWWFrameDebug.registerForPushNotifications()
        }
    }
} 