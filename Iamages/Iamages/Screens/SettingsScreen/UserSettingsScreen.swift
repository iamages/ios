import SwiftUI

struct UserSettingsScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @State var newBiography: String = ""
    @State var currentPassword: String = ""
    @State var newPassword: String = ""
    @State var newPasswordAgain: String = ""
    @State var newLogin: IamagesUserAuth = IamagesUserAuth(username: "", password: "")
    @State var isBusy: Bool = false
    @State var alertItem: AlertItem?
    var body: some View {
        Form {
            if dataCentralObservable.isUserLoggedIn {
                Section(header: Text("Biography")) {
                    TextEditor(text: self.$newBiography)
                    Button(action: {
                        self.updateBiography()
                    }) {
                        HStack {
                            Text("Update biography")
                            Spacer()
                            Image(systemName: "pencil")
                        }
                    }.disabled(self.isBusy)
                }
                
                Section(header: Text("Password")) {
                    SecureField("Current password", text: self.$currentPassword)
                    SecureField("New password", text: self.$newPassword)
                    SecureField("New password, again", text: self.$newPasswordAgain)
                    Button(action: {
                        self.updatePassword()
                    }) {
                        HStack {
                            Text("Update password")
                            Spacer()
                            Image(systemName: "key")
                        }
                    }.disabled(self.isBusy)
                }
            }
            
            Section(header: Text("Authentication")) {
                if dataCentralObservable.isUserLoggedIn {
                    Button(action: {
                        self.logout()
                    }) {
                        HStack {
                            Text("Log out")
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.minus")
                        }
                    }.foregroundColor(.red)
                    .disabled(self.isBusy)
                    Button(action: {
                        self.deleteUser()
                    }) {
                        HStack {
                            Text("Delete user")
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.xmark")
                        }
                    }.foregroundColor(.red)
                    .disabled(self.isBusy)
                } else {
                    TextField("Username", text: self.$newLogin.username)
                    SecureField("Password", text: self.$newLogin.password)
                    Button(action: {
                        self.login()
                    }) {
                        HStack {
                            Text("Log in")
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.plus")
                        }
                    }.disabled(self.isBusy)
                    Button(action: {
                        self.signup()
                    }) {
                        HStack {
                            Text("Sign up")
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.plus")
                        }
                    }.disabled(self.isBusy)
                }
            }
        }.navigationBarTitle("User settings")
        .navigationBarBackButtonHidden(self.isBusy)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if self.isBusy {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
            }
        }.alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }
    }
    
    func updateBiography() {
        self.isBusy = true
        dataCentralObservable.modifyUser(modifications: [.biography: self.newBiography]).done({ yes in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("Modification successful"), message: Text("Biography has been changed!"), dismissButton: .default(Text("Okay")))
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("Modification failed"), message: Text("Couldn't modify your biography."), dismissButton: .default(Text("Okay")))
        })
    }
    
    func updatePassword() {
        if self.currentPassword == dataCentralObservable.userInformation.auth.password {
            if self.newPassword == self.newPasswordAgain {
                if self.newPasswordAgain.count > 1 {
                    self.isBusy = true
                    dataCentralObservable.modifyUser(modifications: [.password: self.newPasswordAgain]).done({ yes in
                        self.isBusy = false
                        self.alertItem = AlertItem(title: Text("Modification successful"), message: Text("Password has been changed!"), dismissButton: .default(Text("Okay")))
                    }).catch({ error in
                        self.isBusy = false
                        self.alertItem = AlertItem(title: Text("Modification failed"), message: Text("Couldn't modify your password."), dismissButton: .default(Text("Okay")))
                    })
                } else {
                    self.alertItem = AlertItem(title: Text("Password too short"), message: Text("The new password is too short!"), dismissButton: .default(Text("Okay")))
                }
            } else {
                self.alertItem = AlertItem(title: Text("Password mismatch"), message: Text("The new passwords don't match."), dismissButton: .default(Text("Okay")))
            }
        } else {
            self.alertItem = AlertItem(title: Text("Password mismatch"), message: Text("The current password doesn't match."), dismissButton: .default(Text("Okay")))
        }
    }
    
    func logout() {
        self.isBusy = true
        dataCentralObservable.logoutUser().done({ yes in
            self.isBusy = false
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("Log in failed"), message: Text("loginFailed"), dismissButton: .default(Text("Okay")))
        })
    }
    
    func login() {
        if self.newLogin.username.count > 1 && self.newLogin.password.count > 1 {
            self.isBusy = true
            dataCentralObservable.loginUser(userAuth: self.newLogin).done({ yes in
                self.isBusy = false
            }).catch({ error in
                self.isBusy = false
                self.alertItem = AlertItem(title: Text("Log in failed"), message: Text("loginFailed"), dismissButton: .default(Text("Okay")))
            })
        } else {
            self.alertItem = AlertItem(title: Text("Log in failed"), message: Text("loginFailed"), dismissButton: .default(Text("Okay")))
        }
    }
    
    func signup() {
        if self.newLogin.username.count > 1 && self.newLogin.password.count > 1 {
            self.isBusy = true
            api.put_root_user_new(userAuth: self.newLogin).done({ yes in
                self.isBusy = false
                self.alertItem = AlertItem(title: Text("Sign up successful"), message: Text("You can now log in."), dismissButton: .default(Text("Okay")))
            }).catch({ error in
                self.isBusy = false
                self.alertItem = AlertItem(title: Text("Sign up failed"), message: Text("signUpFailed \(error.localizedDescription)"), dismissButton: .default(Text("Okay")))
            })
        } else {
            self.alertItem = AlertItem(title: Text("Sign up failed"), message: Text("Username or password too short!"), dismissButton: .default(Text("Okay")))
        }
    }
    
    func deleteUser() {
        self.isBusy = true
        dataCentralObservable.deleteUser().done({ yes in
            self.isBusy = false
            self.newLogin = IamagesUserAuth(username: "", password: "")
            self.alertItem = AlertItem(title: Text("User deleted"), message: nil, dismissButton: .default(Text("Okay")))
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("User deletion failed"), message: Text(verbatim: error.localizedDescription), dismissButton: .default(Text("Okay")))
        })
    }
}

struct UserSettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsScreen()
    }
}
