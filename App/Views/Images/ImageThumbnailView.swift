import SwiftUI
import NukeUI

struct ImageThumbnailView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let image: IamagesImage
    
    @State private var isFirstAppearance: Bool = true
    @State private var request: ImageRequest?
    
    var body: some View {
        if self.image.lock.isLocked {
            Image(systemName: "lock.doc.fill")
                .font(.title2)
        } else {
            LazyImage(request: self.request) { state in
                if let image = state.image {
                    image
                        .resizingMode(.aspectFill)
                } else if state.error != nil {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.title2)
                } else {
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .redacted(reason: .placeholder)
                    }
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
}

#if DEBUG
struct ImageThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageThumbnailView(image: previewImage)
            .environmentObject(GlobalViewModel())
    }
}
#endif
