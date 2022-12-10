import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @State private var isDeleteAccountAlertPresented: Bool = false
    @State private var isLogoutConfirmationDialogPresented: Bool = false
    @State private var isLoginSheetPresented: Bool = false
    
    private func logout() {
        do {
            try self.globalViewModel.logout()
        } catch {
            
        }
    }

    var body: some View {
        Group {
            if let userInformation: IamagesUser = self.globalViewModel.userInformation {
                VStack(alignment: .leading) {
                    Text(userInformation.username)
                        .font(.title2)
                        .bold()
                    LabeledContent("Created on") {
                        Text(userInformation.createdOn, format: .dateTime)
                    }
                }
                Button("Change password") {
                    
                }
                Button("Delete account", role: .destructive) {
                    self.isDeleteAccountAlertPresented = true
                }
                Button("Log out") {
                    self.isLogoutConfirmationDialogPresented = true
                }
                .confirmationDialog(
                    "Log out?",
                    isPresented: self.$isLogoutConfirmationDialogPresented,
                    titleVisibility: .visible
                ) {
                    Button("Log out", role: .destructive, action: self.logout)
                } message: {
                    Text("You will need to sign in again to see your images and collections.")
                }
            } else {
                Button("Login/signup") {
                    self.isLoginSheetPresented = true
                }
            }
        }
        .sheet(isPresented: self.$isLoginSheetPresented) {
            LoginSheetView(isPresented: self.$isLoginSheetPresented)
        }
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView()
    }
}
