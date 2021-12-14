import SwiftUI
import ImagePickerView

struct UploadView: View {
    @State var isPhotoPickerPresented: Bool = false
    @State var isFilePickerPresented: Bool = false
    @State var isURLPickerPresented: Bool = false
    
    @State var isUploadCoverPresented: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    
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
                        self.isUploadCoverPresented = true
                    }) {
                        Label("Upload", systemImage: "square.and.arrow.up.on.square")
                    }
                }
            }
            .sheet(isPresented: self.$isPhotoPickerPresented) {
                ImagePickerView(filter: .any(of: [.images]), selectionLimit: 0, delegate:
                    ImagePickerView.Delegate(
                        isPresented: self.$isPhotoPickerPresented,
                        didCancel: { _ in },
                        didSelect: { result in
                            
                        },
                        didFail: { error in
                            
                        }
                    )
                )
            }
            .fileImporter(
                isPresented: self.$isFilePickerPresented,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                
            }
            .sheet(isPresented: self.$isURLPickerPresented) {
                
            }
            .fullScreenCover(isPresented: self.$isUploadCoverPresented) {
                
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
