import SwiftUI
import Kingfisher

struct InternalImageComponent: View {
    let file: IamagesFileInformationResponse
    let requestModifier: AnyModifier
    var body: some View {
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

struct NavigableImageCardComponent: View {
    let file: IamagesFileInformationResponse
    let requestModifier: AnyModifier
    @AppStorage("NSFWEnabled") var isNSFWEnabled: Bool = false
    @AppStorage("NSFWBlurred") var isNSFWBlurred: Bool = true
    var body: some View {
        if self.isNSFWEnabled || !self.file.isNSFW {
            NavigationLink(destination: ImageDetailsScreen(file: self.file, requestModifier: self.requestModifier)) {
                GroupBox(label: Text(verbatim: self.file.description), content: {
                    if self.file.isNSFW && self.isNSFWBlurred {
                        InternalImageComponent(file: self.file, requestModifier: self.requestModifier)
                            .blur(radius: 6.0)
                            .colorMultiply(.red)
                            
                    } else {
                        InternalImageComponent(file: self.file, requestModifier: self.requestModifier)
                    }
                })
            }
        } else {
            GroupBox(label: Text("NSFW disabled, this file won't be visible."), content: {
                EmptyView()
            })
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
