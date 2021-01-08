import SwiftUI

enum ScrollableListTypes {
    case latest
    case user
}

struct ScrollableFilesListComponent: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    let list: ScrollableListTypes
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, spacing: 16) {
                switch list {
                case .latest:
                    ForEach(dataCentralObservable.latestFiles, id: \.id) { file in
                        NavigableImageComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                case .user:
                    ForEach(dataCentralObservable.userFiles, id: \.id) { file in
                        NavigableImageComponent(file: file, requestModifier: dataCentralObservable.userRequestModifier)
                    }
                }
            }.padding(.horizontal)
        }
    }
}

struct ScrollableFilesListComponent_Previews: PreviewProvider {
    static var previews: some View {
        ScrollableFilesListComponent(list: .latest)
    }
}
