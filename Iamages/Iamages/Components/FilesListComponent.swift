import SwiftUI

enum FilesListTypes {
    case latest
    case user
    case search
}

struct ScrollableFilesComponent: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    let type: FilesListTypes
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .center, spacing: 16) {
                switch type {
                case .latest:
                    ForEach(dataCentralObservable.latestFiles, id: \.id) { file in
                        NavigableImageCardComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                case .user:
                    ForEach(dataCentralObservable.userFiles, id: \.id) { file in
                        NavigableImageCardComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                case .search:
                    ForEach(dataCentralObservable.searchFiles, id: \.id) { file in
                        NavigableImageCardComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                }
            }.padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct FilesListComponent: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    let type: FilesListTypes
    var body: some View {
        switch self.type {
        case .latest:
            if dataCentralObservable.latestFiles.count >= 1 {
                ScrollableFilesComponent(type: self.type)
            } else {
                EmptyHereComponent(type: .normal)
            }
        case .user:
            if dataCentralObservable.userFiles.count >= 1 {
                ScrollableFilesComponent(type: self.type)
            } else {
                EmptyHereComponent(type: .normal)
            }
        case .search:
            if dataCentralObservable.searchFiles.count >= 1 {
                ScrollableFilesComponent(type: self.type)
            } else {
                EmptyHereComponent(type: .search)
            }
        }
        
    }
}

struct ScrollableFilesListComponent_Previews: PreviewProvider {
    static var previews: some View {
        FilesListComponent(type: .latest)
    }
}
