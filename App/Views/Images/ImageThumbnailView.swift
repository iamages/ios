import SwiftUI
import NukeUI

struct ImageThumbnailView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let image: IamagesImage
    
    var body: some View {
        LazyImage(request: self.globalViewModel.getThumbnailRequest(for: self.image)) { state in
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
    }
}

struct ImageThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageThumbnailView(image: previewImage)
            .environmentObject(GlobalViewModel())
    }
}
