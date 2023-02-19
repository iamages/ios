import SwiftUI
import SharedWithYou

struct SWImageWrapperView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer
    @ObservedObject var swViewModel: SWViewModel
    
    @State private var highlight: SWHighlight?
    @State private var error: Error?

    var body: some View {
        VStack {
            NavigableImageView(imageAndMetadata: self.$imageAndMetadata)
            if let highlight {
                SWAttributionViewSwiftUI(highlight: highlight)
            } else if let error {
                Text(error.localizedDescription)
                    .lineLimit(1)
                    .background {
                        Capsule()
                            .fill(.gray)
                    }
            } else {
                ProgressView()
                    .task {
                        do {
                            self.highlight = try await self.swViewModel.highlightCenter.highlight(for: self.globalViewModel.getImageEmbedURL(id: self.imageAndMetadata.id))
                        } catch {
                            self.error = error
                        }
                    }
            }
        }
    }
}

#if DEBUG
struct SWImageWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        SWImageWrapperView(
            imageAndMetadata: .constant(previewImageAndMetadata),
            swViewModel: SWViewModel()
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
