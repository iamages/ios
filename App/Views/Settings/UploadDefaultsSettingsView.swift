import SwiftUI

struct UploadDefaultsSettingsView: View {
    var body: some View {
        Toggle("Private", isOn: .constant(false))
        Toggle("Locked", isOn: .constant(false))
    }
}

#if DEBUG
struct UploadDefaultsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UploadDefaultsSettingsView()
    }
}
#endif
