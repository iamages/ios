import SwiftUI
import Kingfisher

struct FileThumbnailView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    let id: String

    var body: some View {
        KFAnimatedImage(self.dataObservable.getFileThumbnailURL(id: self.id))
            .placeholder {
                ProgressView()
            }
            .cancelOnDisappear(true)
            .scaledToFit()
    }
}

struct FileThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        FileThumbnailView(id: "")
    }
}
