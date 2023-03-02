import SwiftUI
import WidgetKit
import Nuke

struct MaintainanceSettingsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

    @AppStorage("hasPresentedWelcome") private var hasPresentedWelcome: Bool = false
    
    @State private var isForgetAlertPresented = false
    
    private func clearNukeCache() {
        ImagePipeline.shared.cache.removeAll()
    }
    
    private func forgetEverything() {
        self.clearNukeCache()
        UserDefaults.standard.removePersistentDomain(forName: "me.jkelol111.Iamages")
        UserDefaults.standard.removePersistentDomain(forName: "group.me.jkelol111.Iamages")
        UserDefaults.standard.synchronize()
        try? self.globalViewModel.logout()
    }
    
    var body: some View {
        Section("Non-destructive") {
            Button("Force widget refresh") {
                WidgetCenter.shared.reloadAllTimelines()
            }
            Button("Show welcome sheet on next launch") {
                self.hasPresentedWelcome = false
            }
            .disabled(!self.hasPresentedWelcome)
        }
        Section {
            Button("Clear image cache", role: .destructive, action: self.clearNukeCache)
            Button("Forget everything", role: .destructive) {
                self.isForgetAlertPresented = true
            }
            .confirmationDialog("Forget everything?", isPresented: self.$isForgetAlertPresented, titleVisibility: .visible) {
                Button("Forget", role: .destructive, action: self.forgetEverything)
            } message: {
                Text("Everything will be reset to defaults!\nYou will have to log in again.")
            }
        } header: {
            Text("Destructive")
        } footer: {
            Text("Use these options only if something seems off, Iamages can take care of itself!")
        }
    }
}

struct MaintainanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MaintainanceSettingsView()
    }
}
