import SwiftUI
import NukeUI

struct NavigableCollectionView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    let collection: IamagesCollection
    
    @State private var images: [IamagesImage] = []
    
    private func getCollectionImages() async {
        do {
            let newImages = try self.globalViewModel.jsond.decode(
                [IamagesImage].self,
                from: await self.globalViewModel.fetchData(
                    "/collections/\(self.collection.id)/images",
                    method: .post,
                    body: self.globalViewModel.jsone.encode(Pagination(limit: 4)),
                    contentType: .json
                ).0
            )
            self.images.append(contentsOf: newImages)
        } catch {
            print(error)
        }
    }
    
    private let roundedRectangle = RoundedRectangle(cornerRadius: 8)

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
                                CollectionImageThumbnailView(image: image)
                            }
                        }
                        if self.images.count < 4 {
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
                .clipShape(self.roundedRectangle)
                .overlay {
                    self.roundedRectangle
                        .stroke(.gray)
                }
            }
            VStack(alignment: .leading) {
                Text(self.collection.description)
                    .bold()
                    .lineLimit(1)
                HStack {
                    Image(systemName: self.collection.isPrivate ? "eye.slash.fill" : "eye.slash")
                }
            }
        }
        .task {
            if images.isEmpty {
                await getCollectionImages()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .editCollection)) { output in
            guard let notification = output.object as? IamagesCollectionEdit.Notification else {
                print("Couldn't parse edit collection notification.")
                return
            }
            if notification.id != self.collection.id { return }
            switch notification.edit.change {
            case .addImages:
                Task {
                    await getCollectionImages()
                }
            case .removeImages:
                switch notification.edit.to {
                case .stringArray(let ids):
                    self.images.removeAll(where: { ids.contains($0.id) })
                default:
                    break
                }
            default:
                break
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
