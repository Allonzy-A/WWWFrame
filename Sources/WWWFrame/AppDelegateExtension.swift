import UIKit

public extension UIApplicationDelegate {
    
    /// Call this in the AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken method
    func registerAPNSToken(deviceToken: Data) {
        FrameworkManager.shared.setAPNSToken(deviceToken)
    }
} 