import SharedWithYou
import SwiftUI

@MainActor
class SWViewModel: NSObject, ObservableObject, SWHighlightCenterDelegate {
    var highlightCenter = SWHighlightCenter()
    
    override init() {
        super.init()
        self.highlightCenter.delegate = self
    }

    nonisolated internal func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
        highlightCenter.highlights.forEach { highlight in
            print("Received a new highlight with URL: \(highlight.url)")
        }
    }
}
