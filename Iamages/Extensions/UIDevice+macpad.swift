import SwiftUI

extension UIDevice {
    public var isDeviceMacOrPad: Bool {
        if userInterfaceIdiom == .mac || userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
}
