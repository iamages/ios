import SwiftUI
import StoreKit
import SPConfetti
import Kingfisher

struct PreferencesView: View {
    @AppStorage("isNSFWEnabled") var isNSFWEnabled: Bool = true
    @AppStorage("isNSFWBlurred") var isNSFWBlurred: Bool = true
    
    @AppStorage("uploadDefaults.isNSFW") var isNSFWDefault: Bool = false
    @AppStorage("uploadDefaults.isHidden") var isHiddenDefault: Bool = false
    @AppStorage("uploadDefaults.isPrivate") var isPrivateDefault: Bool = false
    
    @State var isClearCacheAlertPresented: Bool = false
    @State var isResetWarningAlertPresented: Bool = false
    
    @State var isCacheBeingCleared: Bool = false
    
    @State var isTipConfettiPresented: Bool = false
    
    func clearImageCache () {
        self.isCacheBeingCleared = true
        KingfisherManager.shared.cache.clearCache {
            self.isCacheBeingCleared = false
        }
    }
    
    func resetAppSettings () {
        self.isNSFWEnabled = true
        self.isNSFWBlurred = true
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Viewing") {
                    Toggle("Enable NSFW viewing", isOn: self.$isNSFWEnabled)
                    Toggle("Blur NSFW Content", isOn: self.$isNSFWBlurred)
                        .disabled(!self.isNSFWEnabled)
                }
                Section {
                    Toggle(isOn: self.$isNSFWDefault) {
                        Text("NSFW (18+)")
                    }
                    Toggle(isOn: self.$isHiddenDefault) {
                        Text("Hidden")
                    }
                    Toggle(isOn: self.$isPrivateDefault) {
                        Text("Private")
                    }
                } header: {
                    Text("Upload defaults")
                } footer: {
                    Text("These preferences will be applied to every new upload created after the changes were made.")
                }
                Section("Maintenance") {
                    Button("Clear image cache") {
                        self.isClearCacheAlertPresented = true
                    }
                    .confirmationDialog(
                        "The image cache will be cleared and images will need to be reloaded.",
                        isPresented: self.$isClearCacheAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Clear image cache", role: .destructive, action: self.clearImageCache)
                    }
                    .disabled(self.isCacheBeingCleared)
                    Button("Reset app settings", role: .destructive) {
                        self.isResetWarningAlertPresented = true
                    }
                    .confirmationDialog(
                        "This will reset all your preferences to default.",
                        isPresented: self.$isResetWarningAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Reset all preferences", role: .destructive, action: self.resetAppSettings)
                    }
                }
                Section(content: {
                    Button("Small tip ($2)") {
                        self.isTipConfettiPresented = true
                    }
                    Button("Medium tip ($5)") {
                        self.isTipConfettiPresented = true
                    }
                    Button("Large tip ($10)") {
                        self.isTipConfettiPresented = true
                    }
                }, header: {
                    Text("Tip Jar")
                }, footer: {
                    Text("Your support helps us maintain Iamages for you and many others! Thank you!\n\nEvery:\n- **Small tip** can keep our servers running for 1 month, courtesy of Uberspace.\n- **Medium tip** will keep our developers fed and motivated to create new features.\n- **Large tip** will help us afford devices to test our apps on.")
                })
                #if !targetEnvironment(macCatalyst)
                Section(content: {
                    HelpLinksView()
                }, header: {
                    Text("About + links")
                }, footer: {
                    Text("Iamages iOS \(Bundle.main.version) (\(Bundle.main.build))")
                })
                #endif
            }
            .navigationTitle("Preferences")
        }
        .navigationViewStyle(.stack)
        .confetti(
            isPresented: self.$isTipConfettiPresented,
            animation: .fullWidthToDown,
            particles: [.heart, .star],
            duration: 3
        )
        .confettiParticle(\.velocity, 600)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
