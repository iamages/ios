import SwiftUI
import SharedWithYou

struct SWListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    
    @StateObject private var swViewModel = SWViewModel()
    
    @State private var collections: [IamagesCollection] = []
    @State private var collectionToDelete: IamagesCollection?
    @State private var navigationPath: [String] = []
    
    private func fetchHighlights(for highlights: [SWHighlight]) async {
        for highlight in highlights {
            if highlight.url.pathComponents.last != "embed" {
                continue
            }
            do {
                switch highlight.url.pathComponents[safe: 1] {
                case "images":
                    if let id = highlight.url.pathComponents[safe: 2] {
                        let image = try await self.globalViewModel.getImagePublicMetadata(id: id)
                        self.splitViewModel.images.insert(
                            IamagesImageAndMetadataContainer(id: image.id, image: image),
                            at: 0
                        )
                    }
                    break
                case "collections":
                    if let id = highlight.url.pathComponents[safe: 2] {
                        self.collections.insert(
                            try await self.globalViewModel.getCollectionInformation(id: id),
                            at: 0
                        )
                    }
                    break
                default:
                    continue
                }
            } catch {
                print(error)
                continue
            }
        }
    }
    
    @ViewBuilder
    private var list: some View {
        List {
            Section("Images") {
                ForEach(self.$splitViewModel.images) { imageAndMetadata in
                    SWImageWrapperView(
                        imageAndMetadata: imageAndMetadata,
                        swViewModel: self.swViewModel
                    )
                }
            }
            Section("Collections") {
                ForEach(self.collections) { collection in
                    SWCollectionWrapperView(
                        collection: collection,
                        swViewModel: self.swViewModel
                    )
                }
            }
        }
        .modifier(
            DeleteCollectionListenerModifier(
                collections: self.$collections,
                navigationPath: self.$navigationPath
            )
        )
        .modifier(
            DeleteCollectionAlertModifier(
                collectionToDelete: self.$collectionToDelete,
                globalViewModel: self.globalViewModel
            )
        )
        .navigationDestination(for: IamagesCollection.ID.self) { id in
            if let i = self.collections.firstIndex(where: { $0.id == id }),
               let collection = self.$collections[safe: i]
            {
                CollectionImagesListView(collection: collection)
                    .environmentObject(self.splitViewModel)
            } else {
                Text("Cannot open collection")
            }
        }
        .task {
            print(self.swViewModel.highlightCenter.highlights)
            await self.fetchHighlights(for: self.swViewModel.highlightCenter.highlights)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newSWHighlights)) { output in
            if let highlights = output.object as? [SWHighlight] {
                Task {
                    await self.fetchHighlights(for: highlights)
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if self.swViewModel.highlightCenter.highlights.isEmpty {
                IconAndInformationView(
                    icon: "shared.with.you",
                    heading: "Nothing Shared with You",
                    subheading: "Iamages embed links sent to you via Messages will appear here."
                )
            } else {
                NavigationStack(path: self.$navigationPath) {
                    self.list
                }
            }
        }
        .navigationTitle("Shared with You")
    }
}

struct SWistView_Previews: PreviewProvider {
    static var previews: some View {
        SWListView()
            .environmentObject(SplitViewModel())
    }
}
