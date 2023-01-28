import SwiftUI

struct EditImageInformationView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var imageAndMetadata: IamagesImageAndMetadataContainer
    @Binding var imageLockKeySalt: Data?
    
    @State private var description: String = ""
    @State private var isPrivate: Bool = false
    @State private var isLocked: Bool = false
    @State private var newLockKey: String = ""
    @State private var currentLockKey: String = ""
    @State private var isKeyAlertPresented: Bool = false

    @State private var isCancelAlertPresented: Bool = false
    @State private var isBusy: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var edits: [IamagesImageEdit] = []
    
    func getMetadataLockKey() throws -> Data {
        guard let salt = self.imageAndMetadata.metadataContainer?.salt else {
            throw NoSaltError()
        }
        return try self.globalViewModel.hashKey(for: self.currentLockKey, salt: salt).hashData()
    }
    
    func getImageLockKey() throws -> Data {
        guard let salt = self.imageLockKeySalt else {
            throw NoSaltError()
        }
        return try self.globalViewModel.hashKey(for: self.currentLockKey, salt: salt).hashData()
    }
    
    private func applyEdits() async {
        self.edits = []
        self.isBusy = true
        do {
            if self.isPrivate != self.imageAndMetadata.image.isPrivate {
                self.edits.append(
                    IamagesImageEdit(
                        change: .isPrivate,
                        to: .bool(self.isPrivate)
                    )
                )
            }
            if self.isLocked != self.imageAndMetadata.image.lock.isLocked {
                if self.isLocked {
                    var edit = IamagesImageEdit(
                        change: .lock,
                        to: .string(self.newLockKey)
                    )
                    if self.imageAndMetadata.image.lock.isLocked == true {
                        edit.metadataLockKey = try self.getMetadataLockKey()
                        edit.imageLockKey = try self.getImageLockKey()
                    }
                    self.edits.append(edit)
                    // Remove cache
                    self.globalViewModel.imageLoadingPipeline.cache.removeCachedData(for: self.globalViewModel.getImageRequest(for: self.imageAndMetadata.image))
                } else {
                    self.edits.append(
                        IamagesImageEdit(
                            change: .lock,
                            to: .bool(false),
                            metadataLockKey: try self.getMetadataLockKey(),
                            imageLockKey: try self.getImageLockKey()
                        )
                    )
                }
            }
            if self.description != self.imageAndMetadata.metadataContainer?.data.description {
                self.edits.append(
                    IamagesImageEdit(
                        change: .description,
                        to: .string(self.description),
                        metadataLockKey: self.imageAndMetadata.image.lock.isLocked == true ? try self.getMetadataLockKey() : nil
                    )
                )
            }
            for edit in self.edits {
                let response = try self.globalViewModel.jsond.decode(
                    IamagesImageEdit.Response.self,
                    from: try await self.globalViewModel.fetchData(
                        "/images/\(self.imageAndMetadata.image.id)",
                        method: .patch,
                        body: self.globalViewModel.jsone.encode(edit),
                        contentType: .json,
                        authStrategy: .required
                    ).0
                )
                if let lockVersion = response.lockVersion {
                    self.imageAndMetadata.image.lock.version = lockVersion
                }
                switch edit.change {
                case .isPrivate:
                    switch edit.to {
                    case .bool(let isPrivate):
                        self.imageAndMetadata.image.isPrivate = isPrivate
                    default:
                        break
                    }
                case .lock:
                    switch edit.to {
                    case .string(_):
                        self.imageAndMetadata.image.lock.isLocked = true
                    case .bool(_):
                        self.imageAndMetadata.image.lock.isLocked = false
                        self.imageAndMetadata.image.lock.version = nil
                    default:
                        break
                    }
                case .description:
                    switch edit.to {
                    case .string(let description):
                        self.imageAndMetadata.metadataContainer?.data.description = description
                    default:
                        break
                    }
                }
            }
            self.dismiss()
        } catch {
            self.error = LocalizedAlertError(error: error)
            self.isBusy = false
        }
    }
    
    func checkHasChanges() -> Bool {
        if self.isPrivate != self.imageAndMetadata.image.isPrivate ||
           self.isLocked != self.imageAndMetadata.image.lock.isLocked
        {
            return true
        }
        if let currentDescription = self.imageAndMetadata.metadataContainer?.data.description,
           currentDescription != self.description
        {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let metadata = self.imageAndMetadata.metadataContainer {
                    Section {
                        TextField("Description", text: self.$description)
                    } header: {
                        Text("Description")
                    } footer: {
                    }
                    .onAppear {
                        self.description = metadata.data.description
                    }
                } else {
                    if self.imageAndMetadata.image.lock.isLocked {
                        Label("Unlock this file to edit its metadata.", systemImage: "lock")
                    } else if self.imageAndMetadata.isLoading {
                        LoadingMetadataView()
                    } else {
                        Text("Metadata not available.")
                    }
                }
                Section {
                    Toggle("Private", isOn: self.$isPrivate)
                    Toggle("Lock (Beta)", isOn: self.$isLocked)
                    if self.isLocked && !self.imageAndMetadata.image.lock.isLocked {
                        SecureField("Lock key", text: self.$newLockKey)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    if self.isLocked {
                        if !self.imageAndMetadata.image.lock.isLocked {
                            Text("Remember this key, as it will be used to unlock this image in the future.\nWe cannot recover locked images.")
                        }
                    } else {
                        if self.imageAndMetadata.image.lock.isLocked {
                            Text("At-rest encryption will be disabled upon disabling the lock option.")
                        }
                    }
                }
                .onAppear {
                    self.isPrivate = self.imageAndMetadata.image.isPrivate
                    self.isLocked = self.imageAndMetadata.image.lock.isLocked
                }
            }
            .errorAlert(error: self.$error)
            .lockBetaWarningAlert(
                isLocked: self.$isLocked,
                currentIsLocked: self.imageAndMetadata.image.lock.isLocked
            )
            .alert("Lock key required", isPresented: self.$isKeyAlertPresented) {
                SecureField("Lock key", text: self.$currentLockKey)
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
                        if self.checkHasChanges() {
                            self.isCancelAlertPresented = true
                        } else {
                            self.dismiss()
                        }
                    }
                    .disabled(self.isBusy)
                    .keyboardShortcut(.escape)
                    .confirmCancelDialog(
                        isPresented: self.$isCancelAlertPresented
                    )
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Save") {
                        if self.checkHasChanges() &&
                           self.imageAndMetadata.image.lock.isLocked
                        {
                            self.isKeyAlertPresented = true
                        } else {
                            Task {
                                await self.applyEdits()
                            }
                        }
                    }
                    .disabled(self.isBusy || (self.isLocked && self.imageAndMetadata.image.lock.isLocked == false && self.newLockKey.isEmpty))
                }
            }
        }
    }
}

#if DEBUG
struct EditImageInformationView_Previews: PreviewProvider {
    static var previews: some View {
        EditImageInformationView(
            imageAndMetadata: .constant(previewImageAndMetadata),
            imageLockKeySalt: .constant(Data())
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
