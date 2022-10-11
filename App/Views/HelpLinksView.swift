import SwiftUI

struct HelpLinksView: View {
    var body: some View {
        Link("Source code", destination: URL(string: "https://github.com/iamages")!)
    }
}

struct HelpLinksView_Previews: PreviewProvider {
    static var previews: some View {
        HelpLinksView()
    }
}
