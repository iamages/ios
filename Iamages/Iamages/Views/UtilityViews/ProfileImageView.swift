import SwiftUI
import Kingfisher

struct ProfileImageView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    let username: String?
    
    var placeholder: some View {
        Image(systemName: "person.circle")
            .resizable()
            .frame(width: 26, height: 26, alignment: .center)
            .scaledToFit()
    }

    var body: some View {
        if username != nil {
            KFAnimatedImage(self.dataObservable.getUserProfilePictureURL(username: self.username!))
                .placeholder {
                    self.placeholder
                }
                .cancelOnDisappear(true)
                .downsampling(size: CGSize(width: 52, height: 52))
                .frame(width: 26, height: 26, alignment: .center)
                .clipShape(Circle())
                .scaledToFit()
        } else {
            self.placeholder
        }
    }
}

struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileImageView(username: "Test Username")
    }
}
