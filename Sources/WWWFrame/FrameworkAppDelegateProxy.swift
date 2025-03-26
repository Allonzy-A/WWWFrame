import UIKit
import UserNotifications
import ObjectiveC

/// Прокси-класс для автоматического получения APNS токена
@objc public class FrameworkAppDelegateProxy: NSObject {
    static let shared = FrameworkAppDelegateProxy()
    
    // Оригинальные методы приложения
    private var originalDidRegisterForRemoteNotificationsImplementation: IMP?
    
    /// Инициализирует прокси для автоматического получения APNS токена
    public func initialize() {
        UNUserNotificationCenter.current().delegate = self
        swizzleAppDelegateMethods()
    }
    
    // MARK: - Private Methods
    
    private func swizzleAppDelegateMethods() {
        guard let appDelegate = UIApplication.shared.delegate else {
            print("WWWFrame: No AppDelegate found to proxy")
            return
        }
        
        let appDelegateClass: AnyClass = object_getClass(appDelegate)!
        
        // Swizzle didRegisterForRemoteNotificationsWithDeviceToken
        swizzleMethod(
            in: appDelegateClass,
            originalSelector: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
            swizzledSelector: #selector(FrameworkAppDelegateProxy.interceptedApplication(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        )
        
        // Swizzle didFailToRegisterForRemoteNotificationsWithError
        swizzleMethod(
            in: appDelegateClass,
            originalSelector: #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)),
            swizzledSelector: #selector(FrameworkAppDelegateProxy.interceptedApplication(_:didFailToRegisterForRemoteNotificationsWithError:))
        )
        
        print("WWWFrame: AppDelegate proxy initialized successfully")
    }
    
    private func swizzleMethod(in cls: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        // Получаем оригинальный метод
        guard let originalMethod = class_getInstanceMethod(cls, originalSelector) else {
            // Если метод не реализован в AppDelegate, добавляем его
            let frameworkMethod = class_getInstanceMethod(FrameworkAppDelegateProxy.self, swizzledSelector)!
            let frameImp = method_getImplementation(frameworkMethod)
            let frameType = method_getTypeEncoding(frameworkMethod)
            
            let success = class_addMethod(cls, originalSelector, frameImp, frameType)
            print("WWWFrame: Added method \(originalSelector) to AppDelegate: \(success)")
            return
        }
        
        // Получаем наш метод
        guard let swizzledMethod = class_getInstanceMethod(FrameworkAppDelegateProxy.self, swizzledSelector) else { return }
        
        // Пытаемся добавить наш метод в AppDelegate
        let didAddMethod = class_addMethod(
            cls,
            swizzledSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        if didAddMethod {
            // Если метод успешно добавлен, заменяем оригинальный метод на наш
            let newMethod = class_getInstanceMethod(cls, swizzledSelector)!
            method_exchangeImplementations(originalMethod, newMethod)
            print("WWWFrame: Successfully swizzled method \(originalSelector)")
        } else {
            print("WWWFrame: Failed to swizzle method \(originalSelector)")
        }
    }
    
    // MARK: - Intercepted Methods
    
    @objc func interceptedApplication(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Обрабатываем токен в нашем коде
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("WWWFrame: Intercepted APNS token: \(tokenString)")
        
        // Передаем токен в FrameworkManager
        FrameworkManager.shared.setAPNSToken(deviceToken)
        
        // Вызываем оригинальный метод, если он существует
        let appDelegate = UIApplication.shared.delegate
        let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        if let originalMethod = class_getInstanceMethod(type(of: appDelegate!), originalSelector) {
            typealias OriginalMethodSignature = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
            let originalMethodIMP = method_getImplementation(originalMethod)
            let originalMethodFunction = unsafeBitCast(originalMethodIMP, to: OriginalMethodSignature.self)
            originalMethodFunction(appDelegate!, originalSelector, application, deviceToken)
        }
    }
    
    @objc func interceptedApplication(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Обрабатываем ошибку в нашем коде
        print("WWWFrame: Intercepted APNS registration failure: \(error.localizedDescription)")
        
        // Вызываем оригинальный метод, если он существует
        let appDelegate = UIApplication.shared.delegate
        let originalSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        if let originalMethod = class_getInstanceMethod(type(of: appDelegate!), originalSelector) {
            typealias OriginalMethodSignature = @convention(c) (AnyObject, Selector, UIApplication, Error) -> Void
            let originalMethodIMP = method_getImplementation(originalMethod)
            let originalMethodFunction = unsafeBitCast(originalMethodIMP, to: OriginalMethodSignature.self)
            originalMethodFunction(appDelegate!, originalSelector, application, error)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension FrameworkAppDelegateProxy: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Обрабатываем уведомления в foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Обрабатываем ответ на уведомление
        completionHandler()
    }
} 