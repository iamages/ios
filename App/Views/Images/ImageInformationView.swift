import SwiftUI

struct ImageInformationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var splitViewModel: SplitViewModel
    
    private func copyID() {
        UIPasteboard.general.string = self.splitViewModel.selectedImage?.id
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let image = self.splitViewModel.selectedImage {
                    Form {
                        if let metadata = self.splitViewModel.selectedImageMetadata?.data {
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
                            Button(action: self.copyID) {
                                HStack {
                                    Text(image.id)
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                        }
                    }
                    .formStyle(.grouped)
                } else {
                    Text("Select an image")
                }
            }
            .navigationTitle("Image information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.dismiss()
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .keyboardShortcut(.escape)
                }
            }
        }
    }
}

#if DEBUG
struct ImageInformationView_Previews: PreviewProvider {
    static var previews: some View {
        ImageInformationView(
            splitViewModel: SplitViewModel()
        )
    }
}
#endif
