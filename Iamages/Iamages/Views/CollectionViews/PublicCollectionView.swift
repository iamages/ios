import SwiftUI

struct PublicCollectionView: View {
    @EnvironmentObject var dataObserable: APIDataObservable
    
    let id: String
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct PublicCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        PublicCollectionView(id: "")
    }
}
