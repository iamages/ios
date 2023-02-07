import SwiftUI
import NukeUI

struct CollectionImageThumbnailView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let image: IamagesImage
    
    @State private var isFirstAppearance: Bool = true
    @State private var request: ImageRequest?

    var body: some View {
        LazyImage(request: self.request) { state in
            if let image = state.image {
                image
                    .animatedImageRenderingEnabled(false)
                    .videoRenderingEnabled(false)
                    .resizingMode(.aspectFill)
            } else if state.error != nil {
                Image(systemName: "exclamationmark.octagon")
            } else {
                Rectangle()
                    .redacted(reason: .placeholder)
            }
        }
        .task {
            if self.isFirstAppearance {
                self.isFirstAppearance = false
                self.request = await self.globalViewModel.getThumbnailRequest(for: self.image)
            }
        }
    }
}

#if DEBUG
struct CollectionImageThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionImageThumbnailView(image: previewImage)
            .environmentObject(GlobalViewModel())
    }
}
#endif
