import SwiftUI

struct UploadedView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let uploaded: IamagesImage
    
    var body: some View {
        if !uploaded.lock.isLocked {
            Image(systemName: "lock.fill")
        } else {
            ImageThumbnailView(image: self.uploaded)
        }
    }
}

struct UploadedView_Previews: PreviewProvider {
    static var previews: some View {
        UploadedView(uploaded: previewImage)
    }
}
