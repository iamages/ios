import SwiftUI

class CustomScrollView: UIScrollView {
    override public var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "+", modifierFlags: .command, action: #selector(zoomIn)),
            UIKeyCommand(input: "-", modifierFlags: .command, action: #selector(zoomOut))
        ]
    }
    
    @objc func zoomIn(sender: UIKeyCommand) {
        print(self.zoomScale)
        if self.zoomScale < self.maximumZoomScale {
            self.setZoomScale(self.zoomScale + 1, animated: true)
        }
    }
    
    @objc func zoomOut(sender: UIKeyCommand) {
        if self.zoomScale > self.minimumZoomScale {
            self.setZoomScale(self.zoomScale - 1, animated: true)
        }
    }
}

// Thanks to Stack Overflow!
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = CustomScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 1
        scrollView.bounces = true
        scrollView.bouncesZoom = true

        // create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)

        return scrollView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }
    
    static func dismantleUIView(_ uiView: UIScrollView, coordinator: Coordinator) {
        uiView.delegate = nil
        coordinator.hostingController.view = nil
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>

        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
