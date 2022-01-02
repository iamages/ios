import SwiftUI

struct NavigableCollectionFilesListView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var collection: IamagesCollection
    @Binding var feedCollections: [IamagesCollection]
    let type: FeedType
    
    @State var collectionFiles: [IamagesFile] = []
    @State var isBusy: Bool = false
    
    var body: some View {
        NavigationLink(destination: CollectionFilesListView(collection: self.$collection, feed: self.$feedCollections, type: self.type)) {
            VStack(alignment: .leading) {
                Label(title: {
                    Text(verbatim: self.collection.owner ?? "Anonymous")
                        .bold()
                        .lineLimit(1)
                }, icon: {
                    ProfileImageView(username: self.collection.owner)
                })
                LazyVGrid(columns: [GridItem(), GridItem()]) {
                    ForEach(self.collectionFiles) { file in
                        FileThumbnailView(id: file.id)
                    }
                }
                Text(verbatim: self.collection.description)
                    .lineLimit(1)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .task {
            if self.collectionFiles.isEmpty {
                do {
                    self.collectionFiles = try await self.dataObservable.getCollectionFiles(id: self.collection.id, limit: 4, startDate: nil)
                } catch {
                    print(error)
                }
            }
        }
        .onDrag {
            return NSItemProvider(item: self.dataObservable.getCollectionEmbedURL(id: self.collection.id) as NSSecureCoding, typeIdentifier: "public.url")
        }
    }
}
