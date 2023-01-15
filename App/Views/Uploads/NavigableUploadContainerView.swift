import SwiftUI

struct NavigableUploadContainerView: View {
    let uploadContainer: IamagesUploadContainer
    
    var body: some View {
        NavigationLink(value: self.uploadContainer.id) {
            HStack {
                UniversalDataImage(data: self.uploadContainer.file.data)
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(self.uploadContainer.information.description.isEmpty ? "No description yet" : self.uploadContainer.information.description)
                        .bold()
                        .lineLimit(1)
                        .foregroundColor(self.uploadContainer.information.description.isEmpty ? .red : nil)
                    HStack {
                        Image(systemName: self.uploadContainer.information.isPrivate ? "eye.slash.fill" : "eye.slash")
                        Image(systemName: self.uploadContainer.information.isLocked ? "lock.doc.fill" : "lock.doc")
                    }
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)
        }
    }
}

#if DEBUG
struct NavigableUploadInformationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableUploadContainerView(
            uploadContainer: previewUploadContainer
        )
    }
}
#endif
