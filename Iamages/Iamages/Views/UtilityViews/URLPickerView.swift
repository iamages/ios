import SwiftUI

struct URLPickerView: View {
    @Binding var pickedURL: URL?
    @Binding var isPresented: Bool
    
    @State var inputURL: String = ""

    @State var isURLInvalidErrorAlertPresented: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("URL") {
                    TextField("URL", text: self.$inputURL)
                }
                Section("Preview") {
                    AsyncImage(url: URL(string: self.inputURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else if phase.error != nil {
                            Label(phase.error!.localizedDescription, systemImage: "exclamationmark.triangle")
                        } else {
                            ProgressView()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.pickedURL = nil
                        self.isPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let url = URL(string: self.inputURL) {
                            self.pickedURL = url
                            self.isPresented = false
                        } else {
                            self.isURLInvalidErrorAlertPresented = true
                        }
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .alert("Invalid URL", isPresented: self.$isURLInvalidErrorAlertPresented, actions: {}, message: {
                Text("The provided URL is invalid. Please recheck it.")
            })
            .navigationTitle("Pick URL")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
