import SwiftUI

struct UploadEditInformationScreen: View {
    @Environment(\.presentationMode) var presentationMode
    let file: IamagesUploadRequest
    @Binding var pickedFileInformation: [IamagesUploadRequest]
    @State var newFile: IamagesUploadRequest = IamagesUploadRequest(description: "", isNSFW: false, isPrivate: false, img: UIImage())

    var body: some View {
        Form {
            Section(header: Text("Description")) {
                TextEditor(text: $newFile.description)
            }
            Section(header: Text("Options"), footer: Text("Private file toggle will only apply if you are logged in.")) {
                Toggle(isOn: $newFile.isNSFW, label: {
                    Text("NSFW")
                })
                Toggle(isOn: $newFile.isPrivate, label: {
                    Text("Private")
                })
            }
        }.navigationBarTitle("Edit file information")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    customBackHandler()
                }) {
                    Image(systemName: "chevron.backward")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    deleteFile()
                }) {
                    Image(systemName: "trash")
                }
            }
        }.onAppear(perform: {
            self.newFile = self.file
        })
    }
    
    func customBackHandler() {
        self.pickedFileInformation[self.pickedFileInformation.firstIndex(of: self.file)!] = self.newFile
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func deleteFile() {
        self.pickedFileInformation.remove(at: self.pickedFileInformation.firstIndex(of: self.file)!)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditInformationScreen_Previews: PreviewProvider {
    static var file: IamagesUploadRequest = IamagesUploadRequest(description: "No description yet", isNSFW: false, isPrivate: false, img: UIImage())
    @State static var pickedFileInformation: [IamagesUploadRequest] = []
    static var previews: some View {
        UploadEditInformationScreen(file: self.file, pickedFileInformation: self.$pickedFileInformation)
    }
}
