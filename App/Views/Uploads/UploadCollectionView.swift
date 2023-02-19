import SwiftUI

struct UploadCollectionView: View {
    let collection: IamagesCollection
    let completedUploads: [IamagesImage]
    
    private let roundedRectangle = RoundedRectangle(cornerRadius: 8)
    
    var body: some View {
        Link(destination: .apiRootUrl.appending(path: "/collections/\(self.collection.id)/embed")) {
            HStack {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 0, alignment: .center),
                        count: 2
                    ), spacing: 0) {
                    Group {
                        ForEach(self.completedUploads) { image in
                            if image.lock.isLocked {
                                Image(systemName: "lock.doc")
                            } else {
                                CollectionImageThumbnailView(image: image)
                            }
                        }
                        if self.completedUploads.count < 4 {
                            ForEach((1...(4-self.completedUploads.count)).reversed(), id: \.self) { _ in
                                Rectangle()
                                    .fill(.gray)
                                    .redacted(reason: .placeholder)
                            }
                        }
                    }
                    .frame(width: 32, height: 32, alignment: .center)
                    .clipped()
                }
                .frame(width: 64, height: 64)
                .clipShape(self.roundedRectangle)
                .overlay {
                    self.roundedRectangle
                        .stroke(.gray)
                }
                VStack(alignment: .leading) {
                    Text(self.collection.description)
                        .bold()
                        .lineLimit(1)
                    HStack {
                        Image(systemName: self.collection.isPrivate ? "eye.slash.fill" : "eye.slash")
                    }
                }
                Spacer()
                Image(systemName: "chevron.forward")
            }
        }
        .contextMenu {
            CollectionShareLinkView(collection: self.collection)
        }
    }
}

#if DEBUG
struct UploadCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        UploadCollectionView(
            collection: previewCollection,
            completedUploads: []
        )
    }
}
#endif
