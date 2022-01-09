#if !targetEnvironment(macCatalyst)
import Foundation

extension Bundle {
    public var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    public var build: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    public var copyright: String {
        return Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© jkelol111"
    }
}
#endif
