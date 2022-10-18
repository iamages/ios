import SwiftUI

struct UploadInformationEditorView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @Binding var information: IamagesUploadInformation
    
    var body: some View {
        Form {
            TextField("Description", text: self.$information.description)
            Toggle("Private", isOn: self.$information.isPrivate)
            Section {
                Toggle("Lock image", isOn: self.$information.isLocked)
                SecureField("Password", text: self.$information.lockKey)
                    .disabled(!self.information.isLocked)
            } header: {
                Text("Lock")
            } footer: {
                Text("Locked files are encrypted in the cloud using your provided password. They have to be manually unlocked everytime you open the app.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Editor")
    }
}

#if DEBUG
struct UploadInformationEditorView_Previews: PreviewProvider {
    static var previews: some View {
        UploadInformationEditorView(
            information: .constant(IamagesUploadInformation())
        )
        .environmentObject(ViewModel())
    }
}
#endif
