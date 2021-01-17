import SwiftUI
import Kingfisher

struct UploadedFilesSheet: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @AppStorage("PreferredUploadFormat") var preferredUploadFormat: String = "png"
    @Binding var pickedFileInformation: [IamagesUploadRequest]
    @State var uploadedFiles: [IamagesUploadResponse] = []
    @State private var isBusy: Bool = false
    @State var alertItem: AlertItem?
    var body: some View {
        NavigationView {
            List {
                ForEach(self.uploadedFiles, id: \.self) { uploadedFile in
                    Link(destination: api.get_root_embed(id: uploadedFile.id)) {
                        HStack(alignment: .center) {
                            KFImage(api.get_root_img(id: uploadedFile.id))
                                .requestModifier(dataCentralObservable.userRequestModifier)
                                .resizable()
                                .cancelOnDisappear(true)
                                .placeholder {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.largeTitle)
                                        .opacity(0.3)
                                }
                                .cornerRadius(4)
                                .scaledToFit()
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }.navigationBarTitle("Uploaded files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if self.isBusy {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
            .alert(item: self.$alertItem) { item in
                Alert(title: item.title, message: item.message, dismissButton: item.dismissButton)
            }
            .onAppear {
                DispatchQueue.global(qos: .userInitiated).async {
                    for file in self.pickedFileInformation {
                        print("Uploading: \(file.description)")
                        DispatchQueue.main.async {
                            self.isBusy = true
                            self.dataCentralObservable.uploadFile(information: file, preferredUploadFormat: IamagesUploadableFormats(rawValue: self.preferredUploadFormat) ?? .png).done({ response in
                                print("Uploaded: \(file.description)")
                                uploadedFiles.append(response)
                                self.isBusy = false
                            }).catch({ error in
                                self.isBusy = false
                                self.alertItem = AlertItem(title: Text("Upload failed"), message: Text("'\(file.description)' uploadFailed \(error.localizedDescription)"), dismissButton: .default(Text("Okay")))
                            })
                        }
                    }
                }
            }
        }
    }
}

struct UploadedFilesCover_Previews: PreviewProvider {
    @State static var pickedFileInformation: [IamagesUploadRequest] = []
    static var previews: some View {
        UploadedFilesSheet(pickedFileInformation: self.$pickedFileInformation)
    }
}
