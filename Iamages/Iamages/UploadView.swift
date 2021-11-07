import SwiftUI

struct UploadView: View {
    var main: some View {
        List {
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu(content: {
                    Button(action: {
                        
                    }) {
                        Label("Select photo", systemImage: "photo.on.rectangle")
                    }
                    Button(action: {
                        
                    }) {
                        Label("Save from URL", systemImage: "externaldrive.badge.icloud")
                    }
                }) {
                    Label("Select", systemImage: "rectangle.stack.badge.plus")
                }.menuStyle(.borderlessButton)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    
                }) {
                    Label("Upload", systemImage: "square.and.arrow.up.on.square")
                }
            }
        }
        .navigationTitle("Upload")
    }
    var body: some View {
        #if targetEnvironment(macCatalyst)
        main
        #else
        NavigationView {
            main
        }
        #endif
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
