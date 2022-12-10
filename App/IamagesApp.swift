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
                    if !self.globalViewModel.isUploadsPresented {
                        openWindow(id: "uploads")
                    }
                    #endif
                    self.globalViewModel.isUploadsPresented = true
                }
                .keyboardShortcut("n")
                .disabled(self.globalViewModel.isUploadsPresented)

                Button("New images collection...") {
                    
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
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
            UploadView()
                .hideMacTitlebar()
                .environmentObject(self.globalViewModel)
                .onDisappear {
                    self.globalViewModel.isUploadsPresented = false
                }
        }
        #endif
    }
}
