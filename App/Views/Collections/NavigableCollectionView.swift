import SwiftUI
import NukeUI

struct NavigableCollectionView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let collection: IamagesCollection
    @State private var images: [IamagesImage] = []
    
    private func getCollectionImages() async throws {
        self.images = try self.globalViewModel.jsond.decode(
            [IamagesImage].self,
            from: await self.globalViewModel.fetchData(
                "/collections/\(self.collection.id)/images",
                queryItems: [
                    URLQueryItem(name: "limit", value: "4")
                ],
                method: .get
            ).0
        )
    }
    
    private func collectionImageView(for image: IamagesImage) -> some View {
        LazyImage(request: self.globalViewModel.getThumbnailRequest(for: image)) { state in
            if let image = state.image {
                image
                    .resizingMode(.aspectFill)
            } else if state.error != nil {
                Image(systemName: "exclamationmark.octagon")
            } else {
                Rectangle()
                    .redacted(reason: .placeholder)
            }
        }
    }

    var body: some View {
        NavigationLink(value: self.collection.id) {
            HStack {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 0, alignment: .center),
                        count: 2
                    ), spacing: 0) {
                    Group {
                        ForEach(self.images) { image in
                            if image.lock.isLocked {
                                Image(systemName: "lock.doc")
                            } else {
                                self.collectionImageView(for: image)
                            }
                        }
                        if 4-self.images.count > 1 {
                            ForEach((1...(4-self.images.count)).reversed(), id: \.self) { _ in
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
                .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text(self.collection.metadata.description)
                    .bold()
                    .lineLimit(1)
                HStack {
                    Image(systemName: self.collection.isPrivate ? "eye.slash.fill" : "eye.slash")
                }
            }
        }
        .task {
            if images.isEmpty {
                do {
                    try await getCollectionImages()
                } catch {
                    print(error)
                }
            }
        }
    }
}

#if DEBUG
struct NavigableCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableCollectionView(collection: previewCollection)
            .environmentObject(GlobalViewModel())
    }
}
#endif
