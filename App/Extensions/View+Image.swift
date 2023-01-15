import SwiftUI
import OrderedCollections

struct DeleteImageListenerModifier: ViewModifier {
    @Binding var images: OrderedDictionary<String, IamagesImageAndMetadataContainer>
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
                self.images.removeValue(forKey: id)
            }
    }
}

extension View {
    func deleteImageListener(
        images: Binding<OrderedDictionary<String, IamagesImageAndMetadataContainer>>,
        splitViewModel: SplitViewModel
    ) -> some View {
        modifier(
            DeleteImageListenerModifier(
                images: images,
                splitViewModel: splitViewModel
            )
        )
    }
}
