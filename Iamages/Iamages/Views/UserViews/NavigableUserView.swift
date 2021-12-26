import SwiftUI

struct NavigableUserView: View {
    let user: IamagesUser
    
    var body: some View {
        NavigationLink(destination: PublicUserView(username: self.user.username)) {
            Label(title: {
                Text(verbatim: user.username)
                    .lineLimit(1)
                Spacer()
            }, icon: {
                ProfileImageView(username: user.username)
            })
        }
    }
}
