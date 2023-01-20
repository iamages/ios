import SwiftUI

struct UploadEditorView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

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
                UploadOwnershipFooter(
                    isLoggedIn: self.globalViewModel.isLoggedIn,
                    isLocked: self.information.isLocked
                )
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
            information: .constant(previewUploadContainer.information)
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
