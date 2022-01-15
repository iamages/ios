import SwiftUI

struct NavigableModifyUploadRequestView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var uploadRequest: UploadFileRequest
    
    var body: some View {
        NavigationLink(destination: ModifyUploadRequestView(uploadRequest: self.$uploadRequest)) {
            VStack(alignment: .leading) {
                Label(title: {
                    Text(verbatim: self.dataObservable.currentAppUser?.username ?? "Anonymous")
                        .bold()
                        .lineLimit(1)
                }, icon: {
                    ProfileImageView(username: self.dataObservable.currentAppUser?.username)
                })
                if uploadRequest.file != nil {
                    Image(uiImage: UIImage(data: self.uploadRequest.file!.image)!)
                        .resizable()
                        .scaledToFit()
                } else {
                    Label(self.uploadRequest.info.url!.absoluteString, systemImage: "globe")
                        .lineLimit(1)
                }
                Text(self.uploadRequest.info.description)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}
