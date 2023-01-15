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

    @State private var error: LocalizedAlertError?
    
    private func changeEmail() async {
        self.isBusy = true
        
        do {
            self.dismiss()
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    var body: some View {
        Form {
            LabeledContent("Current email", value: self.globalViewModel.userInformation?.email ?? "None")
            LabeledContent("New email") {
                TextField("Email", text: self.$newEmail)
                    .multilineTextAlignment(.trailing)
                    .focused(self.$focusedField, equals: .newEmail)
            }
            Button("Change email") {
                Task {
                    await self.changeEmail()
                }
            }
            .disabled(self.isBusy || !self.isEmailValid)
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
