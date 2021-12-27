import SwiftUI

struct ToggleHelpView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Toggle help")
                .font(.title)
                .bold()
            Text("NSFW")
                .font(.title2)
            Text("Use this if your file is aimed towards mature audiences.")
            Text("Private")
                .font(.title2)
            Text("Use this when you want to only allow your account to view this file/collection.")
            Text("Hidden")
                .font(.title2)
            Text("Use this to allow others with your file/collection ID to view your file, but keep it hidden from public feeds.")
        }
        .padding()
    }
}
