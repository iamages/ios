import SwiftUI

enum EmptyHereTypes {
    case normal
    case search
}

struct EmptyHereComponent: View {
    let type: EmptyHereTypes
    var body: some View {
        VStack(alignment: .center) {
            switch self.type {
            case .normal:
                Image(systemName: "cube.transparent")
                    .font(.largeTitle)
                    .padding(.vertical)
                Text("Nothing found here...")
                    .font(.title2)
                    .bold()
                    .padding(.bottom)
                Text("Check your internet connection, or your login. Maybe you don't have files?")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            case .search:
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .padding(.vertical)
                Text("Start searching")
                    .font(.title2)
                    .bold()
                    .padding(.bottom)
                Text("Enter your description above and tap Search on your keyboard to start searching.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
        }.padding(.all)
        
    }
}

struct EmptyHereComponent_Previews: PreviewProvider {
    static var previews: some View {
        EmptyHereComponent(type: .normal)
    }
}
