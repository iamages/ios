import SwiftUI

struct CompletedUploadView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let image: IamagesImage
    
    private let roundedRectangle = RoundedRectangle(cornerRadius: 8)

    var body: some View {
        Link(destination: self.globalViewModel.getImageEmbedURL(id: self.image.id)) {
            ImageThumbnailView(image: self.image)
                .frame(width: 64, height: 64)
                .clipShape(self.roundedRectangle)
                .overlay {
                    self.roundedRectangle
                        .stroke(.gray)
                }
        }
        .contextMenu {
            ImageShareLinkView(image: self.image)
        }
    }
}

#if DEBUG
struct CompletedUploadView_Previews: PreviewProvider {
    static var previews: some View {
        CompletedUploadView(image: previewImage)
            .environmentObject(GlobalViewModel())
    }
}
#endif
