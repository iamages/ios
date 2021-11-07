import SwiftUI
import Kingfisher

struct NavigableImageView: View {
    @Binding var file: FileModal
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
            ZStack {
                HStack {
                    // Profile picture
                    Text(verbatim: file.owner ?? "Anonymous")
                }
                // Main image
                // Description
            }
        }
    }
}

struct NavigableImageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageView(file: .constant(FileModal(id: "", description: "", isNSFW: false, isPrivate: false, isHidden: false, created: Date(), mime: "", width: 0, height: 0, owner: nil, views: nil)))
    }
}
