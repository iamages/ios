import SwiftUI
import WidgetKit
import Nuke

struct MaintainanceSettingsView: View {
    @AppStorage("hasPresentedWelcome") private var hasPresentedWelcome: Bool = false
    
    private func clearNukeCache() {
        ImagePipeline.shared.cache.removeAll()
    }
    
    private func forgetEverything() {
        self.clearNukeCache()
    }
    
    var body: some View {
        Section {
            Button("Force widget refresh") {
                WidgetCenter.shared.reloadAllTimelines()
            }
            Button("Clear image cache", action: self.clearNukeCache)
            Button("Show welcome sheet on next launch") {
                self.hasPresentedWelcome = false
            }
            .disabled(!self.hasPresentedWelcome)
        } header: {
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
