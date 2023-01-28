import SwiftUI

struct AccountPasswordChangeView: View {
    enum Field {
        case newPassword1
        case newPassword2
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isBusy: Bool
    
    @State private var newPassword1: String = ""
    @State private var newPassword2: String = ""
    @FocusState private var focusedField: Field?
    
    @State private var error: LocalizedAlertError?
    
    private func changePassword() async {
        self.isBusy = true
        do {
            if self.newPassword1 != self.newPassword2 {
                throw PasswordMismatchError()
            }
            try self.globalViewModel.validateCredentials(password: self.newPassword1)
            try await self.globalViewModel.editUserInformation(
                using: IamagesUserEdit(change: .password, to: self.newPassword1)
            )
            self.isBusy = false
            self.dismiss()
        } catch {
            self.isBusy = false
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    var body: some View {
        Form {
            Section {
                SecureField("New password", text: self.$newPassword1)
                    .focused(self.$focusedField, equals: .newPassword1)
                SecureField("New password, again", text: self.$newPassword2)
                    .focused(self.$focusedField, equals: .newPassword2)
                Button("Change password", role: .destructive) {
                    Task {
                        await self.changePassword()
                    }
                }
            } footer: {
                Text("Other devices will need to log in again.")
            }
        }
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(error: self.$error)
        .navigationBarBackButtonHidden(self.isBusy)
        .onAppear {
            self.focusedField = .newPassword1
        }
    }
}

#if DEBUG
struct AccountPasswordChangeView_Previews: PreviewProvider {
    static var previews: some View {
        AccountPasswordChangeView(isBusy: .constant(false))
            .environmentObject(GlobalViewModel())
    }
}
#endif
