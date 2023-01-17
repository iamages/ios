import SwiftUI

struct CompletedUploadView: View {
    let image: IamagesImage

    var body: some View {
        Link(destination: .apiRootUrl.appending(path: "/images/\(self.image.id)/embed")) {
            ImageThumbnailView(image: self.image)
                .frame(width: 64, height: 64)
                .cornerRadius(8)
        }
        .contextMenu {
            ImageShareLinkView(image: self.image)
        }
    }
}

struct CompletedUploadView_Previews: PreviewProvider {
    static var previews: some View {
        CompletedUploadView(image: previewImage)
    }
}
