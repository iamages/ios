import SwiftUI

struct PublicUserView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    let username: String
    
    @State var selectedFeed: UserFeed = .files

    @State var isBusy: Bool = false
    @State var isFirstRefreshCompleted: Bool = false
    
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedFiles: [IamagesFile] = []
    @State var feedCollections: [IamagesCollection] = []
    
    @State var errorAlertText: String?
    @State var isErrorAlertPresented: Bool = false
    
    @State var isUserSearchSheetPresented: Bool = false
    
    func pageFeed () async {
        self.isBusy = true
        
        do {
            switch self.selectedFeed {
            case .files:
                let receivedFiles: [IamagesFile] = try await self.dataObservable.getUserFiles(username: username, startDate: self.lastFeedItemDate)
                self.feedFiles.append(contentsOf: receivedFiles)
                self.lastFeedItemDate = receivedFiles.last?.created
                if receivedFiles.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            case .collections:
                let receivedCollections: [IamagesCollection] = try await self.dataObservable.getUserCollections(username: username, startDate: self.lastFeedItemDate)
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
        self.isBusy = true

        self.isEndOfFeed = false
        self.lastFeedItemDate = nil
        self.feedFiles = []
        self.feedCollections = []
        await self.pageFeed()
    }
    
    var body: some View {
        List {
            switch self.selectedFeed {
            case .files:
                ForEach(self.$feedFiles) { file in
                    NavigableFileView(file: file, feed: self.$feedFiles, type: .privateFeed)
                        .task {
                            if !self.isBusy && !self.isEndOfFeed && self.feedFiles.last == file.wrappedValue {
                                await self.pageFeed()
                            }
                        }
                }
            case .collections:
                ForEach(self.$feedCollections) { collection in
                    NavigableCollectionFilesListView(collection: collection, feedCollections: self.$feedCollections, type: .privateFeed)
                        .task {
                            if !self.isBusy && !self.isEndOfFeed && self.feedCollections.last == collection.wrappedValue {
                                await self.pageFeed()
                            }
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
            ToolbarItem {
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
            #if targetEnvironment(macCatalyst)
            ToolbarItem(placement: .primaryAction) {
                if self.isBusy {
                    ProgressView()
                } else {
                    Button(action: {
                        Task {
                            await self.startFeed()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                }
            }
            #endif
            ToolbarItem {
                Button(action: {
                    self.isUserSearchSheetPresented = true
                    self.dataObservable.isModalPresented = true
                }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("f")
                .disabled(self.isBusy)
            }
        }
        .sheet(isPresented: self.$isUserSearchSheetPresented, onDismiss: {
            self.dataObservable.isModalPresented = false
        }) {
            UserSearchView(username: self.username, type: .publicFeed, isUserSearchSheetPresented: self.$isUserSearchSheetPresented)
        }
        .alert("Feed loading failed", isPresented: self.$isErrorAlertPresented, actions: {}) {
            Text(self.errorAlertText ?? "Unknown error")
        }
        .navigationTitle(self.username)
    }
}
