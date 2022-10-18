import SwiftUI
import GRDB

@main
struct IamagesApp: App {
    @Environment(\.openWindow) var openWindow
    
    @StateObject var viewModel: ViewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(self.viewModel)
                .environment(\.dbQueue, try! DatabaseQueue()) // FIXME: Use local DbQueue.
        }
        .commands {
            #if os(iOS)
            CommandGroup(replacing: .appSettings) {
                Button("Settings") {
                    NotificationCenter.default.post(name: Notification.Name("openSettings"), object: nil)
                }
                .keyboardShortcut(",")
            }
            #endif
            CommandGroup(replacing: .newItem) {
                Button("New images upload") {
                    NotificationCenter.default.post(name: Notification.Name("openUploads"), object: nil)
                }
                .keyboardShortcut("n")

                Button("New images collection") {
                    #if os(macOS)
                    openWindow(id: "newCollection")
                    #else
                    self.viewModel.isNewCollectionSheetVisible = true
                    #endif
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        
        #if os(macOS)
        Window("Uploads", id: "uploads") {
            UploadView()
                .environmentObject(self.viewModel)
        }
        
        WindowGroup(id: "newCollection") {
            EmptyView()
        }

        Settings {
            SettingsView()
                .environmentObject(self.viewModel)
        }
        #endif
    }
}
