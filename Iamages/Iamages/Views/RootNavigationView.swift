import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var selectedTabItem: NavigationViews

    var body: some View {
        TabView(selection: self.$selectedTabItem) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }
                .tag(NavigationViews.feed)
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(NavigationViews.search)
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "square.and.arrow.up.on.square")
                }
                .tag(NavigationViews.upload)
            YouView()
                .tabItem {
                    Label("You", systemImage: "person")
                }
                .tag(NavigationViews.you)
            PreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }
                .tag(NavigationViews.preferences)
        }
    }
}
