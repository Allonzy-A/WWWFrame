# WWWFrame

Swift-фреймворк для iOS для интеграции в мобильные приложения. Обрабатывает логику первого запуска и отображает WebView на основе ответа сервера.

## Интеграция

```swift
import SwiftUI
import WWWFrame

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    WWWFrameLauncher.start()
                }
        }
    }
}
```

## Требования

- iOS 15.0+
- Swift 5.0+

## License

MIT 