import WidgetKit
import Foundation
import SwiftUI

struct ImageWidgetEntry: TimelineEntry {
    let date: Date = Date.now
    var id: String? = nil
    #if os(iOS)
    var image: UIImage?
    #else
    var image: NSImage?
    #endif
    var description: String?
    var errors: [Error] = []
    
    mutating func setImage(data: Data, size: CGSize) {
        #if os(iOS)
        self.image = UIImage(data: data)?.widgetResize(to: size.width)
        #else
        self.image = NSImage(data: data)?.widgetResize(to: size.width)
        #endif
    }
}
