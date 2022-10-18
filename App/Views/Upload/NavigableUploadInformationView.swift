import SwiftUI

struct NavigableUploadInformationView: View {
    @Binding var information: IamagesUploadInformation
    let image: Data
    
    var body: some View {
        NavigationLink {
            UploadInformationEditorView(information: self.$information)
        } label: {
            HStack {
                Group {
                    #if os(macOS)
                    Image(nsImage: NSImage(data: self.image)!)
                        .resizable()
                    #else
                    Image(uiImage: UIImage(data: self.image)!)
                        .resizable()
                    #endif
                }
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading) {
                    Text(verbatim: self.information.description)
                        .bold()
                    HStack {
                        Image(systemName: self.information.isPrivate ? "eye.slash.fill" : "eye.slash")
                        Image(systemName: self.information.isLocked ? "lock.doc.fill" : "lock.doc")
                    }
                    
                }
                
                #if os(macOS)
                Spacer()
                Image(systemName: "chevron.right")
                    .tint(.gray)
                #endif
            }
        }
    }
}

#if DEBUG
struct NavigableUploadInformationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableUploadInformationView(
            information: .constant(IamagesUploadInformation()),
            image: Data()
        )
    }
}
#endif
