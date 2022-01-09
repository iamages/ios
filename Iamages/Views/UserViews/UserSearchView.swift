import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    let username: String
    let type: FeedType
    @Binding var isUserSearchSheetPresented: Bool
    
    @State var selectedFeed: UserFeed = .files
    
    @State var isBusy: Bool = false

    @State var searchString: String = ""
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedFiles: [IamagesFile] = []
    @State var feedCollections: [IamagesCollection] = []
    
    @State var isErrorAlertPresented: Bool = false
    @State var errorAlertText: String?
    
    func pageFeed () async {
        self.isBusy = true
        
        do {
            switch self.selectedFeed {
            case .files:
                let receivedFiles: [IamagesFile] = try await self.dataObservable.getSearchFiles(description: self.searchString, startDate: self.lastFeedItemDate, username: self.username)
                self.feedFiles.append(contentsOf: receivedFiles)
                self.lastFeedItemDate = receivedFiles.last?.created
                if receivedFiles.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            case .collections:
                let receivedCollections: [IamagesCollection] = try await self.dataObservable.getSearchCollections(description: self.searchString, startDate: self.lastFeedItemDate, username: self.username)
                self.feedCollections.append(contentsOf: receivedCollections)
                self.lastFeedItemDate = receivedCollections.last?.created
                if receivedCollections.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            }
        } catch {
            self.errorAlertText = error.localizedDescription
            self.isErrorAlertPresented = true
        }
        
        self.isBusy = false
    }
    
    func startFeed () async {
        if !self.searchString.isEmpty {
            self.isBusy = true

            self.isEndOfFeed = false
            self.lastFeedItemDate = nil
            self.feedFiles = []
            self.feedCollections = []
            await self.pageFeed()
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                switch self.selectedFeed {
                case .files:
                    ForEach(self.$feedFiles) { file in
                        NavigableFileView(file: file, feed: self.$feedFiles, type: .publicFeed)
                            .task {
                                if !self.isBusy && !self.isEndOfFeed && self.feedFiles.last == file.wrappedValue {
                                    await self.pageFeed()
                                }
                            }
                    }
                case .collections:
                    ForEach(self.$feedCollections) { collection in
                        NavigableCollectionFilesListView(collection: collection, feedCollections: self.$feedCollections, type: .publicFeed)
                            .task {
                                if !self.isBusy && !self.isEndOfFeed && self.feedCollections.last == collection.wrappedValue {
                                    await self.pageFeed()
                                }
                            }
                    }
                }
            }
            .searchable(text: self.$searchString)
            .onSubmit(of: .search) {
                Task {
                    await self.startFeed()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !self.isBusy {
                        Button(action: {
                            self.isUserSearchSheetPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                        .disabled(self.isBusy)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Picker("Feed", selection: self.$selectedFeed) {
                        ForEach(UserFeed.allCases, id: \.self) { feed in
                            Text(feed.rawValue)
                                .tag(feed)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .disabled(self.isBusy)
                    .onChange(of: self.selectedFeed) { _ in
                        Task {
                            await self.startFeed()
                        }
                    }
                }
                ToolbarItem(placement: .status) {
                    if self.isBusy {
                        ProgressView()
                    }
                }
            }
            .alert("Feed loading failed", isPresented: self.$isErrorAlertPresented, actions: {}) {
                Text(self.errorAlertText ?? "Unknown error")
            }
            .navigationTitle(self.username)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(self.isBusy)
    }
}
