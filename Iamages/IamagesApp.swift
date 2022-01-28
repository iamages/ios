import SwiftUI

enum AppNavigationView: Int {
    case feed = 1
    case search = 2
    case upload = 3
    case you = 4
    case preferences = 5
}

@main
struct IamagesApp: App {
    @StateObject var dataObservable: APIDataObservable = APIDataObservable()

    @State var selectedTabItem: AppNavigationView = .feed
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView(selectedTabItem: self.$selectedTabItem)
                .environmentObject(self.dataObservable)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    self.selectedTabItem = .preferences
                }
                .keyboardShortcut(",")
            }
            CommandGroup(after: .toolbar) {
                Divider()
                Button("Feed") {
                    self.selectedTabItem = .feed
                }
                .keyboardShortcut("1")
                Button("Search") {
                    self.selectedTabItem = .search
                }
                .keyboardShortcut("2")
                Button("Upload") {
                    self.selectedTabItem = .upload
                }
                .keyboardShortcut("3")
                Button("You") {
                    self.selectedTabItem = .you
                }
                .keyboardShortcut("4")
            }
            CommandGroup(replacing: .textFormatting) {}
            #if targetEnvironment(macCatalyst)
            CommandGroup(replacing: .help) {
                HelpLinksView()
                    .environmentObject(self.dataObservable)
            }
            #endif
        }
    }
}
