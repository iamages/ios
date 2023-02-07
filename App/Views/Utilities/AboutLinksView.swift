import SwiftUI

struct AboutLinksView: View {
    var body: some View {
        Link("Review on App Store", destination: URL(string: "https://apps.apple.com/us/app/iamages/id1611306062?action=write-review")!)
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
