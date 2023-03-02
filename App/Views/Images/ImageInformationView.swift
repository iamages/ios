import SwiftUI
import AlertToast

struct ImageInformationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer
    
    @State private var isCopiedAlertPresented: Bool = false
    
    private func copyID() {
        UIPasteboard.general.string = self.imageAndMetadata.image.id
        self.isCopiedAlertPresented = true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let metadata = self.imageAndMetadata.metadataContainer?.data {
                    Section("Description") {
                        Text(metadata.description)
                            .textSelection(.enabled)
                    }
                    Section("Image") {
                        LabeledContent("Dimensions", value: "\(metadata.width)x\(metadata.height)")
                        if self.imageAndMetadata.image.lock.isLocked {
                            LabeledContent("File type", value: metadata.realContentType?.localizedDescription ?? "Unknown")
                        } else {
                            LabeledContent("File type", value: self.imageAndMetadata.image.file.contentType.localizedDescription ?? "Unknown")
                        }
                    }
                } else {
                    if self.imageAndMetadata.image.lock.isLocked {
                        Label("Unlock this file to view its metadata.", systemImage: "lock")
                    } else {
                        LoadingMetadataView()
                    }
                }
                Section("Ownership") {
                    LabeledContent("Created on") {
                        Text(self.imageAndMetadata.image.createdOn, format: .relative(presentation: .numeric))
                    }
                    if let owner = self.imageAndMetadata.image.owner {
                        LabeledContent("Owner", value: owner)
                    }
                    Toggle("Private", isOn: .constant(self.imageAndMetadata.image.isPrivate))
                        .disabled(true)
                }
                Section {
                    Toggle("Locked", isOn: .constant(self.imageAndMetadata.image.lock.isLocked))
                        .disabled(true)
                    if self.imageAndMetadata.image.lock.isLocked,
                       let friendlyName = self.imageAndMetadata.image.lock.version?.friendlyName
                    {
                        LabeledContent("Version", value: friendlyName)
                    }
                } header: {
                    Text("Lock")
                } footer: {
                    if self.imageAndMetadata.image.lock.upgradable == true {
                        Text("New lock version available.\nUpgrade by editing this image.")
                    }
                }
                Section("ID") {
                    Button(action: self.copyID) {
                        HStack {
                            Text(self.imageAndMetadata.image.id)
                            Spacer()
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
            .formStyle(.grouped)
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
            .toast(isPresenting: self.$isCopiedAlertPresented, duration: 1.5, alert: {
                AlertToast(
                    displayMode: .alert,
                    type: .systemImage("doc.on.doc", .green),
                    title: "Copied",
                    subTitle: "Image ID"
                )
            })
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

#if DEBUG
struct ImageInformationView_Previews: PreviewProvider {
    static var previews: some View {
        ImageInformationView(
            imageAndMetadata: .constant(previewImageAndMetadata)
        )
    }
}
#endif
