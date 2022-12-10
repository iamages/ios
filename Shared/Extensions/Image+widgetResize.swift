import SwiftUI

#if os(iOS)
extension UIImage {
    func widgetResize(to width: CGFloat) -> UIImage {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/self.size.width * self.size.height)))
        let image = UIGraphicsImageRenderer(size: canvas).image { _ in
            draw(in: CGRect(origin: .zero, size: canvas))
        }
        return image.withRenderingMode(self.renderingMode)
    }
}
#else
extension NSImage {
    func widgetResize(to width: CGFloat) -> NSImage {
        return self
    }
}
#endif
