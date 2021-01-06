import SwiftUI
import KingfisherSwiftUI
import struct Kingfisher.AnyModifier

struct NavigableImageComponent: View {
    let file: IamagesFileInformationResponse
    let requestModifier: AnyModifier
    @AppStorage("NSFWEnabled") private var isNSFWEnabled = false
    var body: some View {
        if isNSFWEnabled || !file.isNSFW {
            NavigationLink(destination: ImageDetailsScreen(file: file, requestModifier: requestModifier), label: {
                GroupBox(label: Text(verbatim: file.description), content: {
                    KFImage(api.get_root_img(id: file.id), options: [.requestModifier(requestModifier)])
                        .resizable()
                        .cancelOnDisappear(true)
                        .placeholder {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.largeTitle)
                                .opacity(0.3)
                        }
                        .cornerRadius(4)
                        .scaledToFit()
                })
            })
        } else {
            Text("NSFW disabled, this file won't be visible.").multilineTextAlignment(.center)
        }
    }
}

struct NavigableImageComponent_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageComponent(file: IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!, requestModifier: AnyModifier(modify: { request in
            return request
        }))
    }
}
