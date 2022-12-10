import SwiftUI

struct ImageInformationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var splitViewModel: SplitViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if let image = self.splitViewModel.selectedImage {
                    Form {
                        if let metadata = self.splitViewModel.selectedImageMetadata {
                            Section("Description") {
                                Text(metadata.description)
                                    .textSelection(.enabled)
                            }
                            Section("Image") {
                                LabeledContent("Dimensions", value: "\(metadata.width)x\(metadata.height)")
                                if image.lock.isLocked {
                                    LabeledContent("File type", value: metadata.realContentType?.localizedDescription ?? "Unknown")
                                } else {
                                    LabeledContent("File type", value: image.contentType.localizedDescription ?? "Unknown")
                                }
                            }
                        } else {
                            if image.lock.isLocked {
                                Label("Unlock this file to view its metadata.", systemImage: "lock")
                            } else {
                                LoadingMetadataView()
                            }
                        }
                        Section("Ownership") {
                            LabeledContent("Created on") {
                                Text(image.createdOn, format: .relative(presentation: .numeric))
                            }
                            if let owner = image.owner {
                                LabeledContent("Owner", value: owner)
                            }
                            Toggle("Private", isOn: .constant(image.isPrivate))
                                .disabled(true)
                            Toggle("Locked", isOn: .constant(image.lock.isLocked))
                                .disabled(true)
                        }
                        Section("ID") {
                            Text(image.id)
                                .textSelection(.enabled)
                        }
                    }
                    .formStyle(.grouped)
                    #if targetEnvironment(macCatalyst)
                    .navigationSubtitle(self.splitViewModel.selectedImageTitle)
                    #endif
                } else {
                    Text("Select an image")
                }
            }
            .navigationTitle("Image information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ImageInformationView_Previews: PreviewProvider {
    static var previews: some View {
        ImageInformationView(
            isPresented: .constant(true),
            splitViewModel: SplitViewModel()
        )
    }
}
#endif
