import SwiftUI

struct UploadOwnershipFooter: View {
    let isLoggedIn: Bool
    let isLocked: Bool
    
    var body: some View {
        Text((self.isLoggedIn ? "" : "Log in to an account in the app to privatize your photos.\n\n") + (self.isLocked ? "Locked images are encrypted in the cloud using your provided password. These features will be disabled:\n· Thumbnail in images list\n· Social media embed cards.\n· Local image cache.\nYou will have to unlock locked images manually everytime you open the app. People who receive your public link also need a password to decrypt the image." : ""))
    }
}

struct UploadOwnershipFooter_Previews: PreviewProvider {
    static var previews: some View {
        UploadOwnershipFooter(
            isLoggedIn: false, isLocked: true
        )
    }
}
