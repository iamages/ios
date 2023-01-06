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
    
    @State private var removeImageID: String?
    
    @State private var queryString: String = ""
    @State private var querySuggestions: [String] = []
    
    private func pageFeed() async {
        self.isBusy = true
        do {
            let newImages = try self.globalViewModel.jsond.decode(
                [IamagesImage].self,
                from: await self.globalViewModel.fetchData(
                    "/collections/\(self.collection.id)/images",
                    method: .post,
                    body: self.globalViewModel.jsone.encode(
                        Pagination(
                            query: self.queryString.isEmpty ? self.queryString : nil,
                            lastID: self.images.keys.last
                        )
                    ),
                    contentType: .json,
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
    
    private func removeImage(id: String) async {
        do {
            try await self.globalViewModel.fetchData(
                "/collections/\(self.collection.id)",
                method: .patch,
                body: self.globalViewModel.jsone.encode(
                    IamagesCollectionEdit(
                        change: .removeImages,
                        to: .stringArray([id])
                    )
                ),
                contentType: .json,
                authStrategy: .required
            )
            withAnimation {
                self.images.removeValue(forKey: id)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func loadSuggestions() async {
        if self.queryString.isEmpty {
            self.querySuggestions = []
            return
        }
        do {
            self.querySuggestions = try self.globalViewModel.jsond.decode(
                [String].self,
                from: await self.globalViewModel.fetchData(
                    "/collections/\(self.collection.id)/images/suggestions",
                    method: .post,
                    body: self.queryString.data(using: .utf8),
                    contentType: .text,
                    authStrategy: .required
                ).0
            )
        } catch {
            self.querySuggestions = []
        }
    }
    
    @ViewBuilder
    private func removeFromCollectionButton(id: String) -> some View {
        Button(role: .destructive, action: {
            self.removeImageID = id
        }) {
            Label("Remove from collection", systemImage: "rectangle.stack.badge.minus")
        }
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        self.removeFromCollectionButton(id: image.key)
                    }
                    .contextMenu {
                        ImageShareLinkView(image: image.value)
                        Divider()
                        self.removeFromCollectionButton(id: image.key)
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
        .navigationTitle(self.collection.description)
        .errorToast(error: self.$error)
        .refreshable {
            await self.startFeed()
        }
        .task {
            if !self.isFirstPageLoaded {
                await self.startFeed()
                self.isFirstPageLoaded = true
            }
        }
        .searchable(text: self.$queryString)
        .onSubmit(of: .search) {
            Task {
                await self.startFeed()
            }
        }
        .task(id: self.queryString) {
            await self.loadSuggestions()
        }
        .searchSuggestions {
            QuerySuggestionsView(suggestions: self.$querySuggestions)
        }
        .sheet(isPresented: self.$isEditSheetPresented) {
            EditCollectionInformationView(
                collection: self.$collection
            )
        }
        .alert("Remove from collection?", isPresented: .constant(self.removeImageID != nil)) {
            Button("Remove", role: .destructive) {
                Task {
                    guard let id = self.removeImageID else {
                        return
                    }
                    self.removeImageID = nil
                    await removeImage(id: id)
                }
            }
        } message: {
            Text("The selected image will be removed from the collection. You will need to add it back again to see it in this collection.")
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
                CollectionShareLinkView(collection: self.collection)
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
