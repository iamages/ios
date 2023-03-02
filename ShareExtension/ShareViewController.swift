import SwiftUI

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent share sheet dismissal.
        self.isModalInPresentation = true
        
        let shareView = ShareView()
            .environment(\.extensionContext, self.extensionContext)

        let hostingController = UIHostingController(rootView: shareView)
    
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)

        // Expand hosted SwiftUI VC to sheet size.
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
}
