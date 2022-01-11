import SwiftUI

struct CollectionFilesListView: View {
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
    
    #if !targetEnvironment(macCatalyst)
    @State var isShareSheetPresented: Bool = false
    #endif
    @State var isInfoSheetPresented: Bool = false
    @State var isModifyCollectionSheetPresented: Bool = false

    @State var isDeleteAlertPresented: Bool = false
    @State var deleteFailedMessage: String?
    @State var isDeleteFailedAlertPresented: Bool = false
    
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
            if let position = self.feed.firstIndex(of: self.collection) {
                self.feed.remove(at: position)
            }
            self.isDeleted = true
        } catch {
            self.deleteFailedMessage = error.localizedDescription
            self.isDeleteFailedAlertPresented = true
            self.isBusy = false
        }
    }
    
    func copyLink () {
        UIPasteboard.general.setValue(
            self.dataObservable.getCollectionEmbedURL(id: self.collection.id),
            forPasteboardType: "public.url"
        )
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
                #if !targetEnvironment(macCatalyst)
                .refreshable {
                    await self.startFeed()
                }
                #endif
                .toolbar {
                    #if targetEnvironment(macCatalyst)
                    ToolbarItem(placement: .primaryAction) {
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
                    ToolbarItem(placement: .status) {
                        if self.isBusy {
                            ProgressView()
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Button(action: {
                            self.isInfoSheetPresented = true
                        }) {
                            Label("Info", systemImage: "info.circle")
                        }
                        .disabled(self.isBusy)
                        .keyboardShortcut("i")
                    }
                    ToolbarItem {
                        Menu(content: {
                            Section {
                                #if targetEnvironment(macCatalyst)
                                Button("Copy link") {
                                    self.copyLink()
                                }
                                #else
                                Button(action: {
                                    self.isShareSheetPresented = true
                                }) {
                                    Label("Share link", systemImage: "square.and.arrow.up")
                                }
                                #endif
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
                .customSheet(isPresented: self.$isInfoSheetPresented) {
                    CollectionInfoView(collection: self.$collection, isPresented: self.$isInfoSheetPresented)
                }
                #if !targetEnvironment(macCatalyst)
                .customSheet(isPresented: self.$isShareSheetPresented) {
                    ShareView(activityItems: [self.dataObservable.getCollectionEmbedURL(id: self.collection.id)], isPresented: self.$isShareSheetPresented)
                }
                #endif
                .customBindingAlert(title: "Feed loading failed", message: self.$feedLoadFailAlertText, isPresented: self.$isFeedLoadFailAlertPresented)
                .customBindingAlert(title: "Delete failed", message: self.$deleteFailedMessage, isPresented: self.$isDeleteFailedAlertPresented)
                .navigationTitle(self.collection.description)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(self.isBusy)
            }
        }
        .customSheet(isPresented: self.$isModifyCollectionSheetPresented) {
            ModifyCollectionInfoView(collection: self.$collection, feed: self.$feed, type: self.type, isDeleted: self.$isDeleted, isPresented: self.$isModifyCollectionSheetPresented)
        }
    }
}
