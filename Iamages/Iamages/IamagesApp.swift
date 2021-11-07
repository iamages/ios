import SwiftUI

@main
struct IamagesApp: App {
    @StateObject var dataObservable: APIDataObservable = APIDataObservable()
    
    @State var isSettingsSheetPresented: Bool = false
    @State var isAboutSheetPresented: Bool = false
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView(isPreferencesSheetPresented: self.$isSettingsSheetPresented, isAboutSheetPresented: self.$isAboutSheetPresented).environmentObject(self.dataObservable)
        }.commands {
            CommandGroup(replacing: .appSettings) {
                Button(action: {
                    self.isSettingsSheetPresented = true
                }) {
                    Text("Preferences")
                }.keyboardShortcut(",")
            }
            #if targetEnvironment(macCatalyst)
            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    self.isAboutSheetPresented = true
                }) {
                    Text("About Iamages")
                }
            }
            #endif
        }
    }
}
