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
        if let tokenData = WWWFrameDebug.getCurrentAPNSToken() {
            print("WWWFrame Debug: Current APNS token: \(tokenData)")
        } else {
            print("WWWFrame Debug: No APNS token found")
        }
        
        // Проверяем настройки уведомлений
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("WWWFrame Debug: Notification settings - authorization status: \(settings.authorizationStatus.rawValue)")
        }
    }
} 