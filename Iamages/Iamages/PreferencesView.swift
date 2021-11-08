import SwiftUI

struct PreferencesView: View {
    @Binding var isPreferencesSheetPresented: Bool
    
    @AppStorage("isNSFWEnabled") var isNSFWEnabled: Bool = true
    @AppStorage("isNSFWBlurred") var isNSFWBlurred: Bool = true
    
    @State var isResetWarningAlertPresented: Bool = false
    
    var appSettings: some View {
        Group {
            Toggle(isOn: self.$isNSFWEnabled) {
                #if targetEnvironment(macCatalyst)
                Text("Enable NSFW viewing")
                #else
                Label("Enable NSFW viewing", systemImage: "18.circle")
                #endif
            }
            Toggle(isOn: self.$isNSFWBlurred) {
                #if targetEnvironment(macCatalyst)
                Text("Blur NSFW Content")
                #else
                Label("Blur NSFW content", systemImage: "eye.slash")
                #endif
            }.disabled(!self.isNSFWEnabled)
        }
    }
    
    var maintenance: some View {
        Group {
            Button(action: self.clearImageCache) {
                Label("Clear image cache", systemImage: "trash")
            }
            Button(role: .destructive, action: {
                self.isResetWarningAlertPresented = true
            }) {
                Label("Reset app settings", systemImage: "arrow.uturn.backward")
            }
            .alert("This will reset all your settings to default. Continue?", isPresented: self.$isResetWarningAlertPresented) {
                Button(role: .destructive, action: self.resetAppSettings) {
                    Text("Reset all settings")
                }
            }
        }
        #if targetEnvironment(macCatalyst)
        .buttonStyle(.borderedProminent)
        #endif
    }

    var body: some View {
        NavigationView {
            Form {
                #if targetEnvironment(macCatalyst)
                HStack(alignment: .top) {
                    Text("App settings:")
                    VStack(alignment: .leading) {
                        self.appSettings
                    }
                }
                #else
                Section("App settings") {
                    self.appSettings
                }
                #endif

                #if targetEnvironment(macCatalyst)
                HStack(alignment: .top) {
                    Text("Maintenance:")
                    VStack(alignment: .leading) {
                        self.maintenance
                    }
                }
                #else
                Section("Maintenance") {
                    self.maintenance
                }
                #endif

                #if !targetEnvironment(macCatalyst)
                Section(header: Text("About + links"), footer: Text("Iamages iOS \(Bundle.main.version)")) {
                    HelpLinksView()
                }
                #endif
            }.navigationTitle("Preferences")
            #if targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isPreferencesSheetPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
            #endif
        }.navigationViewStyle(.stack)
        .onDisappear {
            self.isPreferencesSheetPresented = false
        }
    }
    
    func clearImageCache() {
        
    }
    
    func resetAppSettings() {
        self.isNSFWEnabled = true
        self.isNSFWBlurred = true
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(isPreferencesSheetPresented: .constant(false))
    }
}
