import SwiftUI

struct FullInformationScreen: View {
    @Binding var newFile: IamagesFileInformationResponse
    var body: some View {
        Form {
            Section(header: Text("Description")) {
                Text($newFile.description.wrappedValue)
            }
            Section(header: Text("Options")) {
                Toggle(isOn: $newFile.isNSFW) {
                    Text("NSFW")
                }.disabled(true)
                Toggle(isOn: $newFile.isExcludeSearch) {
                    Text("Exclude from search")
                }.disabled(true)
                Toggle(isOn: $newFile.isPrivate) {
                    Text("Private")
                }.disabled(true)
            }
            Section(header: Text("Meta")) {
                HStack {
                    Text("Width")
                    Spacer()
                    Text(verbatim: String($newFile.width.wrappedValue) + "px")
                        .bold()
                }
                HStack {
                    Text("Height")
                    Spacer()
                    Text(verbatim: String($newFile.height.wrappedValue) + "px")
                        .bold()
                }
                HStack {
                    Text("MIME type")
                    Spacer()
                    Text($newFile.mime.wrappedValue)
                        .bold()
                }
                HStack {
                    Text("Creation date")
                    Spacer()
                    Text(verbatim: $newFile.createdDate.wrappedValue)
                        .bold()
                }
            }
        }.navigationBarTitle("File information")
    }
}

struct AdditionalDetailsSheet_Previews: PreviewProvider {
    @State static var newFile: IamagesFileInformationResponse = IamagesFileInformationResponse(JSON: ["FileID": 1, "FileDescription": "Test File", "FileNSFW": false, "FilePrivate": false, "FileMime": "image/jpeg", "FileWidth": 696, "FileHeight": 696, "FileCreatedDate": "2020-12-14 14:40:52"])!
    static var previews: some View {
        FullInformationScreen(newFile: $newFile)
    }
}
