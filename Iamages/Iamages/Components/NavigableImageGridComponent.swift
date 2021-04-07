import SwiftUI
import Kingfisher

struct NavigableImageGridComponent: View {
    let file: IamagesFileInformationResponse
    let requestModifier: AnyModifier
    @AppStorage("NSFWEnabled") var isNSFWEnabled: Bool = false
    @State var isNavigationLinkActive = false
    var body: some View {
        if isNSFWEnabled || !file.isNSFW {
            NavigationLink(destination: ImageDetailsScreen(file: file, requestModifier: requestModifier)) {
                GroupBox {
                    KFImage(api.get_root_thumb(id: file.id))
                        .requestModifier(requestModifier)
                        .resizable()
                        .cancelOnDisappear(true)
                        .placeholder {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        }
                        .cornerRadius(4)
                        .scaledToFit()
                }
            }
//            KFImage(api.get_root_thumb(id: file.id))
//                .requestModifier(requestModifier)
//                .resizable()
//                .cancelOnDisappear(true)
//                .placeholder {
//                    ProgressView().progressViewStyle(CircularProgressViewStyle())
//                }
//                .scaledToFit()
//                .background(
//                    NavigationLink(destination: ImageDetailsScreen(file: file, requestModifier: requestModifier), isActive: self.$isNavigationLinkActive) {
//                        EmptyView()
//                    }
//                )
//                .onTapGesture {
//                    self.isNavigationLinkActive = true
//                }
        } else {
            Image(systemName: "18.circle")
        }
    }
}

struct NavigableImageGridComponent_Previews: PreviewProvider {
    static var previews: some View {
        NavigableImageGridComponent(file: IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!, requestModifier: AnyModifier(modify: { request in
            return request
        }))
    }
}
