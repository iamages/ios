import SwiftUI
import WidgetKit

struct LoginSheetView: View {
    @EnvironmentObject var globalViewModel: GlobalViewModel

    @Binding var isPresented: Bool
    
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    
    @State private var error: LocalizedAlertError?
    
    @State private var isBusy: Bool = false
    
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
        self.isBusy = true
        do {
            try self.validateCredentials()
            try await self.globalViewModel.login(
                username: self.usernameInput,
                password: self.passwordInput
            )
            WidgetCenter.shared.reloadAllTimelines()
            self.isPresented = false
        } catch {
            print(error)
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func signup() async {
        self.isBusy = true
        do {
            try self.validateCredentials()
            try await self.globalViewModel.signup(
                username: self.usernameInput,
                password: self.passwordInput
            )
            throw LoginErrors.signupComplete
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
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
                .disabled(self.isBusy)
                Button("Sign up") {
                    Task {
                        await self.signup()
                    }
                }
                .disabled(self.isBusy)
            }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        self.isPresented = false
                    }
                    .disabled(self.isBusy)
                }
                ToolbarItem(placement: .status) {
                    if self.isBusy {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Authenticate")
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert(error: self.$error)

            Button("Forgot your password?", role: .destructive) {
                
            }
            .disabled(self.isBusy)
        }
    }
}

#if DEBUG
struct LoginSheetView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheetView(isPresented: .constant(true))
            .environmentObject(GlobalViewModel())
    }
}
#endif
