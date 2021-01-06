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
                }).buttonStyle(CustomConfirmButtonStyle())
                .padding(.vertical)
                Button("Cancel", action: {
                    self.presentationMode.wrappedValue.dismiss()
                })
            }
        }.padding(.all)
        .navigationBarBackButtonHidden(true)
        .alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }
    }
    
    func deleteUser() {
        
    }
}

struct DeleteUserScreen_Previews: PreviewProvider {
    @State static var newLogin: IamagesUserAuth = IamagesUserAuth(username: "", password: "")
    static var previews: some View {
        DeleteUserScreen(newLogin: self.$newLogin)
    }
}
