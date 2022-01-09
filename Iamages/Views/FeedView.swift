import SwiftUI
import StoreKit

enum PublicFeed: String, CaseIterable {
    case latestFiles = "Latest Files"
    case popularFiles = "Popular Files"
    case randomFiles = "Random File"
    case latestCollections = "Latest Collections"
}

struct FeedView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    @AppStorage("feedOpenedCount") var feedOpenedCount: Int = 0

    @State var errorAlertText: String?
    @State var isErrorAlertPresented: Bool = false

    @State var isBusy: Bool = true
    @State var isFirstRefreshCompleted: Bool = false
    
    @State var selectedFeed: PublicFeed = .latestFiles
    @State var isEndOfFeed: Bool = false
    @State var lastFeedItemDate: Date?
    @State var feedFiles: [IamagesFile] = []
    @State var feedCollections: [IamagesCollection] = []
    
    #if targetEnvironment(macCatalyst)
    @State var isThirdPanePresented: Bool = true
    #endif
    
    func pageFeed () async {
        self.isBusy = true

        do {
            switch self.selectedFeed {
            case .latestFiles:
                let receivedFiles: [IamagesFile] = try await self.dataObservable.getLatestFiles(
                    startDate: self.lastFeedItemDate
                )
                self.feedFiles.append(contentsOf: receivedFiles)
                self.lastFeedItemDate = receivedFiles.last?.created
                if receivedFiles.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            case .popularFiles:
                self.feedFiles = try await self.dataObservable.getPopularFiles()
                self.isEndOfFeed = true
            case .randomFiles:
                self.feedFiles = [try await self.dataObservable.getRandomFile()]
                self.isEndOfFeed = true
            case .latestCollections:
                let receivedCollections: [IamagesCollection] = try await self.dataObservable.getLatestCollections(
                    startDate: self.lastFeedItemDate
                )
                self.feedCollections.append(contentsOf: receivedCollections)
                self.lastFeedItemDate = receivedCollections.last?.created
                if receivedCollections.count < self.dataObservable.loadLimit {
                    self.isEndOfFeed = true
                }
            }
        } catch {
            print(error)
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
            if self.selectedFeed != .latestCollections {
                ForEach(self.$feedFiles) { file in
                    if self.selectedFeed == .latestFiles {
                        NavigableFileView(file: file, feed: self.$feedFiles, type: .publicFeed)
                            .task {
                                if !self.isBusy && !self.isEndOfFeed && self.feedFiles.last == file.wrappedValue {
                                    await self.pageFeed()
                                }
                            }
                    } else {
                        NavigableFileView(file: file, feed: self.$feedFiles, type: .publicFeed)
                    }
                }
            } else {
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
        .onAppear {
            if !self.isFirstRefreshCompleted {
                Task {
                    await self.startFeed()
                }
                self.isFirstRefreshCompleted = true
                self.feedOpenedCount += 1
            }
        }
        #if !targetEnvironment(macCatalyst)
        .refreshable {
            await self.startFeed()
        }
        #endif
        .onDisappear {
            if self.feedOpenedCount > 20 {
                self.feedOpenedCount = 0
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive })
                            as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("Feed", selection: self.$selectedFeed) {
                    ForEach(PublicFeed.allCases, id: \.self) { feed in
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
        }
        .alert("Feed loading failed", isPresented: self.$isErrorAlertPresented, actions: {}) {
            Text(self.errorAlertText ?? "Unknown error")
        }
        .navigationTitle("Feed")
        #if targetEnvironment(macCatalyst)
        .background {
            NavigationLink(destination: RemovedSuggestView(), isActive: self.$isThirdPanePresented) {
                EmptyView()
            }
        }
        #endif
    }
}