import SwiftUI

enum AppNavigationView: Int {
    case feed = 1
    case search = 2
    case upload = 3
    case you = 4
    #if !targetEnvironment(macCatalyst)
    case preferences = 5
    #endif
}

@main
struct IamagesApp: App {
    @StateObject var dataObservable: APIDataObservable = APIDataObservable()

    #if targetEnvironment(macCatalyst)
    @State var selectedTabItem: AppNavigationView? = .feed
    @State var isPreferencesSheetPresented: Bool = false
    #else
    @State var selectedTabItem: AppNavigationView = .feed
    #endif
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView(selectedTabItem: self.$selectedTabItem)
                .environmentObject(self.dataObservable)
            #if targetEnvironment(macCatalyst)
                .sheet(isPresented: self.$isPreferencesSheetPresented, onDismiss: {
                    self.dataObservable.isModalPresented = false
                }) {
                    NavigationView {
                        PreferencesView()
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(action: {
                                        self.isPreferencesSheetPresented = false
                                    }) {
                                        Label("Close", systemImage: "xmark")
                                    }
                                    .keyboardShortcut(.cancelAction)
                                }
                            }
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            #endif
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                #if targetEnvironment(macCatalyst)
                Button("Preferences...") {
                    self.isPreferencesSheetPresented = true
                    self.dataObservable.isModalPresented = true
                }
                .keyboardShortcut(",")
                .disabled(self.dataObservable.isModalPresented)
                #else
                Button("Preferences") {
                    self.selectedTabItem = .preferences
                }
                .keyboardShortcut(",")
                .disabled(self.dataObservable.isModalPresented)
                #endif
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
            #if targetEnvironment(macCatalyst)
            CommandGroup(replacing: .help) {
                HelpLinksView()
                    .environmentObject(self.dataObservable)
            }
            #endif
        }
    }
}