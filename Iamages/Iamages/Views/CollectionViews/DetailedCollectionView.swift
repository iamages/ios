import SwiftUI

struct DetailedCollectionView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var collection: IamagesCollection
    @Binding var feed: [IamagesCollection]
    let type: FeedType
    
    @State var isBusy: Bool = false
    @State var isDeleted: Bool = false
    @State var isFirstRefreshCompleted: Bool = false
    
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedFiles: [IamagesFile] = []
    
    @State var feedLoadFailAlertText: String?
    @State var isFeedLoadFailAlertPresented: Bool = false
    
    @State var isShareSheetPresented: Bool = false
    @State var isDetailSheetPresented: Bool = false
    @State var isModifyCollectionSheetPresented: Bool = false

    @State var isDeleteAlertPresented: Bool = false
    
    func pageFeed () async {
        self.isBusy = true
        
        do {
            let receivedFiles: [IamagesFile] = try await self.dataObservable.getCollectionFiles(
                id: self.collection.id,
                limit: nil,
                startDate: self.lastFeedItemDate
            )
            self.feedFiles.append(contentsOf: receivedFiles)
            self.lastFeedItemDate = receivedFiles.last?.created
            if receivedFiles.count < self.dataObservable.loadLimit {
                self.isEndOfFeed = true
            }
        } catch {
            self.feedLoadFailAlertText = error.localizedDescription
            self.isFeedLoadFailAlertPresented = true
        }
        
        self.isBusy = false
    }
    
    func startFeed () async {
        self.isBusy = true

        self.isEndOfFeed = false
        self.lastFeedItemDate = nil
        self.feedFiles = []
        await self.pageFeed()
    }
    
    func delete () async {
        self.isBusy = true
        do {
            try await self.dataObservable.deleteCollection(id: self.collection.id)
            self.isDeleted = true
        } catch {
            print(error)
            self.isBusy = false
        }
    }
    
    func report () {
        UIApplication.shared.open(URL(
            string: "mailto:iamages@uber.space?subject=\("Report collection: \(self.collection.id)".urlEncode())&body=\("Reason:".urlEncode())"
        )!)
    }
    
    var body: some View {
        Group {
            if self.isDeleted {
                RemovedSuggestView()
            } else {
                List {
                    ForEach(self.$feedFiles) { file in
                        NavigableFileView(file: file, feed: self.$feedFiles, type: .publicFeed)
                            .task {
                                if !self.isBusy && !self.isEndOfFeed && self.feedFiles.last == file.wrappedValue {
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
                    ToolbarItem(placement: .navigationBarLeading) {
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
                    ToolbarItem(placement: .principal) {
                        Button(action: {
                            self.isDetailSheetPresented = true
                        }) {
                            Label("Details", systemImage: "info.circle")
                        }
                        .disabled(self.isBusy)
                    }
                    ToolbarItem {
                        Menu(content: {
                            Section {
                                Button(action: {
                                    self.isShareSheetPresented = true
                                }) {
                                    Label("Share link", systemImage: "square.and.arrow.up")
                                }
                            }
                            if self.collection.owner != nil && self.collection.owner! == self.dataObservable.currentAppUser?.username {
                                Section {
                                    Button(action: {
                                        self.isModifyCollectionSheetPresented = true
                                    }) {
                                        Label("Modify", systemImage: "pencil")
                                    }
                                    Button(role: .destructive, action: {
                                        self.isDeleteAlertPresented = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            Section {
                                Button(action: self.report) {
                                    Label("Report collection", systemImage: "exclamationmark.bubble")
                                }
                            }
                        }) {
                            Label("Actions", systemImage: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .disabled(self.isBusy)
                        .confirmationDialog(
                            "'\(self.collection.description)' will be deleted.",
                            isPresented: self.$isDeleteAlertPresented,
                            titleVisibility: .visible
                        ) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await self.delete()
                                }
                            }
                        }
                        
                    }
                }
                .sheet(isPresented: self.$isDetailSheetPresented) {
                    CollectionDetailsView(collection: self.$collection, isDetailSheetPresented: self.$isDetailSheetPresented)
                }
                .sheet(isPresented: self.$isShareSheetPresented) {
                    ShareView(activityItems: [self.dataObservable.getCollectionEmbedURL(id: self.collection.id)])
                }
                .alert("Feed loading error", isPresented: self.$isFeedLoadFailAlertPresented, actions: {}, message: {
                    Text(self.feedLoadFailAlertText ?? "Unknown error.")
                })
                .navigationTitle(self.collection.description)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(self.isBusy)
            }
        }
        .sheet(isPresented: self.$isModifyCollectionSheetPresented) {
            ModifyCollectionView(collection: self.$collection, feed: self.$feed, type: self.type, isDeleted: self.$isDeleted, isModifyCollectionSheetPresented: self.$isModifyCollectionSheetPresented)
        }
    }
}
