import SwiftUI

struct ImageDetailsEditInformationScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @Environment(\.presentationMode) var presentationMode

    let file: IamagesFileInformationResponse
    @Binding var newFile: IamagesFileInformationResponse
    @Binding var isPopBackToRoot: Bool
    
    @State var isBusy: Bool = false
    @State var alertItem: AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Description")) {
                TextEditor(text: $newFile.description)
            }
            Section(header: Text("Options")) {
                Toggle(isOn: $newFile.isNSFW, label: {
                    Text("NSFW")
                })
                Toggle(isOn: $newFile.isExcludeSearch) {
                    Text("Exclude from search")
                }
                Toggle(isOn: $newFile.isPrivate, label: {
                    Text("Private")
                })
            }
        }.navigationBarTitle("Edit file information")
        .navigationBarBackButtonHidden(self.isBusy)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.saveNewFile()
                }) {
                    Text("Save")
                }.disabled(self.isBusy)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if self.isBusy {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
            }
        }.alert(item: self.$alertItem) { item in
            Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
        }
    }
    
    func saveNewFile() {
        self.isBusy = true
        var modifications: [IamagesFileModifiable: AnyHashable] = [:]
        if self.file.description != self.newFile.description {
            modifications[.description] = self.newFile.description
        }
        if self.file.isNSFW != self.newFile.isNSFW {
            modifications[.isNSFW] = self.newFile.description
        }
        if self.file.isExcludeSearch != self.newFile.isExcludeSearch {
            modifications[.isExcludeSearch] = self.newFile.isExcludeSearch
        }
        if self.file.isPrivate != self.newFile.isPrivate {
            modifications[.isPrivate] = self.newFile.isPrivate
        }
        if modifications != [:] {
            dataCentralObservable.modifyFile(id: self.file.id, modifications: modifications).done({ yes in
                self.isPopBackToRoot = true
                self.isBusy = false
                self.presentationMode.wrappedValue.dismiss()
            }).catch({ error in
                print(error)
                self.isBusy = false
                self.alertItem = AlertItem(title: Text("Modification failed"), message: Text(verbatim: error.localizedDescription), dismissButton: .default(Text("Okay")))
            })
        } else {
            self.isBusy = false
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditDetailScreen_Previews: PreviewProvider {
    static let file: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!
    @State static var newFile: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!
    @State static var isPopBackToRoot: Bool = false
    static var previews: some View {
        ImageDetailsEditInformationScreen(file: file, newFile: self.$newFile, isPopBackToRoot: self.$isPopBackToRoot)
    }
}
