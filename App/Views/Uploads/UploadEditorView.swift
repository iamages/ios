import SwiftUI

struct UploadEditorView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

    let id: UUID
    @Binding var information: IamagesUploadInformation

    @State private var isLockWarningAlertPresented: Bool = false

    var body: some View {
        Form {
            TextField("Description", text: self.$information.description)
            Section {
                Toggle("Private", isOn: self.$information.isPrivate)
                    .disabled(!self.globalViewModel.isLoggedIn)
                Toggle("Lock", isOn: self.$information.isLocked)
                    .onChange(of: self.information.isLocked) { _ in
                        self.information.lockKey = ""
                    }
                if self.information.isLocked {
                    SecureField("Password", text: self.$information.lockKey)
                }
            } header: {
                Text("Ownership")
            } footer: {
                if self.information.isLocked {
                    Text("Locked images are encrypted in the cloud using your provided password. These features will be disabled:\n· Thumbnail in images list\n· Social media embed cards.\n· Local image cache.\nYou will have to unlock locked images manually everytime you open the app. People who receive your public link also need a password to decrypt the image.")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Editor")
        .lockBetaWarningAlert(
            isLocked: self.$information.isLocked,
            isPresented: self.$isLockWarningAlertPresented
        )
    }
}

#if DEBUG
struct UploadEditorView_Previews: PreviewProvider {
    static var previews: some View {
        UploadEditorView(
            id: UUID(),
            information: .constant(previewUploadContainer.information)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
