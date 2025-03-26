import UIKit
import UserNotifications
import ObjectiveC

/// Прокси-класс для автоматического получения APNS токена
@objc public class FrameworkAppDelegateProxy: NSObject {
    static let shared = FrameworkAppDelegateProxy()
    
    // Оригинальные методы приложения
    private var originalDidRegisterForRemoteNotificationsImplementation: IMP?
    
    // Флаг для отслеживания инициализации
    private static var isInitialized = false
    
    /// Инициализирует прокси для автоматического получения APNS токена
    public func initialize() {
        // Проверяем, не инициализированы ли мы уже
        if FrameworkAppDelegateProxy.isInitialized {
            print("WWWFrame: Proxy system already initialized, skipping")
            return
        }
        
        UNUserNotificationCenter.current().delegate = self
        swizzleAppDelegateMethods()
        
        // Устанавливаем флаг инициализации
        FrameworkAppDelegateProxy.isInitialized = true
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
        let originalMethod = class_getInstanceMethod(cls, originalSelector)
        let swizzledMethod = class_getInstanceMethod(FrameworkAppDelegateProxy.self, swizzledSelector)
        
        guard let swizzledMethod = swizzledMethod else {
            print("WWWFrame: Failed to get swizzled method \(swizzledSelector)")
            return
        }
        
        // Проверяем, не заменяли ли мы уже этот метод
        let key = "WWWFrame_\(originalSelector)"
        if let _ = objc_getAssociatedObject(cls, key) as? Bool {
            print("WWWFrame: Method \(originalSelector) already swizzled, skipping")
            return
        }
        
        if let originalMethod = originalMethod {
            // Проверяем, не является ли оригинальный метод уже нашим методом
            let originalIMP = method_getImplementation(originalMethod)
            let swizzledIMP = method_getImplementation(swizzledMethod)
            
            if originalIMP == swizzledIMP {
                print("WWWFrame: Method \(originalSelector) already points to our implementation, skipping")
                return
            }
            
            // Сохраняем оригинальную реализацию
            let originalMethodType = method_getTypeEncoding(originalMethod)
            
            // Пытаемся добавить наш метод в AppDelegate с именем оригинального метода
            let didAddMethod = class_addMethod(
                cls,
                originalSelector,
                swizzledIMP,
                originalMethodType
            )
            
            if didAddMethod {
                // Если успешно, то устанавливаем оригинальный метод с новым именем
                class_replaceMethod(
                    cls,
                    swizzledSelector,
                    originalIMP,
                    originalMethodType
                )
                print("WWWFrame: Successfully replaced method \(originalSelector)")
            } else {
                // Если не смогли добавить (метод уже существует), заменяем реализации
                method_exchangeImplementations(originalMethod, swizzledMethod)
                print("WWWFrame: Successfully exchanged implementations for \(originalSelector)")
            }
        } else {
            // Если метод не реализован в AppDelegate, добавляем его
            let swizzledIMP = method_getImplementation(swizzledMethod)
            let swizzledType = method_getTypeEncoding(swizzledMethod)
            
            let success = class_addMethod(cls, originalSelector, swizzledIMP, swizzledType)
            print("WWWFrame: Added method \(originalSelector) to AppDelegate: \(success)")
        }
        
        // Отмечаем, что мы свиззлили этот метод
        objc_setAssociatedObject(cls, key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // MARK: - Intercepted Methods
    
    @objc func interceptedApplication(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Обрабатываем токен в нашем коде
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("WWWFrame: Intercepted APNS token: \(tokenString)")
        
        // Устанавливаем флаг, чтобы избежать повторного вызова нашего кода
        let isCallFromOurMethod = objc_getAssociatedObject(self, "isCallingFromOurMethod") as? Bool ?? false
        if isCallFromOurMethod {
            print("WWWFrame: Detected recursive call, breaking the cycle")
            return
        }
        
        // Устанавливаем флаг перед продолжением
        objc_setAssociatedObject(self, "isCallingFromOurMethod", true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Передаем токен в FrameworkManager
        FrameworkManager.shared.setAPNSToken(deviceToken)
        
        // Вызываем оригинальный метод, если он существует
        let appDelegate = UIApplication.shared.delegate
        let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        if let originalMethod = class_getInstanceMethod(type(of: appDelegate!), originalSelector) {
            // Проверяем, что IMP метода не совпадает с нашим методом, чтобы избежать рекурсии
            let currentIMP = method_getImplementation(originalMethod)
            let ourMethod = class_getInstanceMethod(FrameworkAppDelegateProxy.self, #selector(FrameworkAppDelegateProxy.interceptedApplication(_:didRegisterForRemoteNotificationsWithDeviceToken:)))!
            let ourIMP = method_getImplementation(ourMethod)
            
            if currentIMP != ourIMP {
                typealias OriginalMethodSignature = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
                let originalMethodFunction = unsafeBitCast(currentIMP, to: OriginalMethodSignature.self)
                originalMethodFunction(appDelegate!, originalSelector, application, deviceToken)
            } else {
                print("WWWFrame: Avoiding recursive call to our own method")
            }
        }
        
        // Сбрасываем флаг после вызова
        objc_setAssociatedObject(self, "isCallingFromOurMethod", false, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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