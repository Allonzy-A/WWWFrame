import UIKit

public extension UIApplicationDelegate {
    
    /// Call this in the AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken method
    func registerAPNSToken(deviceToken: Data) {
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
}

/// Объект для интеграции с FrameworkLauncher
public class WWWFrameDelegate {
    /// Регистрирует APNS токен после получения
    public static func registerAPNSToken(deviceToken: Data) {
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
} 