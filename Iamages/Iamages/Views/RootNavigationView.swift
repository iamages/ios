import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var selectedTabItem: AppNavigationView
    
    @State var isFirstViewDone: Bool = false

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
        .onAppear {
            if !self.isFirstViewDone {
                if let titlebar = (UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene)?.titlebar {
                    titlebar.titleVisibility = .hidden
                }
                self.isFirstViewDone = true
            }
        }
        #endif
    }
}
