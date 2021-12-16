import SwiftUI

struct NavigableUserView: View {
    let user: IamagesUser
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
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

struct NavigableUserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableUserView(user: IamagesUser(username: "", created: Date(), pfp: nil))
    }
}
