import SwiftUI

struct EditImageInformationView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var imageLockKeySalt: Data?
    @ObservedObject var splitViewModel: SplitViewModel
    
    @State private var description: String = ""
    @State private var isPrivate: Bool = false
    @State private var isLocked: Bool = false
    @State private var newLockKey: String = ""
    @State private var currentLockKey: String = ""
    @State private var isKeyAlertPresented: Bool = false
    
    @State private var isLockBetaWarningAlertPresented: Bool = false
    @State private var isCancelAlertPresented: Bool = false
    @State private var isBusy: Bool = false
    @State private var error: LocalizedAlertError?
    
    @State private var edits: [IamagesImageEdit] = []
    
    func getMetadataLockKey() throws -> Data {
        guard let salt = self.splitViewModel.selectedImageMetadata?.salt else {
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
            if self.isLocked != self.splitViewModel.selectedImage?.lock.isLocked {
                if self.isLocked {
                    var edit = IamagesImageEdit(
                        change: .lock,
                        to: .string(self.newLockKey)
                    )
                    if self.splitViewModel.selectedImage?.lock.isLocked == true {
                        edit.metadataLockKey = try self.getMetadataLockKey()
                        edit.imageLockKey = try self.getImageLockKey()
                    }
                    self.edits.append(edit)
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
            if self.description != self.splitViewModel.selectedImageMetadata?.data.description {
                self.edits.append(
                    IamagesImageEdit(
                        change: .description,
                        to: .string(self.description),
                        metadataLockKey: self.splitViewModel.selectedImage?.lock.isLocked == true ? try self.getMetadataLockKey() : nil
                    )
                )
            }
            for i in self.edits.indices {
                let response = try self.globalViewModel.jsond.decode(
                    IamagesImageEdit.Response.self,
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
                    object: IamagesImageEdit.Notification(id: id, edit: self.edits[i])
                )
            }
            self.dismiss()
        } catch {
            self.error = LocalizedAlertError(error: error)
            self.isBusy = false
        }
    }
    
    func checkHasChanges() -> Bool {
        if self.description != self.splitViewModel.selectedImageMetadata?.data.description ||
            self.isPrivate != self.splitViewModel.selectedImage?.isPrivate ||
            self.isLocked != self.splitViewModel.selectedImage?.lock.isLocked
        {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let image = self.splitViewModel.selectedImage {
                    if let metadata = self.splitViewModel.selectedImageMetadata {
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
                        if image.lock.isLocked {
                            Label("Unlock this file to edit its metadata.", systemImage: "lock")
                        } else {
                            LoadingMetadataView()
                        }
                    }
                    Section {
                        Toggle("Private", isOn: self.$isPrivate)
                        Toggle("Lock (Beta)", isOn: self.$isLocked)
                        if self.isLocked && !image.lock.isLocked {
                            SecureField("Lock key", text: self.$newLockKey)
                        }
                    } header: {
                        Text("Privacy")
                    } footer: {
                        if self.isLocked {
                            if !image.lock.isLocked {
                                Text("Remember this key, as it will be used to unlock this image in the future.\nWe cannot recover locked images.")
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
            .lockBetaWarningAlert(
                isLocked: self.$isLocked,
                isPresented: self.$isLockBetaWarningAlertPresented
            )
            .onChange(of: self.isLocked) { isLocked in
                if isLocked {
                    self.isLockBetaWarningAlertPresented = true
                }
            }
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
                           self.splitViewModel.selectedImage?.lock.isLocked == true {
                            self.isKeyAlertPresented = true
                        } else {
                            Task {
                                await self.applyEdits()
                            }
                        }
                    }
                    .disabled(self.isBusy || (self.isLocked && self.splitViewModel.selectedImage?.lock.isLocked == false && self.newLockKey.isEmpty))
                }
            }
        }
    }
}

#if DEBUG
struct EditImageInformationView_Previews: PreviewProvider {
    static var previews: some View {
        EditImageInformationView(
            imageLockKeySalt: .constant(Data()),
            splitViewModel: SplitViewModel()
        )
        .environmentObject(GlobalViewModel())
    }
}
#endif
