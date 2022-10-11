import SwiftUI
import NukeUI

struct ImageDetailView: View {
    let image: IamagesImage
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#if DEBUG
struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailView(
            image: IamagesImage(
                owner: "jkelol111",
                isPrivate: false,
                lock: Lock(
                    is_locked: false,
                    version: .aes128gcm_argon2
                ),
                thumbnail: Thumbnail(
                    is_computing: false,
                    compute_attempts: 1
                )
            )
        )
    }
}
#endif
