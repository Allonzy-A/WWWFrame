# WWWFrame

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.7+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Allonzy-A/WWWFrame.git", from: "1.0.0")
]
```

Or add it directly via Xcode:
1. Go to File > Add Packages
2. Paste the repository URL: `https://github.com/Allonzy-A/WWWFrame.git`
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


## License

This framework is released under the MIT License. See LICENSE file for details. 