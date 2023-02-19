import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    
    @Binding var isBusy: Bool

    @State private var isDeleteAccountAlertPresented: Bool = false
    @State private var isLogoutConfirmationDialogPresented: Bool = false
    @State private var isLoginSheetPresented: Bool = false
    
    @State private var error: LocalizedAlertError?
    
    private func deleteUser() async {
        self.isBusy = true
        do {
            try await self.globalViewModel.deleteUser()
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func logout() {
        do {
            try self.globalViewModel.logout()
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func refreshUserInformation() async {
        do {
            try await self.globalViewModel.getUserInformation()
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }

    var body: some View {
        Group {
            if let userInformation: IamagesUser = self.globalViewModel.userInformation {
                Section("Information") {
                    VStack(alignment: .leading) {
                        Text(userInformation.username)
                            .font(.title2)
                            .bold()
                        LabeledContent("Created on") {
                            Text(userInformation.createdOn, format: .dateTime)
                        }
                    }
                    NavigationLink {
                        AccountEmailChangeView(isBusy: self.$isBusy)
                    } label: {
                        LabeledContent("Email", value: userInformation.email ?? "Set new...")
                    }
                    .toolbar {
                        ToolbarItem {
                            if self.globalViewModel.isLoggedIn {
                                Button("Refresh") {
                                    Task {
                                        await self.refreshUserInformation()
                                    }
                                }
                                .disabled(self.isBusy)
                            }
                        }
                    }
                }
                
                Section("Authentication") {
                    LabeledContent("Mode", value: "Password")
                    NavigationLink("Change password") {
                        AccountPasswordChangeView(isBusy: self.$isBusy)
                    }
                }

                Section("Caution") {
                    Button("Delete account", role: .destructive) {
                        self.isDeleteAccountAlertPresented = true
                    }
                    .disabled(self.isBusy)
                    .confirmationDialog(
                        "Delete user?",
                        isPresented: self.$isDeleteAccountAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await self.deleteUser()
                            }
                        }
                    } message: {
                        Text("Everything, from your images and collections, will be wiped, forever! Make sure you have already backed up your data before continuing!")
                    }
                    Button("Log out") {
                        self.isLogoutConfirmationDialogPresented = true
                    }
                    .disabled(self.isBusy)
                    .confirmationDialog(
                        "Log out?",
                        isPresented: self.$isLogoutConfirmationDialogPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Log out", role: .destructive, action: self.logout)
                    } message: {
                        Text("You will need to sign in again to see your images and collections.")
                    }
                }
            } else {
                Button("Login/signup") {
                    self.isLoginSheetPresented = true
                }
            }
        }
        .errorAlert(error: self.$error)
        .sheet(isPresented: self.$isLoginSheetPresented) {
            LoginSheetView()
        }
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView(isBusy: .constant(false))
    }
}
