import UIKit

/// Это расширение больше не требуется для использования,
/// так как фреймворк автоматически перехватывает APNS токен
/// через систему прокси. Оставлено для обратной совместимости.
@available(*, deprecated, message: "No longer needed. APNS token is captured automatically")
public extension UIApplicationDelegate {
    
    /// Этот метод больше не нужен вызывать, так как фреймворк 
    /// автоматически перехватывает получение APNS токена
    @available(*, deprecated, message: "No longer needed. APNS token is captured automatically")
    func registerAPNSToken(deviceToken: Data) {
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
}

/// Этот класс больше не требуется для использования,
/// так как фреймворк автоматически перехватывает APNS токен
/// через систему прокси. Оставлен для обратной совместимости.
@available(*, deprecated, message: "No longer needed. APNS token is captured automatically")
public class WWWFrameDelegate {
    /// Этот метод больше не нужен вызывать, так как фреймворк 
    /// автоматически перехватывает получение APNS токена
    @available(*, deprecated, message: "No longer needed. APNS token is captured automatically")
    public static func registerAPNSToken(deviceToken: Data) {
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
} 