import SwiftUI

// Thanks to Alex Holder
// Apple, we need a simpler search bar in SwiftUI!
struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var search: () -> Void

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var search: () -> Void

        init(text: Binding<String>, searchAction: @escaping () -> Void) {
            _text = text
            search = searchAction
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            search()
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text, searchAction: search)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.placeholder = NSLocalizedString("Description", comment: "")
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}

struct SearchScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @State var description: String = ""
    @State var alertItem: AlertItem?
    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        SearchBar(text: self.$description, search: self.search)
                            .navigationBarTitle("Search")
                            .alert(item: self.$alertItem) { item in
                                Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
                            }
                        Button(action: {
                            self.cancel()
                        }) {
                            Text("Clear")
                        }
                    }.padding(.horizontal)

                    Divider()
                        .padding(.horizontal)
                        .padding(.bottom)

                    FilesListComponent(type: .search)
                }
                Spacer()
            }
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
        self.dataCentralObservable.cancelSearch = true
        self.dataCentralObservable.searchFiles = []
        self.description = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchScreen_Previews: PreviewProvider {
    static var previews: some View {
        SearchScreen()
    }
}
