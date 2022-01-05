import SwiftUI

struct ManageUserView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var isPresented: Bool

    @State var isBusy: Bool = false
    
    @State var username: String = ""
    @State var password: String = ""
    
    @State var currentPasswordInput: String = ""
    @State var newPasswordInput1: String = ""
    @State var newPasswordInput2: String = ""
    @State var isChangePasswordConfirmationPresented: Bool = false

    @State var isErrorAlertPresented: Bool = false
    @State var errorText: String?
    
    @State var isPrivateAllAlertPresented: Bool = false
    @State var isHideAllAlertPresented: Bool = false
    
    @State var isDeleteAlertPresented: Bool = false
    @State var isRemoveProfilePictureAlertPresented: Bool = false
    
    func presentError(_ error: Error) {
        print(error)
        self.errorText = error.localizedDescription
        self.isErrorAlertPresented = true
    }
    
    func changePassword () async {
        self.isBusy = true
        do {
            try await self.dataObservable.modifyAppUser(modify: .password(self.newPasswordInput1))
        } catch {
            self.presentError(error)
        }
        self.isBusy = false
    }
    
    func login () async {
        self.isBusy = true
        do {
            try await self.dataObservable.saveAppUser(username: self.username, password: self.password)
        } catch {
            self.presentError(error)
        }
        self.isBusy = false
    }
    
    func signup () async {
        self.isBusy = true
        do {
            try await self.dataObservable.makeNewAppUser(username: self.username, password: self.password)
        } catch {
            self.presentError(error)
        }
        self.isBusy = false
    }
    
    func logout () {
        self.isBusy = true
        do {
            try self.dataObservable.logoutAppUser()
        } catch {
            self.presentError(error)
        }
        self.isBusy = false
    }
    
    func delete () async {
        self.isBusy = true
        do {
            try await self.dataObservable.deleteAppUser()
        } catch {
            self.presentError(error)
        }
        self.username = ""
        self.password = ""
        self.isBusy = false
    }
    
    func privatize (method: UserPrivatizable) async {
        self.isBusy = true
        do {
            try await self.dataObservable.privatizeAppUser(method: method)
        } catch {
            self.presentError(error)
        }
        self.isBusy = false
    }
    
    func removeProfilePicture () async {
        self.isBusy = true
        do {
            try await self.dataObservable.modifyAppUser(modify: .pfp("remove"))
        } catch {
            self.presentError(error)
        }
        self.isBusy = false
    }
    
    var body: some View {
        NavigationView {
            Form {
                if !self.dataObservable.isLoggedIn {
                    TextField("Username", text: self.$username)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("Password", text: self.$password)
                        .onSubmit {
                            Task {
                                await self.login()
                            }
                        }

                    Button("Log in") {
                        Task {
                            await self.login()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(self.isBusy)
    
                    Button("Sign up") {
                        Task {
                            await self.signup()
                        }
                    }
                    .disabled(self.isBusy)
                } else {
                    Section {
                        HStack(alignment: .center) {
                            ProfileImageView(username: self.dataObservable.currentAppUser?.username)
                            Text(self.dataObservable.currentAppUser!.username)
                        }
                        if let relativeCreated = Formatter.localRelativeTime.string(for: self.dataObservable.currentAppUserInformation?.created) {
                            HStack {
                                Text("Created")
                                    .bold()
                                Spacer()
                                Text(relativeCreated.capitalized)
                            }
                        }
                    } header: {
                        Text("Information")
                    } footer: {
                        Text("To change your profile photo, find a photo in your library, and use the menu option.")
                    }
                    Section("Privacy") {
                        if self.dataObservable.currentAppUserInformation?.pfp != nil {
                            Button("Remove profile picture", role: .destructive) {
                                self.isRemoveProfilePictureAlertPresented = true
                            }
                            .confirmationDialog(
                                "Your current profile picture will be removed. The file will not be deleted.",
                                isPresented: self.$isRemoveProfilePictureAlertPresented,
                                titleVisibility: .visible
                            ) {
                                Button("Remove profile picture", role: .destructive) {
                                    Task {
                                        await self.removeProfilePicture()
                                    }
                                }
                            }
                        }
                        Button("Mark everything as private", role: .destructive) {
                            self.isPrivateAllAlertPresented = true
                        }
                        .confirmationDialog(
                            "All of your files & collections will be marked as private. The changes will be applied gradually.",
                            isPresented: self.$isPrivateAllAlertPresented,
                            titleVisibility: .visible
                        ) {
                            Button("Mark everything as private", role: .destructive) {
                                Task {
                                    await self.privatize(method: .privatize_all)
                                }
                            }
                        }
                        Button("Mark all files as hidden", role: .destructive) {
                            self.isHideAllAlertPresented = true
                        }
                        .confirmationDialog(
                            "All of your files & collections will be marked as hidden. The changes will be applied gradually.",
                            isPresented: self.$isHideAllAlertPresented,
                            titleVisibility: .visible
                        ) {
                            Button("Mark all files as hidden", role: .destructive) {
                                Task {
                                    await self.privatize(method: .hide_all)
                                }
                            }
                        }
                    }
                    Section("Password") {
                        SecureField("Current password", text: self.$currentPasswordInput)
                        SecureField("New password", text: self.$newPasswordInput1)
                        SecureField("New password, again", text: self.$newPasswordInput2)
                        Button("Change password") {
                            if self.currentPasswordInput != self.dataObservable.currentAppUser?.password {
                                self.errorText = "Your current password doesn't match!"
                                self.isErrorAlertPresented = true
                            } else if self.newPasswordInput1 != self.newPasswordInput2 {
                                self.errorText = "The new passwords don't match!"
                                self.isErrorAlertPresented = true
                            } else if self.newPasswordInput1.isEmpty {
                                self.errorText = "No new password given."
                                self.isErrorAlertPresented = true
                            } else {
                                self.isChangePasswordConfirmationPresented = true
                            }
                        }
                        .confirmationDialog("You will change your password.", isPresented: self.$isChangePasswordConfirmationPresented, titleVisibility: .visible) {
                            Button("Change password", role: .destructive) {
                                Task {
                                    await self.changePassword()
                                }
                            }
                        }
                        .disabled(self.isBusy)
                    }

                    Button("Delete account", role: .destructive) {
                        self.isDeleteAlertPresented = true
                    }
                    .confirmationDialog(
                        "Delete '\(self.dataObservable.currentAppUser!.username)'?",
                        isPresented: self.$isDeleteAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Delete account", role: .destructive) {
                            Task {
                                await self.delete()
                            }
                        }
                    } message: {
                        Text("This will remove all your uploaded data!")
                    }
                    .disabled(self.isBusy)

                    Button("Log out", action: self.logout)
                        .disabled(self.isBusy)
                }
            }
            .toolbar {
                ToolbarItem {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Button(action: {
                            self.isPresented = false
                        }) {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                }
            }
            .alert(self.errorText ?? "Unknown error.", isPresented: self.$isErrorAlertPresented) {}
            .navigationTitle((self.dataObservable.currentAppUser?.username == nil)  ? "Login" : "Manage")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(self.isBusy)
    }
}
