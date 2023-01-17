import SwiftUI
import OrderedCollections

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
    
    @State private var collections: OrderedDictionary<String, IamagesCollection> = [:]
    @State private var isBusy: Bool = false
    @State private var isFirstPageLoaded: Bool = false
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var queryString: String = ""
    @State private var querySuggestions: [String] = []
    
    @State private var selectedCollectionId: String?
    
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
                            lastID: self.collections.keys.last
                        )
                    ),
                    contentType: .json,
                    authStrategy: .required
                ).0
            )
            if newCollections.count < 6 {
                self.isEndOfFeed = true
            }
            for newCollection in newCollections {
                self.collections[newCollection.id] = newCollection
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        
        self.isBusy = false
    }
    
    private func startFeed() async {
        self.collections = [:]
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
            withAnimation {
                self.collections.removeValue(forKey: id)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    @ViewBuilder
    private func deleteCollectionButton(id: String) -> some View {
        Button(role: .destructive, action: {
            self.selectedCollectionId = id
        }) {
            Label("Delete collection", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var list: some View {
        List {
            ForEach(self.collections.elements, id: \.key) { collection in
                NavigableCollectionView(collection: collection.value)
                    .task {
                        if !self.isEndOfFeed && self.collections.keys.last == collection.key {
                            await self.pageFeed()
                        }
                    }
                    .swipeActions {
                        if self.viewMode == .normal {
                            self.deleteCollectionButton(id: collection.key)
                        }
                    }
                    .contextMenu {
                        CollectionShareLinkView(collection: collection.value)
                        Divider()
                        self.deleteCollectionButton(id: collection.key)
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
            if !self.isFirstPageLoaded {
                await startFeed()
                self.isFirstPageLoaded = true
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
        .alert("Delete collection?", isPresented: .constant(self.selectedCollectionId != nil)) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let id = self.selectedCollectionId else {
                        return
                    }
                    self.selectedCollectionId = nil
                    await self.deleteCollection(id: id)
                }
            }
        } message: {
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
                if let collection = Binding<IamagesCollection>(self.$collections[id]) {
                    CollectionImagesListView(collection: collection)
                        .environmentObject(self.splitViewModel)
                } else {
                    Text("Cannot open collection.")
                }
            case .picker:
                if let imageID {
                    AddToCollectionView(collectionID: id, imageID: imageID)
                } else {
                    Text("Image not provided.")
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
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
            .sheet(isPresented: self.$globalViewModel.isNewCollectionPresented) {
                NewCollectionView()
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.globalViewModel.isNewCollectionPresented = true
                    }) {
                        Label("New collection", systemImage: "plus")
                    }
                }
            }
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
