import SwiftUI

struct CardFilesListComponent: View {
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
            .padding(.vertical)
        }
    }
}

struct ScrollableFilesListComponent_Previews: PreviewProvider {
    static var previews: some View {
        CardFilesListComponent(type: .latest)
    }
}
