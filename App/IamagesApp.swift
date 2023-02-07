import SwiftUI

@main
struct IamagesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var globalViewModel: GlobalViewModel = GlobalViewModel()
    @StateObject private var coreDataModel = CoreDataModel()
    
    var body: some Scene {
        WindowGroup(id: "main") {
            RootNavigationView()
                .environment(\.managedObjectContext, self.coreDataModel.container.viewContext)
                .environmentObject(self.globalViewModel)
        }
        .commands {
            AppSettingsCommands(globalViewModel: self.globalViewModel)
            NewItemCommands(globalViewModel: self.globalViewModel)
            // SelectedViewCommands() FIXME: focusedSceneBinding not working properly.
            CommandGroup(replacing: .help) {
                AboutLinksView()
                    .environmentObject(self.globalViewModel)
            }
        }
        
        #if targetEnvironment(macCatalyst)
        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .hideMacTitlebar()
                .environmentObject(self.globalViewModel)
                .onDisappear {
                    self.globalViewModel.isSettingsPresented = false
                }
                .withHostingWindow { window in
                    let size: CGSize = CGSize(width: 900, height: 700)
                    window?.windowScene?.sizeRestrictions?.minimumSize = size
                    window?.windowScene?.sizeRestrictions?.maximumSize = size
                    window?.windowScene?.sizeRestrictions?.allowsFullScreen = false
                    window?.windowScene?.windowingBehaviors?.isMiniaturizable = false
                }
        }
        
        WindowGroup("Uploads", id: "uploads") {
            UploadsView()
                .hideMacTitlebar()
                .environmentObject(self.globalViewModel)
                .environment(\.managedObjectContext, self.coreDataModel.container.viewContext)
        }
        
        WindowGroup("New collection", id: "newCollection") {
            NewCollectionView()
                .hideMacTitlebar()
                .environmentObject(self.globalViewModel)
                .withHostingWindow { window in
                    let size: CGSize = CGSize(width: 400, height: 350)
                    window?.windowScene?.sizeRestrictions?.minimumSize = size
                    window?.windowScene?.sizeRestrictions?.maximumSize = size
                    window?.windowScene?.sizeRestrictions?.allowsFullScreen = false
                    window?.windowScene?.windowingBehaviors?.isMiniaturizable = false
                }
        }
        #endif
    }
}
