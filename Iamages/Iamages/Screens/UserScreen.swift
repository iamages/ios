import SwiftUI

struct UserScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @State var isBusy: Bool = false
    @State var alertItem: AlertItem?
    var body: some View {
        NavigationView {
            if dataCentralObservable.userFiles.count >= 1 {
                ScrollableFilesListComponent(list: .user)
                    .navigationBarTitle(dataCentralObservable.userInformation.auth.username)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                self.refreshUser()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }.disabled(self.isBusy)
                        }
                    }
            } else {
                if self.isBusy {
                    ProgressView("Loading data").progressViewStyle(CircularProgressViewStyle())
                        .navigationBarTitle("Latest")
                } else {
                    EmptyHereComponent()
                        .navigationBarTitle(dataCentralObservable.userInformation.auth.username)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    self.refreshUser()
                                }) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }.disabled(self.isBusy)
                            }
                        }
                }
            }
        }.alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    func refreshUser() {
        self.isBusy = true
        dataCentralObservable.fetchUser().done({ yes in
            self.isBusy = false
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("Refresh failed"), message: Text(verbatim: error.localizedDescription), dismissButton: .default(Text("Okay")))
        })
    }
}

struct UserScreen_Previews: PreviewProvider {
    static var previews: some View {
        UserScreen()
    }
}
