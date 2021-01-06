import SwiftUI

struct LatestScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @State private var isBusy: Bool = false
    @State private var alertItem: AlertItem?
    @State var isFirstRefreshCompleted: Bool = false
    @State var isInitialRefreshCoverPresented: Bool = false

    var body: some View {
        NavigationView {
            if dataCentralObservable.latestFiles.count >= 1 {
                ScrollableFilesListComponent(list: .latest)
                    .navigationBarTitle("Latest")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                self.refreshLatest()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }.disabled(self.isBusy)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if self.isBusy {
                                ProgressView().progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
            } else {
                EmptyHereComponent()
                    .navigationBarTitle("Latest")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                self.refreshLatest()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }.disabled(self.isBusy)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if self.isBusy {
                                ProgressView().progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
            }
        }.onAppear() {
            if !self.isFirstRefreshCompleted {
                self.isInitialRefreshCoverPresented = true
                self.isFirstRefreshCompleted = true
            }
        }.fullScreenCover(isPresented: self.$isInitialRefreshCoverPresented) {
            InitialRefreshCover(isInitialRefreshCoverPresented: self.$isInitialRefreshCoverPresented)
        }.alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    func refreshLatest() {
        self.isBusy = true
        dataCentralObservable.fetchLatest().done({ yes in
            self.isBusy = false
        }).catch({ error in
            self.isBusy = false
            self.alertItem = AlertItem(title: Text("Refresh failed"), message: Text(error.localizedDescription), dismissButton: .default(Text("Okay")))
        })
    }
}

struct LatestScreen_Previews: PreviewProvider {
    static var previews: some View {
        LatestScreen()
    }
}
