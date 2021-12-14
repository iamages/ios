import SwiftUI

struct HelpLinksView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    var body: some View {
        Link("Terms of Service", destination: URL(string: "\(self.dataObservable.apiRoot)/legal/tos")!)
        Link("Privacy Policy", destination: URL(string: "\(self.dataObservable.apiRoot)/legal/privacy")!)
        Link("Open-source on GitHub", destination: URL(string: "https://github.com/iamages")!)
        Link("API Documentation", destination: URL(string: "\(self.dataObservable.apiRoot)/")!)
        Link("Discuss on Discord", destination: URL(string: "https://discord.com/")!)
    }
}

struct HelpLinksView_Previews: PreviewProvider {
    static var previews: some View {
        HelpLinksView()
    }
}
