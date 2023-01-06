import SwiftUI
import GRDB
import Nuke

@main
struct IamagesApp: App {
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var globalViewModel: GlobalViewModel = GlobalViewModel()
    
    private func openSettings() {
        #if targetEnvironment(macCatalyst)
        if !self.globalViewModel.isSettingsPresented {
            openWindow(id: "settings")
        }
        #endif
        self.globalViewModel.isSettingsPresented = true
    }
    
    var body: some Scene {
        WindowGroup(id: "main") {
            RootNavigationView()
                .environmentObject(self.globalViewModel)
                .environment(\.dbQueue, try! DatabaseQueue()) // FIXME: Use local DbQueue.
        }
        .commands {
            #if targetEnvironment(macCatalyst)
            CommandGroup(replacing: .appInfo) {
                Button("About Iamages") {
                    self.globalViewModel.selectedSettingsView = .about
                    self.openSettings()
                }
                .disabled(self.globalViewModel.selectedSettingsView == .about)
            }
            #endif
            CommandGroup(replacing: .appSettings) {
                Button("Settings...", action: self.openSettings)
                    .keyboardShortcut(",")
                    .disabled(self.globalViewModel.isSettingsPresented)
            }
            CommandGroup(replacing: .newItem) {
                Button("New images upload...") {
                    #if targetEnvironment(macCatalyst)
                    openWindow(id: "uploads")
                    #else
                    self.globalViewModel.isUploadsPresented = true
                    #endif
                }
                .keyboardShortcut("n")
                #if !targetEnvironment(macCatalyst)
                .disabled(self.globalViewModel.isUploadsPresented)
                #endif

                Button("New images collection...") {
                    #if targetEnvironment(macCatalyst)
                    openWindow(id: "newCollection")
                    #else
                    self.globalViewModel.isNewCollectionPresented = true
                    #endif
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                #if targetEnvironment(macCatalyst)
                .disabled(!self.globalViewModel.isLoggedIn)
                #else
                .disabled(self.globalViewModel.isNewCollectionPresented || !self.globalViewModel.isLoggedIn)
                #endif

                if self.supportsMultipleWindows {
                    Divider()
                    Button("New window") {
                        openWindow(id: "main")
                    }
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                }
            }
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
                }
        }
        
        WindowGroup("Uploads", id: "uploads") {
            UploadsView()
                .hideMacTitlebar()
                .environmentObject(self.globalViewModel)
        }
        
        WindowGroup("New collection", id: "newCollection") {
            NewCollectionView()
                .hideMacTitlebar()
                .environmentObject(self.globalViewModel)
                .withHostingWindow { window in
                    let size: CGSize = CGSize(width: 400, height: 350)
                    window?.windowScene?.sizeRestrictions?.minimumSize = size
                    window?.windowScene?.sizeRestrictions?.maximumSize = size
                }
        }
        #endif
    }
}
