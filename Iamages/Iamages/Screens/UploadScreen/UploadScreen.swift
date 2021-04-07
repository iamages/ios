import SwiftUI
import PhotosUI

struct UploadScreen: View {
    @State var isPhotosPickerPresented: Bool = false
    @State var isUploadedFilesSheetPresented: Bool = false

    @State var pickedFileInformation: [IamagesUploadRequest] = []
    @State var uploadedFilesInformation: [IamagesUploadRequest] = []

    var pickerConfig: PHPickerConfiguration {
       var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 0
        return config
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(self.pickedFileInformation) { file in
                        NavigationLink(destination: UploadEditInformationScreen(file: file, pickedFileInformation: self.$pickedFileInformation), label: {
                            GroupBox(label: Text(verbatim: file.description)) {
                                Image(uiImage: file.img)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(4)
                            }
                        })
                    }
                }.padding(.horizontal)
                .padding(.vertical)
            }.navigationBarTitle("Upload")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.isPhotosPickerPresented = true
                    }) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                    }.sheet(isPresented: self.$isPhotosPickerPresented) {
                        PhotoPickerComponent(configuration: self.pickerConfig,
                                             pickerResultInformation: self.$pickedFileInformation,
                                             isPhotosPickerPresented: self.$isPhotosPickerPresented)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isUploadedFilesSheetPresented = true
                    }) {
                        Image(systemName: "square.and.arrow.up.on.square")
                    }.fullScreenCover(isPresented: self.$isUploadedFilesSheetPresented, onDismiss: {
                        if self.uploadedFilesInformation.count > 0 {
                            for uploadedFileInformation in self.uploadedFilesInformation {
                                self.pickedFileInformation.remove(at: self.pickedFileInformation.firstIndex(of: uploadedFileInformation)!)
                            }
                        }
                    }) {
                        UploadedFilesCover(pickedFileInformation: self.$pickedFileInformation, uploadedFilesInformation: self.$uploadedFilesInformation, isUploadedFilesCoverPresented: self.$isUploadedFilesSheetPresented)
                    }
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct UploadScreen_Previews: PreviewProvider {
    static var previews: some View {
        UploadScreen()
    }
}
