import SwiftUI

enum FilesListTypes {
    case latest
    case user
    case search
}

struct GenericFilesListComponent: View {
    @AppStorage("FilesListDisplayLayout") var filesListDisplayLayout: String = "card"
    let type: FilesListTypes
    var body: some View {
        switch self.filesListDisplayLayout {
        case "card":
            CardFilesListComponent(type: self.type)
        case "grid":
            GridFilesListComponent(type: self.type)
        default:
            CardFilesListComponent(type: self.type)
        }
    }
}

struct GenericFilesListComponent_Previews: PreviewProvider {
    static var previews: some View {
        GenericFilesListComponent(type: .latest)
    }
}
