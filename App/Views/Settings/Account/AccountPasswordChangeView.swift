import SwiftUI

struct AccountPasswordChangeView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @Binding var isBusy: Bool
    
    @State private var newPassword1: String = ""
    @State private var newPassword2: String = ""
    
    @State private var error: LocalizedAlertError?
    
    private func changePassword() async {
        do {
            // TODO: Change password.
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    var body: some View {
        Form {
            Section {
                SecureField("New password", text: self.$newPassword1)
                SecureField("New password, again", text: self.$newPassword2)
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
