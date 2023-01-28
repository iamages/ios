import SwiftUI
struct CollectionImagesListView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    
    @Binding var collection: IamagesCollection

    @State private var isBusy: Bool = false
    @State private var isFirstAppearance: Bool = true
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    @State private var isEditSheetPresented: Bool = false
    
    @State private var imageToRemove: IamagesImageAndMetadataContainer?
    
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
                            lastID: self.splitViewModel.images.last?.id
                        )
                    ),
                    contentType: .json,
                    authStrategy: .whenPossible
                ).0
            )
            if newImages.count < 6 {
                self.isEndOfFeed = true
            }
            withAnimation {
                self.splitViewModel.images.append(
                    contentsOf: newImages.map({ IamagesImageAndMetadataContainer(id: $0.id, image: $0) })
                )
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func startFeed() async {
        self.splitViewModel.selectedImage = nil
        self.splitViewModel.images = []
        self.isEndOfFeed = false
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
                if let i = self.splitViewModel.images.firstIndex(where: { $0.id == id }) {
                    self.splitViewModel.images.remove(at: i)
                }
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
    private func removeFromCollectionButton(
        for imageAndMetadata: IamagesImageAndMetadataContainer
    ) -> some View {
        Button(role: .destructive, action: {
            self.imageToRemove = imageAndMetadata
        }) {
            Label("Remove from collection", systemImage: "rectangle.stack.badge.minus")
        }
    }
    
    var body: some View {
        List(selection: self.$splitViewModel.selectedImage) {
            ForEach(self.$splitViewModel.images) { imageAndMetadata in
                NavigableImageView(
                    imageAndMetadata: imageAndMetadata
                )
                .contextMenu {
                    self.removeFromCollectionButton(for: imageAndMetadata.wrappedValue)
                }
                .task {
                    if !self.isEndOfFeed && self.splitViewModel.images.last?.id == imageAndMetadata.wrappedValue.id {
                        await self.pageFeed()
                    }
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
            if self.isFirstAppearance {
                self.isFirstAppearance = false
                await self.startFeed()
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
        .alert(
            "Remove from collection?",
            isPresented: .constant(self.imageToRemove != nil),
            presenting: self.imageToRemove
        ) { imageAndMetadata in
            Button("Remove", role: .destructive) {
                Task {
                    await removeImage(id: imageAndMetadata.id)
                }
                self.imageToRemove = nil
            }
            Button("Cancel", role: .cancel) {
                self.imageToRemove = nil
            }
        } message: { imageAndMetadata in
            if let description = imageAndMetadata.metadataContainer?.data.description {
                Text("'\(description)' will be removed from this collection!")
            } else {
                Text("The selected image will be removed from the collection!")
            }
            
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
            #if targetEnvironment(macCatalyst)
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
            #endif
        }
    }
}

#if DEBUG
struct CollectionImagesListView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionImagesListView(
            collection: .constant(previewCollection)
        )
        .environmentObject(GlobalViewModel())
        .environmentObject(SplitViewModel())
    }
}
#endif
