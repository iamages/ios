import SwiftUI

struct ModifyUploadRequestView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var uploadRequest: UploadFileRequest
    
    var body: some View {
        Form {
            Section("Description") {
                TextField("", text: self.$uploadRequest.info.description)
            }
            Section("Options") {
                Toggle("NSFW", isOn: self.$uploadRequest.info.isNSFW)
                Toggle("Private", isOn: self.$uploadRequest.info.isPrivate)
                    .disabled(!self.dataObservable.isLoggedIn)
                Toggle("Hidden", isOn: self.$uploadRequest.info.isHidden)
            }
        }
        .navigationTitle(uploadRequest.info.description)
    }
}
