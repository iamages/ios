import SwiftUI
import OrderedCollections

struct CollectionsListView: View {
    enum ViewMode {
        case normal
        case picker
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @ObservedObject var splitViewModel: SplitViewModel
    let viewMode: ViewMode
    let imageID: String?
    @Binding var isPresented: Bool
    
    init(
        splitViewModel: SplitViewModel,
        viewMode: ViewMode = .normal,
        imageID: String? = nil,
        isPresented: Binding<Bool> = .constant(false)
    ) {
        self.splitViewModel = splitViewModel
        self.viewMode = viewMode
        self.imageID = imageID
        self._isPresented = isPresented
    }
    
    @State private var collections: OrderedDictionary<String, IamagesCollection> = [:]
    @State private var isBusy: Bool = false
    @State private var isFirstPageLoaded: Bool = false
    @State private var isEndOfFeed: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var queryString: String = ""
    @State private var querySuggestions: [String] = []
    
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if self.isPresented {
                    Button("Cancel") {
                        self.isPresented = false
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
                    CollectionImagesListView(collection: collection, splitViewModel: self.splitViewModel)
                } else {
                    Text("Cannot open collection.")
                }
            case .picker:
                if let imageID {
                    AddToCollectionView(collectionID: id, imageID: imageID, isPresented: self.$isPresented)
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .editCollection)) { output in
            
        }
    }
}

#if DEBUG
struct CollectionsListView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionsListView(
            splitViewModel: SplitViewModel()
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
