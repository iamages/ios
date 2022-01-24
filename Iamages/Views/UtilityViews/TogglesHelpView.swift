import SwiftUI

struct TogglesHelpView: View {
    var body: some View {
        List {
            Section("NSFW") {
                Text("Use this if your file is aimed towards mature audiences.")
            }
            Section("Private") {
                Text("Use this when you want to only allow your account to view this file/collection.")
            }
            Section("Hidden") {
                Text("Use this to allow others with your file/collection ID to view your file, but keep it hidden from public feeds.")
            }
        }
        .frame(width: 300, height: 250)
        .padding(.top)
    }
}
