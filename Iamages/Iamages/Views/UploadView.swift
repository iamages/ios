import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @AppStorage("uploadDefaults.isNSFW") var isNSFWDefault: Bool = false
    @AppStorage("uploadDefaults.isHidden") var isHiddenDefault: Bool = false
    @AppStorage("uploadDefaults.isPrivate") var isPrivateDefault: Bool = false
    
    @State var isPhotoPickerPresented: Bool = false
    @State var isFilePickerPresented: Bool = false
    @State var isURLPickerPresented: Bool = false
    @State var isUploadSheetPresented: Bool = false
    
    @State var pickedURL: URL?
    @State var pickedImages: [Data] = []
    @State var rawPickerResultLength: Int = 0
    
    @State var pickErrorAlertText: String?
    @State var isPickErrorAlertPresented: Bool = false
    
    @State var uploadRequests: [UploadFileRequest] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.$uploadRequests) { uploadRequest in
                    NavigableModifyUploadRequestView(uploadRequest: uploadRequest, uploadRequests: self.$uploadRequests)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu(content: {
                        Button(action: {
                            self.isPhotoPickerPresented = true
                        }) {
                            Label("Select photos", systemImage: "photo.on.rectangle")
                        }
                        Button(action: {
                            self.isFilePickerPresented = true
                        }) {
                            Label("Select files", systemImage: "doc")
                        }
                        Button(action: {
                            self.isURLPickerPresented = true
                        }) {
                            Label("Save from URLs", systemImage: "externaldrive.badge.icloud")
                        }
                    }) {
                        Label("Select", systemImage: "rectangle.stack.badge.plus")
                    }
                    .menuStyle(.borderlessButton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isUploadSheetPresented = true
                    }) {
                        Label("Upload", systemImage: "square.and.arrow.up.on.square")
                    }
                    .disabled(self.uploadRequests.isEmpty)
                }
            }
            .sheet(isPresented: self.$isPhotoPickerPresented) {
                PhotosPickerView(imageRetrievedHandler: { image, type in
                    self.uploadRequests.append(
                        UploadFileRequest(
                            info: UploadJSONRequest(
                                description: "No description yet.",
                                isNSFW: self.isNSFWDefault,
                                isPrivate: self.isPrivateDefault,
                                isHidden: self.isHiddenDefault,
                                url: nil
                            ),
                            file: UploadFile(
                                image: image,
                                type: UTType(type)!
                            )
                        )
                    )
                }, isPresented: self.$isPhotoPickerPresented)
            }
            .onChange(of: self.pickedImages) { _ in
                if self.pickedImages.count == self.rawPickerResultLength {
                    self.isPhotoPickerPresented = false
                }
            }
            .fileImporter(
                isPresented: self.$isFilePickerPresented,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                    case .success(let urls):
                    do {
                        for url in urls {
                            let image = try Data(contentsOf: url)
                            self.uploadRequests.append(
                                UploadFileRequest(
                                    info: UploadJSONRequest(
                                        description: "No description yet.",
                                        isNSFW: self.isNSFWDefault,
                                        isPrivate: self.isPrivateDefault,
                                        isHidden: self.isHiddenDefault,
                                        url: nil
                                    ),
                                    file: UploadFile(
                                        image: image,
                                        type: UTType(filenameExtension: url.pathExtension)!
                                    )
                                )
                            )
                        }
                    } catch {
                        print(error)
                    }
                    case .failure(let error):
                    self.pickErrorAlertText = error.localizedDescription
                    self.isPickErrorAlertPresented = true
                }
            }
            .sheet(isPresented: self.$isURLPickerPresented, onDismiss: {
                if self.pickedURL != nil {
                    self.uploadRequests.append(
                        UploadFileRequest(
                            info: UploadJSONRequest(
                                description: "No description yet",
                                isNSFW: self.isNSFWDefault,
                                isPrivate: self.isPrivateDefault,
                                isHidden: self.isHiddenDefault,
                                url: self.pickedURL!
                            ),
                            file: nil
                        )
                    )
                }
            }) {
                URLPickerView(pickedURL: self.$pickedURL, isPresented: self.$isURLPickerPresented)
            }
            .sheet(isPresented: self.$isUploadSheetPresented) {
                UploadingView(uploadRequests: self.$uploadRequests, isPresented: self.$isUploadSheetPresented)
            }
            .navigationTitle("Upload")
        }
    }
}
