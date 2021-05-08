import SwiftUI
import Kingfisher

struct UploadedFilesCover: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    @AppStorage("PreferredUploadFormat") var preferredUploadFormat: String = "png"
    @Binding var pickedFileInformation: [IamagesUploadRequest]
    @Binding var uploadedFilesInformation: [IamagesUploadRequest]
    @Binding var isUploadedFilesCoverPresented: Bool
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if self.isBusy {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isUploadedFilesCoverPresented = false
                    }) {
                        Image(systemName: "xmark")
                    }.disabled(self.isBusy)
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
                                uploadedFilesInformation.append(file)
                                self.isBusy = false
                            }).catch({ error in
                                self.isBusy = false
                                self.alertItem = AlertItem(title: Text("Upload failed"), message: Text("'\(file.description)': \(error.localizedDescription)"), dismissButton: .default(Text("Okay")))
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
    @State static var uploadedFilesInformation: [IamagesUploadRequest] = []
    @State static var isUploadedFilesCoverPresented: Bool = false
    static var previews: some View {
        UploadedFilesCover(pickedFileInformation: self.$pickedFileInformation, uploadedFilesInformation: self.$uploadedFilesInformation, isUploadedFilesCoverPresented: self.$isUploadedFilesCoverPresented)
    }
}
