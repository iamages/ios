import SwiftUI

enum FilesListTypes {
    case latest
    case user
    case search
}

struct FilesListComponent: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    let type: FilesListTypes
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .center, spacing: 16) {
                switch type {
                case .latest:
                    if dataCentralObservable.latestFiles.count >= 1 {
                        ForEach(dataCentralObservable.latestFiles, id: \.id) { file in
                            NavigableImageCardComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                        }
                    } else {
                        EmptyHereComponent()
                    }
                case .user:
                    if dataCentralObservable.userFiles.count >= 1 {
                        ForEach(dataCentralObservable.userFiles, id: \.id) { file in
                            NavigableImageCardComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                        }
                    } else {
                        EmptyHereComponent()
                    }
                case .search:
                    if dataCentralObservable.searchFiles.count >= 1 {
                        ForEach(dataCentralObservable.searchFiles, id: \.id) { file in
                            NavigableImageCardComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                        }
                    } else {
                        EmptyHereComponent()
                    }
                }
            }.padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct ScrollableFilesListComponent_Previews: PreviewProvider {
    static var previews: some View {
        FilesListComponent(type: .latest)
    }
}
