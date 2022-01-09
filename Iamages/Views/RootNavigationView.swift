import SwiftUI

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
            .tabItem {
                Label("Preferences", systemImage: "gearshape")
            }
            .tag(AppNavigationView.preferences)
        }
        #endif
    }
}
