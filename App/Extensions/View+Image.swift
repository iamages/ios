import SwiftUI
import OrderedCollections

struct DeleteImageListenerModifier: ViewModifier {
    @ObservedObject var splitViewModel: SplitViewModel
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deleteImage)) { output in
                guard let id = output.object as? String else {
                    return
                }
                if self.splitViewModel.selectedImage == id {
                    self.splitViewModel.selectedImage = nil
                }
                withAnimation {
                    self.splitViewModel.images.removeValue(forKey: id)
                }
            }
    }
}

extension View {
    func deleteImageListener(
        splitViewModel: SplitViewModel
    ) -> some View {
        modifier(
            DeleteImageListenerModifier(
                splitViewModel: splitViewModel
            )
        )
    }
}
