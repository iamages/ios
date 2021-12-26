import SwiftUI

enum NavigationViews: Hashable {
    case feed
    case search
    case upload
    case you
    case preferences
}

@main
struct IamagesApp: App {
    @StateObject var dataObservable: APIDataObservable = APIDataObservable()
    
    @State var selectedTabItem: NavigationViews = .feed
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView(selectedTabItem: self.$selectedTabItem)
                .environmentObject(self.dataObservable)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(action: {
                    self.selectedTabItem = .preferences
                }) {
                    Text("Preferences")
                }
                .keyboardShortcut(",")
            }
        }
    }
}
