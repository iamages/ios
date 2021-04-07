import SwiftUI
import Kingfisher

struct NavigableImageCardComponent: View {
    let file: IamagesFileInformationResponse
    let requestModifier: AnyModifier
    @AppStorage("NSFWEnabled") var isNSFWEnabled: Bool = false
    var body: some View {
        if isNSFWEnabled || !file.isNSFW {
            NavigationLink(destination: ImageDetailsScreen(file: file, requestModifier: requestModifier)) {
                GroupBox(label: Text(verbatim: file.description), content: {
                    KFImage(api.get_root_thumb(id: file.id))
                        .requestModifier(requestModifier)
                        .resizable()
                        .cancelOnDisappear(true)
                        .placeholder {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        }
                        .cornerRadius(4)
                        .scaledToFit()
                })
            }
        } else {
            Text("NSFW disabled, this file won't be visible.").multilineTextAlignment(.center)
        }
    }
}

struct NavigableImageComponent_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageCardComponent(file: IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!, requestModifier: AnyModifier(modify: { request in
            return request
        }))
    }
}
