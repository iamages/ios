import SharedWithYou
import SwiftUI

class SWViewModel: NSObject, ObservableObject, SWHighlightCenterDelegate {
    var highlightCenter = SWHighlightCenter()
    
    override init() {
        super.init()
        self.highlightCenter.delegate = self
    }

    internal func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
        NotificationCenter.default.post(name: .newSWHighlights, object: highlightCenter.highlights)
    }
}
