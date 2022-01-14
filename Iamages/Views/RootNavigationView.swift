import SwiftUI

fileprivate enum URLViewable: String {
    case file
    case collection
    case user
}

fileprivate struct URLViewerView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    @Binding var type: URLViewable
    @Binding var id: String
    @Binding var isPresented: Bool

    @State var isBusy: Bool = true
    
    @State var file: IamagesFile = IamagesFile(id: "", description: "", isNSFW: false, isPrivate: false, isHidden: false, created: Date(), mime: "", width: 0, height: 0)
    @State var collection: IamagesCollection = IamagesCollection(id: "", description: "", isPrivate: false, isHidden: false, created: Date())
    @State var feedFiles: [IamagesFile] = []
    @State var feedCollections: [IamagesCollection] = []
    
    @State var isNavigationLinkActive: Bool = false
    @State var onAppearCount: Int = 0
    
    var body: some View {
        NavigationView {
            ProgressView("Locating \(self.type.rawValue)...")
                .task {
                    if onAppearCount == 0 {
                        do {
                            switch self.type {
                            case .file:
                                self.file = try await self.dataObservable.getFileInformation(id: self.id)
                                self.feedFiles.append(self.file)
                            case .collection:
                                self.collection = try await self.dataObservable.getCollectionInformation(id: self.id)
                                self.feedCollections.append(self.collection)
                            case .user:
                                break
                            }
                            self.onAppearCount += 1
                            self.isNavigationLinkActive = true
                        } catch {
                            print(error)
                        }
                        self.isBusy = false
                    } else {
                        self.isPresented = false
                    }
                }
                .background {
                    switch self.type {
                    case .file:
                        NavigationLink(destination: FileView(file: self.$file, feed: self.$feedFiles, type: .publicFeed), isActive: self.$isNavigationLinkActive) {}
                    case .collection:
                        NavigationLink(destination: CollectionFilesListView(collection: self.$collection, feed: self.$feedCollections, type: .publicFeed), isActive: self.$isNavigationLinkActive) {}
                    case .user:
                        NavigationLink(destination: PublicUserView(username: self.id), isActive: self.$isNavigationLinkActive) {}
                    }
                }
        }
        .interactiveDismissDisabled(self.isBusy)
    }
}

fileprivate struct CommonViewModifiers: ViewModifier {
    @EnvironmentObject var dataObservable: APIDataObservable

    #if targetEnvironment(macCatalyst)
    @Binding var selectedTabItem: AppNavigationView?
    #else
    @Binding var selectedTabItem: AppNavigationView
    #endif
    @State var type: URLViewable = .file
    @State var id: String = ""
    @State var isOpenURLInvalidAlertPresented: Bool = false
    @State var isSheetAlreadyOpenAlertPresented: Bool = false
    @State var isURLViewerSheetPresented: Bool = false
    
    func handleOpenURL(_ url: URL) {
        if url.scheme == "iamages" {
            switch url.host {
            case "feed":
                self.selectedTabItem = .feed
            case "search":
                self.selectedTabItem = .search
            case "upload":
                self.selectedTabItem = .upload
            case "you":
                self.selectedTabItem = .you
            case "view":
                if self.dataObservable.isModalPresented {
                    self.isSheetAlreadyOpenAlertPresented = true
                } else {
                    guard let components: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
                          let queryArgs: [URLQueryItem] = components.queryItems,
                          let type: URLViewable = URLViewable(rawValue: queryArgs.first?.value ?? ""),
                          let id: String = queryArgs[1].value else {
                        self.isOpenURLInvalidAlertPresented = true
                        return
                    }
                    self.type = type
                    self.id = id
                    self.isURLViewerSheetPresented = true
                }
            default:
                self.isOpenURLInvalidAlertPresented = true
            }
        } else {
            self.isOpenURLInvalidAlertPresented = true
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onOpenURL(perform: self.handleOpenURL)
            .customFixedAlert(title: "Open URL failed", message: "Provided open URL is invalid.", isPresented: self.$isOpenURLInvalidAlertPresented)
            .customFixedAlert(title: "A sheet is already presented.", message: "Please dismiss it to open the viewer.", isPresented: self.$isSheetAlreadyOpenAlertPresented)
            .customSheet(isPresented: self.$isURLViewerSheetPresented) {
                URLViewerView(type: self.$type, id: self.$id, isPresented: self.$isURLViewerSheetPresented)
            }
    }
}

struct RootNavigationView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    #if targetEnvironment(macCatalyst)
    @Binding var selectedTabItem: AppNavigationView?
    #else
    @Binding var selectedTabItem: AppNavigationView
    #endif

    var body: some View {
        #if targetEnvironment(macCatalyst)
        NavigationView {
            List {
                NavigationLink(tag: AppNavigationView.feed, selection: self.$selectedTabItem, destination: {
                    FeedView()
                }) {
                    Label("Feed", systemImage: "newspaper")
                }
                NavigationLink(tag: AppNavigationView.search, selection: self.$selectedTabItem, destination: {
                    SearchView()
                }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                NavigationLink(tag: AppNavigationView.upload, selection: self.$selectedTabItem, destination: {
                    UploadView()
                }) {
                    Label("Upload", systemImage: "square.and.arrow.up.on.square")
                }
                NavigationLink(tag: AppNavigationView.you, selection: self.$selectedTabItem, destination: {
                    YouView()
                }) {
                    Label("You", systemImage: "person")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Iamages")
            RemovedSuggestView()
            RemovedSuggestView()
        }
        // Disabling window titlebar in Catalyst.
        .withHostingWindow { window in
            if let titlebar = window?.windowScene?.titlebar {
                titlebar.titleVisibility = .hidden
            }
        }
        .modifier(CommonViewModifiers(selectedTabItem: self.$selectedTabItem))
        #else
        TabView(selection: self.$selectedTabItem) {
            NavigationView {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "newspaper")
            }
            .tag(AppNavigationView.feed)

            NavigationView {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(AppNavigationView.search)

            NavigationView {
                UploadView()
            }
            .tabItem {
                Label("Upload", systemImage: "square.and.arrow.up.on.square")
            }
            .tag(AppNavigationView.upload)

            NavigationView {
                YouView()
            }
            .tabItem {
                Label("You", systemImage: "person")
            }
            .tag(AppNavigationView.you)

            NavigationView {
                PreferencesView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Preferences", systemImage: "gearshape")
            }
            .tag(AppNavigationView.preferences)
        }
        .modifier(CommonViewModifiers(selectedTabItem: self.$selectedTabItem))
        #endif
    }
}
