import SwiftUI

struct NavigableUserView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
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
        .onDrag {
            return NSItemProvider(item: self.dataObservable.getUserEmbedURL(username: self.user.username) as NSSecureCoding, typeIdentifier: "public.url")
        }
    }
}
