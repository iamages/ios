import SwiftUI

struct CompletedUploadView: View {
    let image: IamagesImage
    
    private let roundedRectangle = RoundedRectangle(cornerRadius: 8)

    var body: some View {
        Link(destination: .apiRootUrl.appending(path: "/images/\(self.image.id)/embed")) {
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

struct CompletedUploadView_Previews: PreviewProvider {
    static var previews: some View {
        CompletedUploadView(image: previewImage)
    }
}
