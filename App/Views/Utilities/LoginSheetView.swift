import SwiftUI
import WidgetKit

struct LoginSheetView: View {
    enum Field {
        case username
        case password
        case email
    }
    
    @EnvironmentObject var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var emailInput: String = ""
    @State private var isSigningUp: Bool = false
    @FocusState private var focusedField: Field?
    
    @State private var isPasswordResetSheetPresented: Bool = false
    
    @State private var error: LocalizedAlertError?
    
    @State private var isBusy: Bool = false
    
    private func login() async {
        self.isBusy = true
        do {
            try self.globalViewModel.validateCredentials(
                username: self.usernameInput,
                password: self.passwordInput
            )
            try await self.globalViewModel.login(
                username: self.usernameInput,
                password: self.passwordInput
            )
            WidgetCenter.shared.reloadAllTimelines()
            self.dismiss()
        } catch {
            print(error)
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func signup() async {
        self.isBusy = true
        do {
            try self.globalViewModel.validateCredentials(
                username: self.usernameInput,
                password: self.passwordInput,
                email: self.emailInput.isEmpty ? nil : self.emailInput
            )
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
                    .focused(self.$focusedField, equals: .username)
                SecureField("Password", text: self.$passwordInput)
                    .focused(self.$focusedField, equals: .password)
                if self.isSigningUp {
                    TextField("Email (optional)", text: self.$emailInput)
                        .focused(self.$focusedField, equals: .email)
                }
                Toggle("I want to make a new account", isOn: self.$isSigningUp)
                Button(self.isSigningUp ? "Sign up" : "Login") {
                    Task {
                        if self.isSigningUp {
                            await self.signup()
                        } else {
                            await self.login()
                        }
                    }
                }
                .disabled(self.isBusy)
            }
            .formStyle(.grouped)
            .onAppear {
                self.focusedField = .username
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        self.dismiss()
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

            Button("Forgot your password?") {
                self.isPasswordResetSheetPresented = true
            }
            .foregroundColor(.red)
            .disabled(self.isBusy)
            .sheet(isPresented: self.$isPasswordResetSheetPresented) {
                PasswordResetView()
            }
        }
        .interactiveDismissDisabled(self.isBusy)
    }
}

#if DEBUG
struct LoginSheetView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheetView()
            .environmentObject(GlobalViewModel())
    }
}
#endif
