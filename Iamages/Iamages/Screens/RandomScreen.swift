import SwiftUI

struct RandomScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @State private var isBusy: Bool = false
    @State private var alertItem: AlertItem?
    var body: some View {
        NavigationView {
            if dataCentralObservable.randomFiles.count >= 1 {
                ScrollableFilesListComponent(list: .random)
                    .navigationBarTitle("Random")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                self.refreshRandom()
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
                        .navigationBarTitle("Random")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    self.refreshRandom()
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
    
    func refreshRandom() {
        self.isBusy = true
        dataCentralObservable.fetchRandom().done({ yes in
            self.isBusy = false
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("Refresh failed"), message: Text(error.localizedDescription), dismissButton: .default(Text("Okay")))
        })
    }
}

struct RandomScreen_Previews: PreviewProvider {
    static var previews: some View {
        RandomScreen()
    }
}
