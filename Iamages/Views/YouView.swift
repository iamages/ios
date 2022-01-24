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

    @State var isThirdPanePresented: Bool = true
    
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
            
            self.isThirdPanePresented = false
        } else {
            self.isFirstRefreshCompleted = false
            self.errorAlertText = "You are not logged in. Use the user button above to do so, then come back here."
            self.isErrorAlertPresented = true
        }
    }

    var body: some View {
        List {
            switch self.selectedFeed {
            case .files:
                ForEach(self.$feedFiles) { file in
                    NavigableFileView(file: file, feed: self.$feedFiles, type: .privateFeed)
                        .task {
                            if !self.isBusy && !self.isEndOfFeed && !self.feedFiles.isEmpty && self.feedFiles.last == file.wrappedValue {
                                await self.pageFeed()
                            }
                        }
                }
            case .collections:
                ForEach(self.$feedCollections) { collection in
                    NavigableCollectionFilesListView(collection: collection, feedCollections: self.$feedCollections, type: .privateFeed)
                        .task {
                            if !self.isBusy && !self.isEndOfFeed && !self.feedFiles.isEmpty && self.feedCollections.last == collection.wrappedValue {
                                await self.pageFeed()
                            }
                        }
                }
            }
        }
        .onAppear {
            if !self.isFirstRefreshCompleted {
                self.isThirdPanePresented = true
                Task {
                    await self.startFeed()
                }
                self.isFirstRefreshCompleted = true
            }
        }
        .onChange(of: self.dataObservable.isLoggedIn) { isLoggedin in
            self.isThirdPanePresented = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if isLoggedin {
                    Task {
                        await self.startFeed()
                    }
                } else {
                    self.feedFiles = []
                    self.feedCollections = []
                }
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
                .pickerStyle(.menu)
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
                    self.isUserSearchSheetPresented = true
                }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("f")
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isThirdPanePresented = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Task {
                            await self.startFeed()
                        }
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(self.isBusy)
            }
            ToolbarItem(placement: .status) {
                if self.isBusy {
                    ProgressView()
                }
            }
        }
        .customSheet(isPresented: self.$isUserSearchSheetPresented) {
            UserSearchView(username: self.dataObservable.currentAppUser?.username ?? "nil", type: .privateFeed, isUserSearchSheetPresented: self.$isUserSearchSheetPresented)
        }
        .customSheet(isPresented: self.$isManageUserSheetPresented) {
            ManageUserView(isPresented: self.$isManageUserSheetPresented)
        }
        .customBindingAlert(title: "Feed loading failed", message: self.$errorAlertText, isPresented: self.$isErrorAlertPresented)
        .listAndDetailViewFix(isThirdPanePresented: self.$isThirdPanePresented)
        .navigationTitle("You")
    }
}
