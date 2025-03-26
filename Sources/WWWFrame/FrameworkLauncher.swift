import SwiftUI

public struct FrameworkLauncher {
    public static func start() {
        FrameworkManager.shared.launch()
    }
} 