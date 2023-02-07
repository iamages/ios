import SwiftUI

extension EnvironmentValues {
    private struct ExtensionContext: EnvironmentKey {
        static var defaultValue: NSExtensionContext?
    }
    
    var extensionContext: NSExtensionContext? {
        get { self[ExtensionContext.self] }
        set {
            self[ExtensionContext.self] = newValue
        }
    }
}
