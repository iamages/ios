// TODO: Check every new SDK release whether this is needed anymore.
// Patch for Mac Catalyst not showing the primary view (a.k.a sidebar)
// by default on launch.
#if targetEnvironment(macCatalyst)
import SwiftUI

extension UISplitViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.maximumPrimaryColumnWidth = 220
        self.show(.primary)
    }
}
#endif
