import SwiftUI

enum FeedType {
    case publicFeed
    case privateFeed
}

struct NavigableFileView: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    @Binding var file: IamagesFile
    @Binding var feed: [IamagesFile]
    let type: FeedType
    
    @AppStorage("isNSFWEnabled", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWEnabled: Bool = true
    @AppStorage("isNSFWBlurred", store: UserDefaults(suiteName: "group.me.jkelol111.Iamages")) var isNSFWBlurred: Bool = true
    
    var body: some View {
        if self.file.isNSFW && !self.isNSFWEnabled {
            Label("NSFW viewing is disabled.", systemImage: "eye.slash")
        } else {
            NavigationLink(destination: FileView(file: self.$file, feed: self.$feed, type: self.type)) {
                VStack(alignment: .leading) {
                    Label(title: {
                        Text(verbatim: self.file.owner ?? "Anonymous")
                            .bold()
                            .lineLimit(1)
                    }, icon: {
                        ProfileImageView(username: self.file.owner)
                    })
                    if self.file.isNSFW && self.isNSFWBlurred {
                        FileThumbnailView(id: self.file.id)
                            .blur(radius: 12.0, opaque: true)
                            .overlay {
                                Image(systemName: "18.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                    } else {
                        FileThumbnailView(id: self.file.id)
                    }
                    Text(verbatim: "\(self.file.description)")
                        .lineLimit(1)
                }
            }
            .onDrag {
                return NSItemProvider(item: self.dataObservable.getFileEmbedURL(id: self.file.id) as NSSecureCoding, typeIdentifier: "public.url")
            }
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
    }
}
