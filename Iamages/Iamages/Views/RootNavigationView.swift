import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var selectedTabItem: AppNavigationView

    var body: some View {
        TabView(selection: self.$selectedTabItem) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }
                .tag(AppNavigationView.feed)
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppNavigationView.search)
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "square.and.arrow.up.on.square")
                }
                .tag(AppNavigationView.upload)
            YouView()
                .tabItem {
                    Label("You", systemImage: "person")
                }
                .tag(AppNavigationView.you)
            PreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }
                .tag(AppNavigationView.preferences)
        }
        // Disabling window titlebar in Calalyst.
        #if targetEnvironment(macCatalyst)
        .withHostingWindow { window in
            if let titlebar = window?.windowScene?.titlebar {
                titlebar.titleVisibility = .hidden
            }
        }
        #endif
    }
}
