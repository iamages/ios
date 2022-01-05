import SwiftUI
import UniformTypeIdentifiers

struct FileInfoView: View {
    @Binding var file: IamagesFile
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section("Description") {
                    Text(verbatim: self.file.description)
                }
                Section("Options") {
                    Group {
                        Toggle(isOn: self.$file.isNSFW) {
                            Text("NSFW")
                        }
                        Toggle(isOn: self.$file.isPrivate) {
                            Text("Private")
                        }
                        Toggle(isOn: self.$file.isHidden) {
                            Text("Hidden")
                        }
                    }
                    .disabled(true)
                }
                if let relativeTimeString = Formatter.localRelativeTime.string(for: self.file.created) {
                    Section("Created") {
                        Text(relativeTimeString.capitalized)
                    }
                }
                Section("Image") {
                    HStack {
                        Text("Resolution")
                        Spacer()
                        Text("\(self.file.width)x\(self.file.height)")
                            .bold()
                    }
                    if let mimeDescription = UTType(mimeType: self.file.mime)?.localizedDescription {
                        HStack {
                            Text("Type")
                            Spacer()
                            Text(mimeDescription)
                                .bold()
                        }
                    }
                }
                if let owner = self.file.owner {
                    Section("Owner") {
                        HStack {
                            ProfileImageView(username: owner)
                            Text(verbatim: owner)
                        }
                    }
                }
                if let views = self.file.views {
                    Section("Views") {
                        Text(String(views))
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
