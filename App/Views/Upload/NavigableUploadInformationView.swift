import SwiftUI

struct NavigableUploadInformationView: View {
    @Binding var uploadContainer: IamagesUploadContainer
    
    var body: some View {
        NavigationLink {
            UploadInformationEditorView(information: self.$uploadContainer.information)
        } label: {
            HStack {
                UniversalDataImage(data: self.uploadContainer.file.data)
                    .frame(width: 64, height: 64)
                
                VStack(alignment: .leading) {
                    Text(verbatim: self.uploadContainer.information.description)
                        .bold()
                    HStack {
                        Image(systemName: self.uploadContainer.information.isPrivate ? "eye.slash.fill" : "eye.slash")
                        Image(systemName: self.uploadContainer.information.isLocked ? "lock.doc.fill" : "lock.doc")
                    }
                    
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .tint(.gray)
            }
        }
    }
}

#if DEBUG
struct NavigableUploadInformationView_Previews: PreviewProvider {
    static var previews: some View {
        if let asset: NSDataAsset = NSDataAsset(name: "preview_image") {
            NavigableUploadInformationView(
                uploadContainer: .constant(
                    IamagesUploadContainer(
                        file: IamagesUploadFile(
                            name: "test.jpg",
                            data: asset.data,
                            type: "image/jpeg"
                        )
                    )
                )
            )
        } else {
            Text("Could not find preview image.")
        }
    }
}
#endif
