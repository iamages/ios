import SwiftUI

struct UploadInformationEditorView: View {
    @EnvironmentObject var globalViewModel: GlobalViewModel
    
    @Binding var information: IamagesUploadInformation
    
    var body: some View {
        Form {
            TextField("Description", text: self.$information.description)
            Toggle("Private", isOn: self.$information.isPrivate)
                .disabled(!self.globalViewModel.isLoggedIn)
            Section {
                Toggle("Lock image", isOn: self.$information.isLocked)
                    .onChange(of: self.information.isLocked) { isLocked in
                        if isLocked {
                            self.information.lockKey = ""
                        } else {
                            self.information.lockKey = nil
                        }
                    }
                if var lockKey: Binding<String> = Binding<String>(self.$information.lockKey) {
                    SecureField("Password", text: lockKey)
                }
            } header: {
                Text("Lock")
            } footer: {
                Text("Locked images are encrypted in the cloud using your provided password. These features will be disabled:\n· Thumbnail in images list\n· Social media embed cards.\n· Local image cache.\nYou will have to unlock locked images manually everytime you open the app. People who receive your public link also need a password to decrypt the image. You cannot reverse the encryption process.")
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
        .environmentObject(GlobalViewModel())
    }
}
#endif
