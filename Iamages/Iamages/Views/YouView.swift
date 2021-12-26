import SwiftUI

enum UserFeed: String, CaseIterable {
    case files = "Files"
    case collections = "Collections"
}

struct YouView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @State var selectedFeed: UserFeed = .files

    @State var isBusy: Bool = false
    @State var isFirstRefreshCompleted: Bool = false
    
    @State var errorAlertText: String?
    @State var isErrorAlertPresented: Bool = false
    
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedFiles: [IamagesFile] = []
    @State var feedCollections: [IamagesCollection] = []
    
    @State var isManageUserSheetPresented: Bool = false
    @State var isUserSearchSheetPresented: Bool = false
    
    func pageFeed () async {
        guard let username: String = self.dataObservable.currentAppUser?.username else {
            return
        }
        
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
        if self.dataObservable.isLoggedIn {
            self.isBusy = true

            self.isEndOfFeed = false
            self.lastFeedItemDate = nil
            self.feedFiles = []
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
                        NavigableCollectionView(collection: collection, feedCollections: self.$feedCollections, type: .privateFeed)
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
            .onChange(of: self.dataObservable.isLoggedIn) { isLoggedin in
                if isLoggedin {
                    Task {
                        await startFeed()
                    }
                } else {
                    self.feedFiles = []
                    self.feedCollections = []
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Feed", selection: self.$selectedFeed) {
                        ForEach(UserFeed.allCases, id: \.self) { feed in
                            Text(feed.rawValue)
                                .tag(feed)
                        }
                    }
                    .labelsHidden()
                    .disabled(self.isBusy)
                    .onChange(of: self.selectedFeed) { _ in
                        Task {
                            await self.startFeed()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if self.isBusy {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isUserSearchSheetPresented = true
                    }) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .disabled(!self.dataObservable.isLoggedIn || self.isBusy)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isManageUserSheetPresented = true
                    }) {
                        ProfileImageView(username: self.dataObservable.currentAppUser?.username)
                    }
                    .disabled(self.isBusy)
                }
            }
            .sheet(isPresented: self.$isUserSearchSheetPresented) {
                UserSearchView(username: self.dataObservable.currentAppUser?.username ?? "nil", type: .privateFeed, isUserSearchSheetPresented: self.$isUserSearchSheetPresented)
            }
            .sheet(isPresented: self.$isManageUserSheetPresented) {
                ManageUserView(isPresented: self.$isManageUserSheetPresented)
            }
            .alert("Feed loading failed", isPresented: self.$isErrorAlertPresented, actions: {}) {
                Text(self.errorAlertText ?? "Unknown error")
            }
            .navigationTitle("You")
        }
    }
}
