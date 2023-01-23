import SwiftUI

struct DeleteImageListenerModifier: ViewModifier {
    @ObservedObject var splitViewModel: SplitViewModel
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deleteImage)) { output in
                guard let id = output.object as? String,
                      let i = self.splitViewModel.images.firstIndex(where: { $0.id == id }) else {
                    return
                }
                if self.splitViewModel.selectedImage == id {
                    withAnimation {
                        self.splitViewModel.selectedImage = nil
                    }
                }
                withAnimation {
                    self.splitViewModel.images.remove(at: i)
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
