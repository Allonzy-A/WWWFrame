# WWWFrame

A SwiftUI framework for iOS that manages first launch logic and WebView display based on server responses.

## Features

- Manages first app launch workflow
- Requests push notification permissions
- Requests App Tracking Transparency permissions
- Collects necessary data (APNS token, ATT token, bundle ID)
- Makes server requests and displays WebView based on response
- Caches WebView URL for future launches
- Provides debug output for all operations

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.7+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/WWWFrame.git", from: "1.0.0")
]
```

Or add it directly via Xcode:
1. Go to File > Add Packages
2. Paste the repository URL: `https://github.com/yourusername/WWWFrame.git`
3. Click Add Package

### Required Info.plist Configuration

To properly hide the status bar, add the following to your app's Info.plist:

```xml
<key>UIViewControllerBasedStatusBarAppearance</key>
<true/>
```

## Usage

### Basic Integration

1. Import the framework in your AppDelegate or main entry point:

```swift
import WWWFrame
```

2. Start the framework with a single line:

```swift
WWWFrameLauncher.start()
```

3. To handle push notification tokens, add the following to your AppDelegate:

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Передаем APNS токен во фреймворк
    FrameworkLauncher.registerAPNSToken(deviceToken: deviceToken)
}
```

### Example Integration (SwiftUI)

```swift
import SwiftUI
import WWWFrame

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    WWWFrameLauncher.start()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Передаем APNS токен во фреймворк
        FrameworkLauncher.registerAPNSToken(deviceToken: deviceToken)
    }
}
```

## Как это работает

**ВАЖНОЕ ОБНОВЛЕНИЕ: Больше не требуется настраивать AppDelegate для получения APNS токена! Фреймворк автоматически перехватывает все необходимые вызовы.**

### Интеграция за одну строку

Все, что вам нужно для интеграции фреймворка, это одна строка кода:

```swift
import SwiftUI
import WWWFrame

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Это все, что нужно! Фреймворк автоматически 
                    // обработает все необходимые разрешения и токены
                    WWWFrameLauncher.start()
                }
        }
    }
}
```

### Как фреймворк получает APNS токен

Фреймворк автоматически:
1. Инициализирует прокси систему, которая безопасно перехватывает системные вызовы для APNS токенов
2. Запрашивает необходимые разрешения (пуш-уведомления, ATT)
3. Сохраняет полученные токены в безопасном хранилище
4. Формирует запрос к серверу с собранными данными

### Отладка проблем

Если вам нужно проверить статус APNS токена, вы можете использовать встроенную функцию отладки:

```swift
WWWFrameLauncher.debugPushNotificationStatus()
```

Эта функция выведет в консоль информацию о:
- Зарегистрировано ли приложение для пуш-уведомлений
- Текущий APNS токен (если есть)
- Настройки уведомлений

## Устаревшие методы интеграции (не рекомендуются)

Ранее требовалось настраивать AppDelegate для получения APNS токена. Эти методы по-прежнему работают для обратной совместимости, но они отмечены как устаревшие и не рекомендуются к использованию.

## License

This framework is released under the MIT License. See LICENSE file for details. 