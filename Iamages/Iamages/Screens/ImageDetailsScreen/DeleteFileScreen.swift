import SwiftUI

struct DeleteFileScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @Environment(\.presentationMode) var presentationMode

    @Binding var newFile: IamagesFileInformationResponse
    @Binding var isPopBackToRoot: Bool
    
    @State var isBusy: Bool = false
    @State var alertItem: AlertItem?
    
    var body: some View {
        VStack(alignment: .center) {
            if self.isBusy {
                ProgressView("Deleting file").progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Delete file \(newFile.description)")
                    .bold()
                    .multilineTextAlignment(.center)
                Text("This is not reversible.")
                    .multilineTextAlignment(.center)
                Divider()
                Button("Delete forever", action: {
                    self.deleteFile()
                }).buttonStyle(CustomConfirmButtonStyle())
                .padding(.vertical)
            }
        }.padding(.all)
        .navigationBarBackButtonHidden(self.isBusy)
        .alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }
    }
    
    func deleteFile() {
        self.isBusy = true
        dataCentralObservable.modifyFile(id: self.newFile.id, modifications: [.deleteFile: true]).done({ yes in
            self.isPopBackToRoot = true
            self.presentationMode.wrappedValue.dismiss()
        }).catch({ error in
            self.alertItem = AlertItem(title: Text("Delete failed"), message: Text(verbatim: error.localizedDescription), dismissButton: .default(Text("Okay")))
            self.isBusy = false
        })
    }
}

struct DeleteFileScreen_Previews: PreviewProvider {
    @State static var newFile: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!
    @State static var isPopBackToRoot: Bool = false
    static var previews: some View {
        DeleteFileScreen(newFile: self.$newFile, isPopBackToRoot: self.$isPopBackToRoot)
    }
}
