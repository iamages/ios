import SwiftUI
import Combine

struct PasswordResetView: View {
    enum Views {
        case reset
        case done
    }
    
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    private let secondsFormatter = DateComponentsFormatter()
    
    init() {
        self.secondsFormatter.allowedUnits = [.minute, .second]
        self.secondsFormatter.unitsStyle = .full
    }

    @State private var path: [Views] = []
    @State private var isBusy: Bool = false
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword1: String = ""
    @State private var newPassword2: String = ""
    
    @State private var error: LocalizedAlertError?
    
    private func getCode() async {
        self.isBusy = true
        do {
            try await self.globalViewModel.fetchData(
                "/users/password/code",
                method: .post,
                body: self.email.data(using: .utf8),
                contentType: .text
            )
            withAnimation {
                self.path.append(.reset)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        self.isBusy = false
    }
    
    private func resetPassword() async {
        self.isBusy = true
        do {
            if self.newPassword1 != self.newPassword2 {
                throw PasswordMismatchError()
            }
            try self.globalViewModel.validateCredentials(password: self.newPassword1)
            try await self.globalViewModel.fetchData(
                "/users/password/reset",
                method: .post,
                body: try self.globalViewModel.jsone.encode(
                    IamagesPasswordReset(
                        email: self.email,
                        code: self.code,
                        newPassword: self.newPassword1
                    )
                ),
                contentType: .json
            )
            withAnimation {
                self.path.append(.done)
            }
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
        
            self.isBusy = false
    }
    
    var body: some View {
        NavigationStack(path: self.$path) {
            VStack(alignment: .leading, spacing: 16) {
                Text("1")
                    .font(.largeTitle)
                    .bold()
                Text("Input your email")
                    .font(.title)
                TextField("Email", text: self.$email)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                Text("If you did not add an email to your account, password recovery will not be possible.")
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                    .disabled(self.isBusy)
                }
                ToolbarItem {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Button("Next") {
                            Task {
                                await self.getCode()
                            }
                        }
                        .disabled(!self.email.isEmail())
                    }
                }
            }
            .navigationDestination(for: Views.self) { view in
                switch view {
                case .reset:
                    VStack(alignment: .leading, spacing: 16) {
                        Text("2")
                            .font(.largeTitle)
                            .bold()
                        Text("Input your code & new password")
                            .font(.title)
                        Group {
                            TextField("Code", text: self.$code)
                                .keyboardType(.numberPad)
                                .onReceive(Just(self.code)) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        self.code = filtered
                                    }
                                }
                            SecureField("New password", text: self.$newPassword1)
                            SecureField("New password, again", text: self.$newPassword2)
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        Text("You can find the code in your email inbox.\nIf you do not see it, check the spam folder.")
                        Spacer()
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem {
                            if self.isBusy {
                                ProgressView()
                            } else {
                                Button("Reset") {
                                    Task {
                                        await self.resetPassword()
                                    }
                                }
                            }
                        }
                        
                    }
                case .done:
                    IconAndInformationView(
                        icon: "checkmark",
                        heading: "Password reset complete",
                        subheading: "You can now login with your new password"
                    )
                    .navigationBarBackButtonHidden()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(2))) {
                            self.dismiss()
                        }
                    }
                }
            }
        }
        .errorAlert(error: self.$error)
    }
}

#if DEBUG
struct PasswordResetView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetView()
    }
}
#endif
