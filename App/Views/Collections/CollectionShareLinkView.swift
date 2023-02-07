import SwiftUI

struct CollectionShareLinkView: View {
    let collection: IamagesCollection
    
    var body: some View {
        ShareLink(item: .apiRootUrl.appending(path: "/collections/\(self.collection.id)/embed")) {
            Label(
                self.collection.isPrivate ? "Sharing not available because collection is private." : "Share collection...",
                systemImage: self.collection.isPrivate ? "square.and.arrow.up.trianglebadge.exclamationmark" : "square.and.arrow.up")
        }
        .disabled(self.collection.isPrivate)
    }
}

#if DEBUG
struct CollectionShareLinkView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionShareLinkView(
            collection: previewCollection
        )
    }
}
#endif
