import SwiftUI

extension Bundle {
    public var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    public var build: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}
