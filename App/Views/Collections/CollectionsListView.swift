import SwiftUI

struct CollectionsListView: View {
    enum ViewMode {
        case normal
        case picker
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @EnvironmentObject private var splitViewModel: SplitViewModel
    @Environment(\.dismiss) private var dismiss

    let viewMode: ViewMode
    var imageID: String? = nil
    
    @State private var collections: [IamagesCollection] = []
    @State private var isBusy: Bool = false
    @State private var isFirstAppearance: Bool = true
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var queryString: String = ""
    @State private var querySuggestions: [String] = []

    @State private var collectionToDelete: String?
    @State private var isAddedToCollection: Bool = false
    @State private var navigationPath: [String] = []
    
    private func pageFeed() async {
        self.isBusy = true
        
        do {
            let newCollections: [IamagesCollection] = try self.globalViewModel.jsond.decode(
                [IamagesCollection].self,
                from: try await self.globalViewModel.fetchData(
                    "/users/collections",
                    method: .post,
                    body: self.globalViewModel.jsone.encode(
                        Pagination(
                            query: self.queryString.isEmpty ? nil : self.queryString,
                            lastID: self.collections.last?.id
                        )
                    ),
                    contentType: .json,
                    authStrategy: .required
                ).0
            )
            if newCollections.count < 6 {
                self.isEndOfFeed = true
            }
            withAnimation {
                self.collections.append(contentsOf: newCollections)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    private func startFeed() async {
        self.collections = []
        await self.pageFeed()
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
                    "/users/collections/suggestions",
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
    
    private func deleteCollection(id: String) async {
        do {
            try await self.globalViewModel.fetchData(
                "/collections/\(id)",
                method: .delete,
                authStrategy: .required
            )
            if let i = self.collections.firstIndex(where: { $0.id == id }) {
                withAnimation {
                    self.collections.remove(at: i)
                }
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    @ViewBuilder
    private func deleteCollectionButton(id: String) -> some View {
        Button(role: .destructive, action: {
            self.collectionToDelete = id
        }) {
            Label("Delete collection", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var list: some View {
        List {
            ForEach(self.collections) { collection in
                NavigableCollectionView(collection: collection)
                    .task {
                        if !self.isEndOfFeed && self.collections.last?.id == collection.id {
                            await self.pageFeed()
                        }
                    }
                    .swipeActions {
                        if self.viewMode == .normal {
                            self.deleteCollectionButton(id: collection.id)
                        }
                    }
                    .contextMenu {
                        CollectionShareLinkView(collection: collection)
                        Divider()
                        self.deleteCollectionButton(id: collection.id)
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
        .errorToast(error: self.$error)
        .refreshable {
            await self.startFeed()
        }
        .task {
            if self.isFirstAppearance {
                self.isFirstAppearance = false
                await startFeed()
            }
        }
        .searchable(text: self.$queryString)
        .task(id: self.queryString) {
            await loadSuggestions()
        }
        .searchSuggestions {
            QuerySuggestionsView(suggestions: self.$querySuggestions)
        }
        .onSubmit(of: .search) {
            Task {
                await self.startFeed()
            }
        }
        .onChange(of: self.navigationPath) { path in
            if path.isEmpty {
                switch self.viewMode {
                case .normal:
                    self.splitViewModel.selectedImage = nil
                    self.splitViewModel.images = []
                case .picker:
                    if self.isAddedToCollection {
                        self.dismiss()
                    }
                }
            }
        }
        .alert("Delete collection?", isPresented: .constant(self.collectionToDelete != nil), presenting: self.collectionToDelete) { id in
            Button("Delete", role: .destructive) {
                Task {
                    await self.deleteCollection(id: id)
                }
            }
        } message: { _ in
            Text("The selected collection will be deleted. The images it contains will not be deleted.")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if self.viewMode == .picker {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
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
        .navigationDestination(for: IamagesCollection.ID.self) { id in
            switch self.viewMode {
            case .normal:
                if let i = self.collections.firstIndex(where: { $0.id == id }),
                   let collection = self.$collections[i]
                {
                    CollectionImagesListView(collection: collection)
                        .environmentObject(self.splitViewModel)
                } else {
                    Text("Cannot open collection")
                }
            case .picker:
                if let imageID {
                    AddToCollectionView(
                        collectionID: id, imageID: imageID,
                        isAddedToCollection: self.$isAddedToCollection
                    )
                } else {
                    Text("Image not provided.")
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: self.$navigationPath) {
            Group {
                if self.globalViewModel.userInformation == nil {
                    NotLoggedInView()
                } else {
                    switch self.viewMode {
                    case .normal:
                        self.list
                    case .picker:
                        self.list
                            .navigationTitle("Select a collection")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
            .navigationTitle("Collections")
            #if !targetEnvironment(macCatalyst)
            .newMenuToolbarItem(globalViewModel: self.globalViewModel)
            #endif
        }
    }
}

#if DEBUG
struct CollectionsListView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionsListView(
            viewMode: .normal,
            imageID: nil
        )
        .environmentObject(GlobalViewModel())
        .environmentObject(SplitViewModel())
    }
}
#endif
