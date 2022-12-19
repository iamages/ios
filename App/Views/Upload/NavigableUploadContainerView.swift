import SwiftUI

struct NavigableUploadContainerView: View {
    @Binding var uploadContainer: IamagesUploadContainer
    
    var body: some View {
        NavigationLink(value: self.uploadContainer) {
            HStack {
                UniversalDataImage(data: self.uploadContainer.file.data)
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(verbatim: self.uploadContainer.information.description)
                        .bold()
                        .lineLimit(1)
                    HStack {
                        Image(systemName: self.uploadContainer.information.isPrivate ? "eye.slash.fill" : "eye.slash")
                        Image(systemName: self.uploadContainer.information.isLocked ? "lock.doc.fill" : "lock.doc")
                    }
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)
        }
        .onReceive(NotificationCenter.default.publisher(for: .editUploadInformation)) { output in
            guard let edits = output.object as? IamagesUploadInformationEdits else {
                #if DEBUG
                print("Couldn't find any changes.")
                #endif
                return
            }
            if edits.id != self.uploadContainer.id { return }
            for edit in edits.list {
                switch edit.change {
                case .description:
                    switch edit.to {
                    case .string(let description):
                        self.uploadContainer.information.description = description
                    default:
                        break
                    }
                case .isPrivate:
                    switch edit.to {
                    case .bool(let isPrivate):
                        self.uploadContainer.information.isPrivate = isPrivate
                    default:
                        break
                    }
                case .isLocked:
                    switch edit.to {
                    case .bool(let isLocked):
                        self.uploadContainer.information.isLocked = isLocked
                        if !isLocked {
                            self.uploadContainer.information.lockKey = nil
                        }
                    default:
                        break
                    }
                case .lockKey:
                    switch edit.to {
                    case .string(let lockKey):
                        if lockKey.isEmpty {
                            self.uploadContainer.information.lockKey = nil
                        } else {
                            self.uploadContainer.information.lockKey = lockKey
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
}

#if DEBUG
struct NavigableUploadInformationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigableUploadContainerView(
            uploadContainer: .constant(previewUploadContainer)
        )
    }
}
#endif
