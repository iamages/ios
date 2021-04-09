import SwiftUI

struct EmptyHereComponent: View {
    var body: some View {
        VStack(alignment: .center) {
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
        }.padding(.all)
    }
}

struct EmptyHereComponent_Previews: PreviewProvider {
    static var previews: some View {
        EmptyHereComponent()
    }
}
