import SwiftUI

struct UploadDefaultsSettingsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @AppStorage("uploadDefaults.isPrivate", store: .iamagesGroup)
    private var isPrivate: Bool = false
    
    @AppStorage("uploadDefaults.isLocked", store: .iamagesGroup)
    private var isLocked: Bool = false
    
    
    var body: some View {
        Section {
            Toggle("Private", isOn: self.$isPrivate)
                .disabled(!self.globalViewModel.isLoggedIn)
            Toggle("Locked", isOn: self.$isLocked)
        } header: {
            Text("Defaults")
        } footer: {
            Text((!self.globalViewModel.isLoggedIn ? "You will need to log in to enable upload privatization.\n\n" : "") + (self.isLocked ? "You will need to provide a key for each individual upload." : ""))
        }
    }
}

#if DEBUG
struct UploadDefaultsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UploadDefaultsSettingsView()
            .environmentObject(GlobalViewModel())
    }
}
#endif
