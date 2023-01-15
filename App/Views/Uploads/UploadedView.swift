import SwiftUI
import NukeUI

struct UploadedView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let uploaded: IamagesImage
    
    var body: some View {
        if !uploaded.lock.isLocked {
            Image(systemName: "lock.fill")
        } else {
            LazyImage(request: self.globalViewModel.getThumbnailRequest(for: self.uploaded)) { state in
                if let image = state.image {
                    image
                        .resizingMode(.aspectFill)
                } else if state.error != nil {
                    Image(systemName: "exclamationmark.octagon.fill")
                } else {
                    Rectangle()
                        .redacted(reason: .placeholder)
                }
            }
        }
    }
}

struct UploadedView_Previews: PreviewProvider {
    static var previews: some View {
        UploadedView(uploaded: previewImage)
    }
}
