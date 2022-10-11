import SwiftUI

struct LoginSheetView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @Binding var isPresented: Bool
    
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    
    @State private var error: LocalizedAlertError?
    
    private func validateCredentials() throws {
        if usernameInput.firstMatch(of: try Regex("[\\s]")) != nil ||
           usernameInput.count < 3 {
            throw LoginErrors.invalidUsername
        }
        if passwordInput.count < 6 {
            throw LoginErrors.invalidPassword
        }
    }
    
    private func login() async {
        do {
            try self.validateCredentials()
            try await self.viewModel.login(
                username: self.usernameInput,
                password: self.passwordInput
            )
            self.isPresented = false
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    private func signup() async {
        do {
            try self.validateCredentials()
            try await self.viewModel.signup(
                username: self.usernameInput,
                password: self.passwordInput
            )
            throw LoginErrors.signupComplete
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Username", text: self.$usernameInput)
                SecureField("Password", text: self.$passwordInput)
                Button("Login") {
                    Task {
                        await self.login()
                    }
                }
                
                Button("Sign up") {
                    Task {
                        await self.signup()
                    }
                }
            }
            .toolbar {
                Button(action: {
                    self.isPresented = false
                }) {
                    Text("Cancel")
                }
            }
            .navigationTitle("Authenticate")
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert(error: self.$error)
        }
    }
}

#if DEBUG
struct LoginSheetView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheetView(isPresented: .constant(true))
            .environmentObject(ViewModel())
    }
}
#endif
