import SwiftUI

struct HelpLinksView: View {
    var body: some View {
        Group {
            Link(destination: URL(string: "https://iamages.uber.space/iamages/api/v3/legal/tos")!) {
                Label("Terms of Service", systemImage: "doc")
            }
            Link(destination: URL(string: "https://iamages.uber.space/iamages/api/v3/legal/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: "https://github.com/iamages")!) {
                Label("Open-source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Link(destination: URL(string: "https://discord.com/")!) {
                Label("Discuss on Discord", systemImage: "text.bubble")
            }
        }
        #if targetEnvironment(macCatalyst)
        .buttonStyle(.borderless)
        #endif
    }
}

struct HelpLinksView_Previews: PreviewProvider {
    static var previews: some View {
        HelpLinksView()
    }
}
