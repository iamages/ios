import SwiftUI

enum Searches {
    case files
    case collections
    case users
}

struct SearchView: View {
    @State var selectedSearch: Searches = .files
    @State var searchString: String = ""
    
    var main: some View {
        List {
            
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("Search", selection: self.$selectedSearch) {
                    Text("Files")
                        .tag(Searches.files)
                    Text("Collections")
                        .tag(Searches.collections)
                    Text("Users")
                        .tag(Searches.users)
                }.labelsHidden()
            }
        }.searchable(text: self.$searchString)
        .navigationTitle("Search")
    }

    var body: some View {
        #if targetEnvironment(macCatalyst)
        main
        #else
        NavigationView {
            main
        }
        #endif
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
