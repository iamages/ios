import SwiftUI

/*
 Bundle icon extension thanks to:
 https://stackoverflow.com/a/65862395/13319205
 */

extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let icon = files.last
        {
            return UIImage(named: icon)
        }
        return nil
    }
    public var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}
