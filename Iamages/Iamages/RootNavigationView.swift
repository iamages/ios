import SwiftUI

enum NavigationViews: Hashable {
    case feed
    case search
    case upload
    case you
    case preferences
}

struct RootNavigationView: View {
    @Binding var isPreferencesSheetPresented: Bool
    @Binding var isAboutSheetPresented: Bool

    @State var selectedNavigationItem: NavigationViews? = .feed
    @State var selectedTabItem: NavigationViews = .feed
    
    var sidebar: some View {
        NavigationView {
            List {
                NavigationLink(destination: FeedView(), tag: NavigationViews.feed, selection: self.$selectedNavigationItem) {
                    Label("Feed", systemImage: "newspaper")
                }
                NavigationLink(destination: SearchView(), tag: NavigationViews.search, selection: self.$selectedNavigationItem) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                NavigationLink(destination: UploadView(), tag: NavigationViews.upload, selection: self.$selectedNavigationItem) {
                    Label("Upload", systemImage: "square.and.arrow.up.on.square")
                }
                NavigationLink(destination: YouView(), tag: NavigationViews.you, selection: self.$selectedNavigationItem) {
                    Label("You", systemImage: "person")
                }
            }.listStyle(.sidebar)
            .navigationTitle("Iamages")
            EmptyView()
            EmptyView()
        }
    }
    
    var tabbar: some View {
        TabView(selection: self.$selectedTabItem) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }.tag(NavigationViews.feed)
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }.tag(NavigationViews.search)
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "square.and.arrow.up.on.square")
                }.tag(NavigationViews.upload)
            YouView()
                .tabItem {
                    Label("You", systemImage: "person")
                }.tag(NavigationViews.you)
            PreferencesView(isPreferencesSheetPresented: self.$isPreferencesSheetPresented)
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }.tag(NavigationViews.preferences)
        }.onChange(of: self.isPreferencesSheetPresented) { newValue in
            if newValue {
                self.selectedTabItem = .preferences
            }
        }
    }

    var body: some View {
        #if targetEnvironment(macCatalyst)
        sidebar
            .sheet(isPresented: self.$isPreferencesSheetPresented) {
                PreferencesView(isPreferencesSheetPresented: self.$isPreferencesSheetPresented)
            }
            #if targetEnvironment(macCatalyst)
            .sheet(isPresented: self.$isAboutSheetPresented) {
                AboutView(isAboutSheetPresented: self.$isAboutSheetPresented)
            }
            #endif
        #else
        tabbar
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView(isPreferencesSheetPresented: .constant(false), isAboutSheetPresented: .constant(false))
    }
}
