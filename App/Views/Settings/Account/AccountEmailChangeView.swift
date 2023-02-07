import SwiftUI

struct AccountEmailChangeView: View {
    private enum Field {
        case newEmail
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isBusy: Bool
    
    @FocusState private var focusedField: Field?
    
    @State private var newEmail: String = ""
    var isEmailValid: Bool {
        return self.newEmail.isEmail()
    }
    
    @State private var isRemoveEmailAlertPresented: Bool = false

    @State private var error: LocalizedAlertError?
    
    private func changeEmail() async {
        self.isBusy = true
        
        do {
            try await self.globalViewModel.editUserInformation(
                using: IamagesUserEdit(change: .email, to: self.newEmail)
            )
            self.isBusy = false
            self.dismiss()
        } catch {
            self.isBusy = false
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func removeEmail() async {
        self.isBusy = true
        
        do {
            try await self.globalViewModel.editUserInformation(
                using: IamagesUserEdit(change: .email, to: nil)
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
                LabeledContent("Current email", value: self.globalViewModel.userInformation?.email ?? "None")
                LabeledContent("New email") {
                    TextField("Email", text: self.$newEmail)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)
                        .focused(self.$focusedField, equals: .newEmail)
                }
                Button("Change email") {
                    Task {
                        await self.changeEmail()
                    }
                }
                .disabled(self.isBusy || !self.isEmailValid)
            }
            if self.globalViewModel.userInformation?.email != nil {
                Section {
                    Button("Remove email", role: .destructive) {
                        self.isRemoveEmailAlertPresented = true
                    }
                    .confirmationDialog(
                        "Remove email?",
                        isPresented: self.$isRemoveEmailAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Remove", role: .destructive) {
                            Task {
                                await self.removeEmail()
                            }
                        }
                    } message: {
                        Text("Without an email, you will not be able to reset your password.")
                    }
                }
            }
        }
        .navigationTitle("Change email")
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(error: self.$error)
        .navigationBarBackButtonHidden(self.isBusy)
        .onAppear {
            self.focusedField = .newEmail
        }
        .onDisappear {
            self.isBusy = false
        }
    }
}

struct AccountEmailChangeView_Previews: PreviewProvider {
    static var previews: some View {
        AccountEmailChangeView(isBusy: .constant(false))
            .environmentObject(GlobalViewModel())
    }
}
