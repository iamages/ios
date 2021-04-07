import SwiftUI

struct GridFilesListComponent: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    let type: FilesListTypes
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), alignment: .center) {
                switch type {
                case .latest:
                    ForEach(dataCentralObservable.latestFiles, id: \.id) { file in
                        NavigableImageGridComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                case .user:
                    ForEach(dataCentralObservable.userFiles, id: \.id) { file in
                        NavigableImageGridComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                case .search:
                    ForEach(dataCentralObservable.searchFiles, id: \.id) { file in
                        NavigableImageGridComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                }
            }.padding(.horizontal)
            .padding(.vertical)
        }
    }
}

struct HorizontalFilesListComponent_Previews: PreviewProvider {
    static var previews: some View {
        GridFilesListComponent(type: .latest)
    }
}
