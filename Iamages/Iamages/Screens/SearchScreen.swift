import SwiftUI
import SwiftUIX

struct SearchScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @State var description: String = ""
    @State var isEditing: Bool = false
    @State var alertItem: AlertItem?
    var body: some View {
        NavigationView {
            FilesListComponent(type: .search)
                .navigationSearchBar {
                    SearchBar("Description", text: self.$description, isEditing: self.$isEditing, onCommit: self.search)
                        .showsCancelButton(self.isEditing)
                        .onCancel {
                            self.cancel()
                        }
                }.navigationSearchBarHiddenWhenScrolling(true)
                .navigationBarTranslucent(false)
                .navigationBarTitle("Search")
        }
    }
    
    func search() {
        self.dataCentralObservable.fetchSearch(description: self.description).done({ yes in
            print("Search for '\(self.description)' complete.")
        }).catch({ error in
            self.alertItem = AlertItem(title: Text("Search failed"), message: Text(verbatim: error.localizedDescription), dismissButton: .default(Text("Okay")))
        })
    }
    
    func cancel() {
        self.dataCentralObservable.searchFiles = []
        self.description = ""
    }
}

struct SearchScreen_Previews: PreviewProvider {
    static var previews: some View {
        SearchScreen()
    }
}
