import SwiftUI

struct AppSettingsCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    @ObservedObject var globalViewModel: GlobalViewModel

    private func openSettings() {
        #if targetEnvironment(macCatalyst)
        if !self.globalViewModel.isSettingsPresented {
            self.openWindow(id: "settings")
        }
        #endif
        self.globalViewModel.isSettingsPresented = true
    }

    var body: some Commands {
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
    }
}

struct NewItemCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    @ObservedObject var globalViewModel: GlobalViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            #if targetEnvironment(macCatalyst)
            Menu("New") {
                Button("Uploads") {
                    self.openWindow(id: "uploads")
                }
                .keyboardShortcut("n")
                
                Button("Collection") {
                    self.openWindow(id: "newCollection")
                }
                .keyboardShortcut("n", modifiers: [.shift, .command])
                Divider()
                Button("Window") {
                    self.openWindow(id: "main")
                }
                .keyboardShortcut("t", modifiers: [.shift, .command])
            }
            #else
            Button("New images upload...") {
                self.globalViewModel.isUploadsPresented = true
            }
            .keyboardShortcut("n")
            .disabled(self.globalViewModel.isNewCollectionPresented)
            
            Button("New images collection...") {
                self.globalViewModel.isNewCollectionPresented = true
            }
            .keyboardShortcut("n", modifiers: [.shift, .command])
            .disabled(!self.globalViewModel.isLoggedIn || self.globalViewModel.isUploadsPresented)
            #endif
        }
    }
}

struct SelectedViewCommands: Commands {
    @FocusedObject private var splitViewModel: SplitViewModel?

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Divider()
            ForEach(Array(zip(AppUserViews.allCases.indices, AppUserViews.allCases)), id: \.1) { i, view in
                Button(view.localizedName) {
                    withAnimation {
                        self.splitViewModel?.selectedView = view
                    }
                }
                .keyboardShortcut(.init(Character(String(i + 1))))
            }
        }
    }
}

