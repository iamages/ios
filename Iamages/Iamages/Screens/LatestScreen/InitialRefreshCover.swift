import SwiftUI

struct InitialRefreshCover: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @Binding var isInitialRefreshCoverPresented: Bool
    @State var alertItem: AlertItem?
    var body: some View {
        ProgressView("Loading data").progressViewStyle(CircularProgressViewStyle())
            .alert(item: self.$alertItem) { item in
                Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
            }
            .onAppear() {
                self.refreshAll()
            }
    }
    
    func refreshAll() {
        dataCentralObservable.fetchLatest().done({ yes in
            print("Successfully refreshed initial latest data.")
            dataCentralObservable.fetchUser().done({ yes in
                print("Successfully refreshed initial user data.")
                self.isInitialRefreshCoverPresented = false
            }).catch({ error in
                print("Failed to refresh initial user data.")
                self.isInitialRefreshCoverPresented = false
            })
        }).catch({ error in
            print("Failed to refresh latest user data.")
            self.isInitialRefreshCoverPresented = false
        })
    }
}

struct InitialRefreshCover_Previews: PreviewProvider {
    @State static var isInitialRefreshCoverPresented: Bool = false
    static var previews: some View {
        InitialRefreshCover(isInitialRefreshCoverPresented: self.$isInitialRefreshCoverPresented)
    }
}
