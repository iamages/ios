import SwiftUI

struct UploadEditorView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    #if !targetEnvironment(macCatalyst)
    @Binding var isPresented: Bool
    #endif
    @Binding var selectedUploadContainer: IamagesUploadContainer?
    
    @State private var description: String = ""
    @State private var isPrivate: Bool = false
    @State private var isLocked: Bool = false
    @State private var lockKey: String = ""
    
    var body: some View {
        Group {
            if let selectedUploadContainer {
                Form {
                    Section("Description") {
                        TextField("Description", text: self.$description)
                    }
                    Section {
                        Toggle("Private", isOn: self.$isPrivate)
                            .disabled(!self.globalViewModel.isLoggedIn)
                        Toggle("Lock", isOn: self.$isLocked)
                            .onChange(of: self.isLocked) { _ in
                                self.lockKey = ""
                            }
                        if self.isLocked {
                            SecureField("Password", text: self.$lockKey)
                        }
                    } header: {
                        Text("Ownership")
                    } footer: {
                        if self.isLocked {
                            Text("Locked images are encrypted in the cloud using your provided password. These features will be disabled:\n· Thumbnail in images list\n· Social media embed cards.\n· Local image cache.\nYou will have to unlock locked images manually everytime you open the app. People who receive your public link also need a password to decrypt the image. You cannot reverse the encryption process.")
                        }
                    }
                }
                .formStyle(.grouped)
                .navigationTitle("Editor")
                .onAppear {
                    self.description = selectedUploadContainer.information.description
                    self.isPrivate = selectedUploadContainer.information.isPrivate
                    self.isLocked = selectedUploadContainer.information.isLocked
                    if let lockKey = selectedUploadContainer.information.lockKey {
                        self.lockKey = lockKey
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Discard", role: .destructive) {
                            self.selectedUploadContainer = nil
                        }
                    }
                    ToolbarItem {
                        Button("Save") {
                            var edits = IamagesUploadInformationEdits(id: selectedUploadContainer.id)
                            if self.description != selectedUploadContainer.information.description {
                                edits.list.append(
                                    .init(change: .description, to: .string(self.description))
                                )
                            }
                            if self.isPrivate != selectedUploadContainer.information.isPrivate {
                                edits.list.append(
                                    .init(change: .isPrivate, to: .bool(self.isPrivate))
                                )
                            }
                            if self.isLocked != selectedUploadContainer.information.isLocked {
                                edits.list.append(.init(change: .isLocked, to: .bool(self.isLocked)))
                                if self.isLocked {
                                    edits.list.append(.init(change: .lockKey, to: .string(self.lockKey)))
                                }
                            }
                            NotificationCenter.default.post(name: .editUploadInformation, object: edits)
                            self.selectedUploadContainer = nil
                        }
                        .disabled(self.isLocked && self.lockKey.isEmpty)
                    }
                }
            } else {
                Text("Select an upload to edit it")
                    .navigationTitle("")
            }
        }
        .toolbar {
            #if !targetEnvironment(macCatalyst)
            ToolbarItem(placement: .primaryAction) {
                if self.horizontalSizeClass == .regular {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                    .keyboardShortcut("w")
                }
            }
            #endif
        }
    }
}

#if DEBUG
struct UploadEditorView_Previews: PreviewProvider {
    static var previews: some View {
        #if targetEnvironment(macCatalyst)
        UploadEditorView(
            selectedUploadContainer: .constant(previewUploadContainer)
        )
        .environmentObject(GlobalViewModel())
        #else
        UploadEditorView(
            isPresented: .constant(true),
            selectedUploadContainer: .constant(previewUploadContainer)
        )
        .environmentObject(GlobalViewModel())
        #endif
    }
}
#endif
