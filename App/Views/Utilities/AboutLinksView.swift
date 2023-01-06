import SwiftUI

struct AboutLinksView: View {
    var body: some View {
        Link("Open-source on GitHub", destination: URL(string: "https://github.com/iamages")!)
        Link("Terms of Service", destination: URL.apiRootUrl.appending(path: "/legal/tos"))
        Link("Privacy Policy", destination: URL.apiRootUrl.appending(path: "/legal/privacy"))
    }
}

#if DEBUG
struct AboutLinksView_Previews: PreviewProvider {
    static var previews: some View {
        AboutLinksView()
    }
}
#endif
