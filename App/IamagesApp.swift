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
            CommandGroup(replacing: .newItem) {
                Button("New images upload") {
                    #if os(macOS)
                    openWindow(id: "upload")
                    #else
                    self.viewModel.isUploadDetailVisible = true
                    #endif
                }
                .keyboardShortcut("n")

                Button("New images collection") {
                    #if os(macOS)
                    openWindow("newCollection")
                    #else
                    self.viewModel.isNewCollectionSheetVisible = true
                    #endif
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        
        #if os(macOS)
        WindowGroup(id: "upload") {
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
