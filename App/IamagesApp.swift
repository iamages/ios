import SwiftUI
import AlertToast

// Thanks to:
// https://swiftwombat.com/how-to-add-home-screen-quick-actions-to-swiftui-app/
final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    var shortcutItem: UIApplicationShortcutItem? { AppDelegate.shortcutItem }
        
    static var shortcutItem: UIApplicationShortcutItem?

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            AppDelegate.shortcutItem = shortcutItem
        }
        
        let sceneConfiguration = UISceneConfiguration(name: "IamagesQuickActions", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        
        return sceneConfiguration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        AppDelegate.shortcutItem = shortcutItem
        completionHandler(true)
    }
}

@main
struct IamagesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var globalViewModel: GlobalViewModel = GlobalViewModel()
    @StateObject private var coreDataModel = CoreDataModel()
    
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
                .environment(\.managedObjectContext, self.coreDataModel.container.viewContext)
                .environmentObject(self.globalViewModel)
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
