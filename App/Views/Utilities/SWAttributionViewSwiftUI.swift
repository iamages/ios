import SwiftUI
import SharedWithYou

struct SWAttributionViewSwiftUI: UIViewRepresentable {
    let highlight: SWHighlight
    
    func makeUIView(context: Context) -> some UIView {
        let attributionView = SWAttributionView()
        attributionView.horizontalAlignment = .leading
        attributionView.displayContext = .summary
        attributionView.highlight = self.highlight
        return attributionView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
