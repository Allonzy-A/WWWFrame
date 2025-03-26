import SwiftUI

public struct FrameworkLauncher {
    /// Запускает фреймворк
    public static func start() {
        FrameworkManager.shared.launch()
    }
} 