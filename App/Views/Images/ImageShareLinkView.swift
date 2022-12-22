import SwiftUI

struct ImageShareLinkView: View {
    let image: IamagesImage
    
    var body: some View {
        ShareLink(item: URL.apiRootUrl.appending(path: "/images/\(image.id)/embed")) {
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
    }
}
#endif
