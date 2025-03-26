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
    registerAPNSToken(deviceToken: deviceToken)
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
        registerAPNSToken(deviceToken: deviceToken)
    }
}
```

## How It Works

1. When the app launches:
   - All internal processes are stopped
   - Push notification permissions are requested
   - App Tracking Transparency permissions are requested
   - Data collection begins (APNS token, ATT token, bundle ID)

2. After 10 seconds:
   - Framework collects all available data (using stubs for any missing values)
   - A domain is generated from the bundle ID
   - A Base64-encoded request URL is created
   - A GET request is sent to the server

3. Server response handling:
   - If non-empty string is returned: 
     - "https://" is added to create a valid URL
     - A WebView is displayed with the URL
     - The URL is cached for future use
   - If empty string is returned:
     - Normal app operations resume
     - WebView is not used

## License

This framework is released under the MIT License. See LICENSE file for details. 