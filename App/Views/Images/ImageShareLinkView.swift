import SwiftUI

struct ImageShareLinkView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let image: IamagesImage
    
    var body: some View {
        ShareLink(item: self.globalViewModel.getImageEmbedURL(id: self.image.id)) {
            Label(
                self.image.isPrivate ? "Sharing not available because image is private." : "Share image...",
                systemImage: self.image.isPrivate ? "square.and.arrow.up.trianglebadge.exclamationmark" : "square.and.arrow.up")
        }
        .disabled(self.image.isPrivate)
    }
}

#if DEBUG
struct ImageShareLinkView_Previews: PreviewProvider {
    static var previews: some View {
        ImageShareLinkView(image: previewImage)
            .environmentObject(GlobalViewModel())
    }
}
#endif
