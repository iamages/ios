import SwiftUI

enum SearchFeed: String, CaseIterable {
    case files = "Files"
    case collections = "Collections"
    case users = "Users"
}

struct SearchView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @State var selectedFeed: SearchFeed = .files
    
    @State var isBusy: Bool = false

    @State var searchString: String = ""
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedFiles: [IamagesFile] = []
    @State var feedCollections: [IamagesCollection] = []
    @State var feedUsers: [IamagesUser] = []
    
    func pageFeed () async {
        self.isBusy = true
        
        do {
            switch self.selectedFeed{
            case .files:
                let receivedFiles: [IamagesFile] = try await self.dataObservable.getSearchFiles(description: self.searchString, startDate: self.lastFeedItemDate, username: nil)
                self.feedFiles.append(contentsOf: receivedFiles)
                self.lastFeedItemDate = receivedFiles.last?.created
                if receivedFiles.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            case .collections:
                let receivedCollections: [IamagesCollection] = try await self.dataObservable.getSearchCollections(description: self.searchString, startDate: self.lastFeedItemDate, username: nil)
                self.feedCollections.append(contentsOf: receivedCollections)
                self.lastFeedItemDate = receivedCollections.last?.created
                if receivedCollections.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            case .users:
                let receivedUsers: [IamagesUser] = try await self.dataObservable.getSearchUsers(username: self.searchString, startDate: self.lastFeedItemDate)
                self.feedUsers.append(contentsOf: receivedUsers)
                self.lastFeedItemDate = receivedUsers.last?.created
                if receivedUsers.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            }
        } catch {
            print(error)
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
            self.feedUsers = []
            await self.pageFeed()
        } else {
            print("Empty search string!")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
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
                            NavigableCollectionView(collection: collection)
                                .task {
                                    if !self.isBusy && !self.isEndOfFeed && self.feedCollections.last == collection.wrappedValue {
                                        await self.pageFeed()
                                    }
                                }
                        }
                    case .users:
                        ForEach(self.feedUsers, id: \.self) { user in
                            NavigableUserView(user: user)
                                .task {
                                    if !self.isBusy && !self.isEndOfFeed && self.feedUsers.last == user {
                                        await self.pageFeed()
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .searchable(text: self.$searchString)
            .onSubmit(of: .search) {
                Task {
                    await self.startFeed()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Search", selection: self.$selectedFeed) {
                        ForEach(SearchFeed.allCases, id: \.self) { search in
                            Text(search.rawValue)
                                .tag(search)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if self.isBusy {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
