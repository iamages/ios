import SwiftUI

struct DeleteUserScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var newLogin: IamagesUserAuth
    
    @State var isBusy: Bool = false
    @State var alertItem: AlertItem?

    var body: some View {
        VStack(alignment: .center) {
            if self.isBusy {
                ProgressView("Deleting user").progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("deleteUser \(dataCentralObservable.userInformation.auth.username)")
                    .bold()
                    .multilineTextAlignment(.center)
                Text("This is not reversible.")
                Divider()
                Button("Delete forever", action: {
                    self.deleteUser()
                }).buttonStyle(CustomConfirmButtonStyle())
                .padding(.vertical)
            }
        }.padding(.all)
        .navigationBarBackButtonHidden(self.isBusy)
        .alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }
    }
    
    func deleteUser() {
        self.isBusy = true
        dataCentralObservable.deleteUser().done({ yes in
            self.newLogin = IamagesUserAuth(username: "", password: "")
            self.presentationMode.wrappedValue.dismiss()
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("User deletion failed"), message: Text(verbatim: error.localizedDescription), dismissButton: .default(Text("Okay")))
        })
    }
}

struct DeleteUserScreen_Previews: PreviewProvider {
    @State static var newLogin: IamagesUserAuth = IamagesUserAuth(username: "", password: "")
    static var previews: some View {
        DeleteUserScreen(newLogin: self.$newLogin)
    }
}
