import UIKit
import SwiftUI

class StatusBarManager {
    static func hideStatusBar() {
        if #available(iOS 16.0, *) {
            // For iOS 16 and later, we need to use the windowScene's statusBarManager
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let statusBarManager = windowScene.statusBarManager
                // We can't directly set the hidden property, but we can use SwiftUI's .statusBar(hidden: true)
                // which is done in the WebViewContainer
            }
        } else {
            // For iOS 15, we need to use the Info.plist setting "UIViewControllerBasedStatusBarAppearance" = YES
            // And then set the preferredStatusBarStyle and modalPresentationCapturesStatusBarAppearance
            // This is handled in the UIHostingController setup in FrameworkManager.showWebView
            
            // Force update status bar
            UIApplication.shared.windows.first?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    static func configureStatusBarForHostingController<T: View>(_ controller: UIHostingController<T>) {
        controller.modalPresentationCapturesStatusBarAppearance = true
        controller.setNeedsStatusBarAppearanceUpdate()
    }
} 