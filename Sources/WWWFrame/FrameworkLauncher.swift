import SwiftUI

public struct FrameworkLauncher {
    public static func start() {
        FrameworkManager.shared.launch()
    }
    
    /// Регистрирует APNS токен в фреймворке
    /// Вызывайте этот метод в AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken
    public static func registerAPNSToken(deviceToken: Data) {
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
} 