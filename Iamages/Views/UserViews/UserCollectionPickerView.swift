import SwiftUI

fileprivate struct CollectionPickedView: View {
    let id: String
    @Binding var pickedCollectionID: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        Text("Picked a collection. Returning you back...")
            .onAppear {
                self.pickedCollectionID = id
                self.isPresented = false
            }
    }
}

fileprivate struct NavigableCollectionPickedView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    let collection: IamagesCollection
    @Binding var pickedCollectionID: String?
    @Binding var isPresented: Bool
    
    @State var collectionFiles: [IamagesFile] = []
    @State var isBusy: Bool = false
    
    var body: some View {
        NavigationLink(destination: CollectionPickedView(id: self.collection.id, pickedCollectionID: self.$pickedCollectionID, isPresented: self.$isPresented)) {
            if self.isBusy {
                ProgressView()
            } else {
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
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .task {
            if self.collectionFiles.isEmpty {
                self.isBusy = true
                do {
                    self.collectionFiles = try await self.dataObservable.getCollectionFiles(id: self.collection.id, limit: 4, startDate: nil)
                } catch {
                    print(error)
                }
                self.isBusy = false
            }
        }
    }
}

struct UserCollectionPickerView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var pickedCollectionID: String?
    @Binding var isPresented: Bool
    
    @State var isBusy: Bool = false
    @State var isFirstRefreshCompleted: Bool = false
    
    @State var errorAlertText: String?
    @State var isErrorAlertPresented: Bool = false
    
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedCollections: [IamagesCollection] = []
    
    func pageFeed () async {
        guard let username: String = self.dataObservable.currentAppUser?.username else {
            return
        }
        
        self.isBusy = true
        
        do {
            let receivedCollections: [IamagesCollection] = try await self.dataObservable.getUserCollections(username: username, startDate: self.lastFeedItemDate)
            self.feedCollections.append(contentsOf: receivedCollections)
            self.lastFeedItemDate = receivedCollections.last?.created
            if receivedCollections.count < self.dataObservable.loadLimit {
                self.isEndOfFeed = true
            }
        } catch {
            self.errorAlertText = error.localizedDescription
            self.isErrorAlertPresented = true
        }
        
        self.isBusy = false
    }
    
    func startFeed () async {
        if self.dataObservable.isLoggedIn {
            self.isBusy = true

            self.isEndOfFeed = false
            self.lastFeedItemDate = nil
            self.feedCollections = []
            await self.pageFeed()
        } else {
            self.isFirstRefreshCompleted = false
            self.errorAlertText = "You are not logged in. Use the user button above to do so, then come back here."
            self.isErrorAlertPresented = true
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.feedCollections) { collection in
                    NavigableCollectionPickedView(collection: collection, pickedCollectionID: self.$pickedCollectionID, isPresented: self.$isPresented)
                    .task {
                        if !self.isBusy && !self.isEndOfFeed && self.feedCollections.last == collection {
                            await self.pageFeed()
                        }
                    }
                }
            }
            .onAppear {
                if !self.isFirstRefreshCompleted {
                    Task {
                        await self.startFeed()
                    }
                    self.isFirstRefreshCompleted = true
                }
            }
            .refreshable {
                await self.startFeed()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        self.pickedCollectionID = nil
                        self.isPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: NewCollectionView(feedCollections: self.$feedCollections)) {
                        Label("New", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Pick a collection")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(self.isBusy)
        }
    }
}
