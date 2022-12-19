import SwiftUI
import OrderedCollections

struct CollectionImagesListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @Binding var collection: IamagesCollection
    @ObservedObject var splitViewModel: SplitViewModel

    @State private var images: OrderedDictionary<String, IamagesImage> = [:]
    @State private var isFirstPageLoaded: Bool = false
    @State private var isBusy: Bool = false
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    @State private var isEditSheetPresented: Bool = false
    @State private var isRemoveImageAlertPresented: Bool = false
    
    private func pageFeed() async {
        self.isBusy = true
        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "limit", value: "6")
            ]
            if let lastID = self.images.values.last?.id {
                queryItems.append(URLQueryItem(name: "last_id", value: lastID))
            }
            let newImages = try self.globalViewModel.jsond.decode(
                [IamagesImage].self,
                from: await self.globalViewModel.fetchData(
                    "/collections/\(self.collection.id)/images",
                    queryItems: queryItems,
                    method: .get,
                    authStrategy: .whenPossible
                ).0
            )
            if newImages.count < 6 {
                self.isEndOfFeed = true
            }
            for newImage in newImages {
                self.images[newImage.id] = newImage
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func startFeed() async {
        self.images = [:]
        await self.pageFeed()
    }
    
    private func removeImage(image: IamagesImage) async {
        
    }
    
    var body: some View {
        List(selection: self.$splitViewModel.selectedImage) {
            ForEach(self.images.elements, id: \.key) { image in
                NavigableImageView(image: image.value)
                    .task {
                        if !self.isEndOfFeed && self.images.keys.last == image.key {
                            await self.pageFeed()
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive, action: {
                            self.isRemoveImageAlertPresented = true
                        }) {
                            Label("Remove from collection", systemImage: "rectangle.stack.badge.minus")
                        }
                    }
                    .confirmationDialog("Remove from collection?", isPresented: self.$isRemoveImageAlertPresented) {
                        Button("Remove", role: .destructive) {
                            Task {
                                await removeImage(image: image.value)
                            }
                        }
                    } message: {
                        Text("The selected image will be removed from the collection")
                    }
            }
            if self.isBusy {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle(collection.metadata.description)
        .errorToast(error: self.$error)
        .onDisappear {
            self.splitViewModel.selectedImage = nil
            self.splitViewModel.selectedImageMetadata = nil
        }
        .refreshable {
            await self.startFeed()
        }
        .task {
            if !self.isFirstPageLoaded {
                await self.startFeed()
                self.isFirstPageLoaded = true
            }
        }
        .sheet(isPresented: self.$isEditSheetPresented) {
            EditCollectionInformationView(
                collection: self.$collection,
                isPresented: self.$isEditSheetPresented
            )
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if self.collection.owner == self.globalViewModel.userInformation?.username {
                    Button(action: {
                        self.isEditSheetPresented = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            ToolbarItem {
                ShareLink(item: URL.apiRootUrl.appending(path: "/collections/\(self.collection.id)/embed"))
                    .disabled(self.collection.isPrivate)
            }
            ToolbarItem {
                Button(action: {
                    Task {
                        await self.startFeed()
                    }
                }) {
                   Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
                .disabled(self.isBusy)
            }
        }
    }
}

#if DEBUG
struct CollectionImagesListView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionImagesListView(
            collection: .constant(previewCollection),
            splitViewModel: SplitViewModel()
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
