import SwiftUI

struct LoadingMetadataView: View {
    var body: some View {
        HStack {
            ProgressView()
            Text("Loading metadata...")
                .foregroundColor(.gray)
                .padding(.leading, 4)
        }
    }
}

#if DEBUG
struct LoadingMetadataView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingMetadataView()
    }
}
#endif
