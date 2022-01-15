// TODO: Check every new SDK release whether this is needed anymore.
//
// Patch for Mac Catalyst not showing the primary view (a.k.a sidebar)
// by default on launch.
//
// Thanks to: https://stackoverflow.com/a/68532980/13319205

#if targetEnvironment(macCatalyst)
import SwiftUI

extension UISplitViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumPrimaryColumnWidth = 220
        self.preferredDisplayMode = .twoBesideSecondary
    }
}
#endif
