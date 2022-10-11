import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var informations: [IamagesUploadInformation] = []
    @State private var images: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if self.images.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.folder")
                            .font(.largeTitle)
                        Text("No images added")
                            .font(.title2)
                            .bold()
                    }
                } else {
                    List(self.$informations) { information in
                        
                    }
                }
            }
            .navigationTitle("Upload")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.viewModel.isUploadDetailVisible = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .keyboardShortcut("w", modifiers: .command)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(self.images.isEmpty)
                }
                #endif
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: self.$images, matching: .images) {
                        Label("Choose photos", systemImage: "rectangle.stack.badge.plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button(action: {
                            
                        }) {
                            Label("Upload separately", systemImage: "square.and.arrow.up.on.square")
                        }
                        Button(action: {
                            
                        }) {
                            Label("Upload into collection", systemImage: "square.grid.3x1.folder.badge.plus")
                        }
                    } label: {
                        Label("Upload", systemImage: "square.and.arrow.up.on.square")
                    }
                    .disabled(self.images.isEmpty)
                }
            }
        }
    }
}

#if DEBUG
struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
            .environmentObject(ViewModel())
    }
}
#endif
