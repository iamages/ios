import SwiftUI

struct EditImageInformationView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel

    @Binding var isPresented: Bool
    @ObservedObject var splitViewModel: SplitViewModel
    
    @State private var description: String = ""
    @State private var isPrivate: Bool = false
    @State private var isLocked: Bool = false
    @State private var key: String = ""
    @State private var isKeyAlertPresented: Bool = false
    
    @State private var isCancelAlertPresented: Bool = false
    @State private var isBusy: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var edits: [IamagesImageEdit] = []
    
    private func applyEdits() async {
        self.edits = []
        self.isBusy = true
        do {
            guard let id = self.splitViewModel.selectedImage?.id else {
                throw NoIDError()
            }
            if self.isPrivate != self.splitViewModel.selectedImage?.isPrivate {
                self.edits.append(
                    IamagesImageEdit(
                        change: .isPrivate,
                        to: .bool(self.isPrivate)
                    )
                )
            }
            if self.isLocked != self.splitViewModel.selectedImage?.lock.isLocked && !self.isLocked {
                if self.isLocked {
                    self.edits.append(
                        IamagesImageEdit(
                            change: .lock,
                            to: .string(self.key)
                        )
                    )
                } else {
                    self.edits.append(
                        IamagesImageEdit(
                            change: .lock,
                            to: .bool(false)
                        )
                    )
                }
            }
            if self.description != self.splitViewModel.selectedImageMetadata?.description {
                self.edits.append(
                    IamagesImageEdit(
                        change: .description,
                        to: .string(self.description)
                    )
                )
            }
            for i in self.edits.indices {
                let response = try self.globalViewModel.jsond.decode(
                    IamagesImageEditResponse.self,
                    from: try await self.globalViewModel.fetchData(
                        "/images/\(id)",
                        method: .patch,
                        body: self.globalViewModel.jsone.encode(self.edits[i]),
                        contentType: .json,
                        authStrategy: .required
                    ).0
                )
                if let lockVersion = response.lockVersion {
                    self.edits[i].lockVersion = lockVersion
                }
                NotificationCenter.default.post(
                    name: .editImage,
                    object: EditImageNotification(id: id, edit: self.edits[i])
                )
            }
            self.isPresented = false
        } catch {
            self.error = LocalizedAlertError(error: error)
            self.isBusy = false
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let image = self.splitViewModel.selectedImage {
                    if let metadata = self.splitViewModel.selectedImageMetadata {
                        Section {
                            TextField("Description", text: self.$description)
                                .disabled(image.lock.isLocked)
                        } header: {
                            Text("Description")
                        } footer: {
                            if image.lock.isLocked {
                                Text("You cannot change the descripion of a locked file.")
                            }
                        }
                        .onAppear {
                            self.description = metadata.description
                        }
                    } else {
                        if image.lock.isLocked {
                            Label("Unlock this file to view its metadata.", systemImage: "lock")
                        } else {
                            LoadingMetadataView()
                        }
                    }
                    Section {
                        Toggle("Private", isOn: self.$isPrivate)
                        Toggle("Lock", isOn: self.$isLocked)
                        if self.isLocked {
                            SecureField("Lock key", text: self.$key)
                        }
                    } header: {
                        Text("Privacy")
                    } footer: {
                        if self.isLocked {
                            if !image.lock.isLocked {
                                Text("Remember this key, as it will be used to unlock this image in the future.\nWe cannot recover locked images.")
                            } else {
                                Text("Do not input anything into lock key if you do not plan in changing your key.")
                            }
                        } else {
                            if image.lock.isLocked {
                                Text("At-rest encryption will be disabled upon disabling the lock option.")
                            }
                        }
                    }
                    .onAppear {
                        self.isPrivate = image.isPrivate
                        self.isLocked = image.lock.isLocked
                    }
                }
            }
            .errorAlert(error: self.$error)
            .alert("Lock key required", isPresented: self.$isKeyAlertPresented) {
                SecureField("Lock key", text: self.$key)
                Button("Unlock", role: .destructive) {
                    Task {
                        await self.applyEdits()
                    }
                }
            } message: {
                Text("To edit this locked image, input your lock key.")
            }
            .navigationTitle("Edit image information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let image = self.splitViewModel.selectedImage {
                            if self.isPrivate != image.isPrivate ||
                               self.isLocked != image.lock.isLocked
                            {
                                self.isCancelAlertPresented = true
                                return
                            }
                            if let metadata = self.splitViewModel.selectedImageMetadata,
                               self.description != metadata.description {
                                self.isCancelAlertPresented = true
                                return
                            }
                            self.isPresented = false
                        } else {
                            self.isPresented = false
                        }
                    }
                    .disabled(self.isBusy)
                    .keyboardShortcut(.escape)
                    .confirmCancelDialog(isPresented: self.$isCancelAlertPresented, isSheetPresented: self.$isPresented)
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Save") {
                        if self.splitViewModel.selectedImage?.lock.isLocked == true {
                            self.isKeyAlertPresented = true
                        } else {
                            Task {
                                await self.applyEdits()
                            }
                        }
                    }
                    .disabled(self.isBusy || (self.isLocked && self.splitViewModel.selectedImage?.lock.isLocked == false && self.key.isEmpty))
                }
            }
        }
    }
}

#if DEBUG
struct EditImageInformationView_Previews: PreviewProvider {
    static var previews: some View {
        EditImageInformationView(
            isPresented: .constant(true),
            splitViewModel: SplitViewModel()
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
