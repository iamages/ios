import SwiftUI

struct ModifyUploadRequestView: View {
    @EnvironmentObject var dataObservable: APIDataObservable
    
    @Binding var uploadRequest: UploadFileRequest
    @Binding var uploadRequests: [UploadFileRequest]
    
    @State var isDeleted: Bool = false
    
    var body: some View {
        if self.isDeleted {
            RemovedSuggestView()
        } else {
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
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        if let position = self.uploadRequests.firstIndex(of: self.uploadRequest) {
                            self.uploadRequests.remove(at: position)
                            self.isDeleted = true
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(uploadRequest.info.description)
        }
    }
}
