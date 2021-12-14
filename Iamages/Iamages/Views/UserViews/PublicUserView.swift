import SwiftUI

struct PublicUserView: View {
    @EnvironmentObject var dataObserable: APIDataObservable
    
    let username: String
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct PublicUserView_Previews: PreviewProvider {
    static var previews: some View {
        PublicUserView(username: "")
    }
}
