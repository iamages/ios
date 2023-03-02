import SwiftUI
import KeychainAccess

struct ShareView: View {
    private enum Field {
        case description
        case lockKey
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.extensionContext) private var extensionContext

    @AppStorage("uploadDefaults.isPrivate", store: .iamagesGroup)
    private var isPrivateDefault: Bool = false
    
    @AppStorage("uploadDefaults.isLocked", store: .iamagesGroup)
    private var isLockedDefault: Bool = false
    
    @StateObject private var uploadModel = UploadViewModel()
    @StateObject private var coreDataModel = CoreDataModel()

    @FocusState private var focusedField: Field?
    @State private var isLoggedIn: Bool = false
    @State private var isCancelAlertPresented = false
    @State private var isBusy: Bool = true
    
    private func dismiss() {
        self.extensionContext!.completeRequest(returningItems: nil)
    }
    
    private func upload() async {
        self.focusedField = nil
        await self.uploadModel.upload()
        if self.uploadModel.error == nil {
            self.dismiss()
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Description", text: self.$uploadModel.information.description)
                            .focused(self.$focusedField, equals: .description)
                        Spacer()
                        Group {
                            if let data = self.uploadModel.file?.data {
                                Image(uiImage: UIImage(data: data)!)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(width: 64, height: 64)
                    }
                }
                Section {
                    Toggle("Private", isOn: self.$uploadModel.information.isPrivate)
                        .disabled(!self.isLoggedIn)
                    Toggle("Lock (Beta)", isOn: self.$uploadModel.information.isLocked)
                    if self.uploadModel.information.isLocked {
                        SecureField("Lock key", text: self.$uploadModel.information.lockKey)
                            .focused(self.$focusedField, equals: .lockKey)
                    }
                } header: {
                    Text("Ownership")
                } footer: {
                    UploadOwnershipFooter(
                        isLoggedIn: self.isLoggedIn,
                        isLocked: self.uploadModel.information.isLocked
                    )
                }
            }
            .navigationTitle("Share to Iamages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !self.uploadModel.information.description.isEmpty ||
                            self.uploadModel.information.isPrivate ||
                            self.uploadModel.information.isLocked
                        {
                            self.isCancelAlertPresented = true
                        } else {
                            self.dismiss()
                        }
                    }
                    .keyboardShortcut(.escape)
                    .disabled(self.uploadModel.isUploading || self.isBusy)
                    .confirmationDialog(
                        "Leave without uploading?",
                        isPresented: self.$isCancelAlertPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Leave", role: .destructive) {
                            self.dismiss()
                        }
                    } message: {
                        Text("This image will not be uploaded.")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Upload") {
                        Task {
                            await self.upload()
                        }
                    }
                    .disabled(self.uploadModel.file == nil || self.uploadModel.isUploading || self.isBusy)
                }
                ToolbarItem(placement: .principal) {
                    if self.uploadModel.isUploading {
                        ProgressView(value: self.uploadModel.progress, total: 100.0)
                    } else if self.isBusy {
                        ProgressView()
                    }
                }
            }
        }
        .tint(.orange)
        .interactiveDismissDisabled()
        .errorAlert(error: self.$uploadModel.error)
        .onChange(of: self.uploadModel.information.isLocked) { isLocked in
            self.uploadModel.information.lockKey = ""
            if isLocked {
                self.focusedField = .lockKey
            } else {
                self.focusedField = .description
            }
        }
        // Refresh isLoggedIn on focus, in case user logs in somewhere else.
        // Wish there was a better solution for this.
        .onChange(of: self.scenePhase) { phase in
            if phase == .active {
                self.isBusy = true
                self.isLoggedIn = self.uploadModel.checkLoggedIn()
                if !self.isLoggedIn {
                    self.uploadModel.information.isPrivate = false
                }
                self.isBusy = false
            }
        }
        .onAppear {
            self.uploadModel.viewContext = self.coreDataModel.container.viewContext
            self.focusedField = .description
            self.isLoggedIn = self.uploadModel.checkLoggedIn()

            guard let itemProvider = (self.extensionContext!.inputItems.first as? NSExtensionItem)?.attachments?.first,
                  let contentType = itemProvider.registeredContentTypes.first else {
                self.uploadModel.error = LocalizedAlertError(error: NoImageDataError())
                return
            }
            itemProvider.loadDataRepresentation(for: contentType) { data, error in
                DispatchQueue.main.async {
                    if let error {
                        self.uploadModel.error = LocalizedAlertError(error: error)
                        self.isBusy = false
                        return
                    }
                    guard let data else {
                        self.uploadModel.error = LocalizedAlertError(error: error)
                        self.isBusy = false
                        return
                    }
                    self.uploadModel.file = IamagesUploadFile(
                        data: data,
                        type: contentType.preferredMIMEType!
                    )
                    self.uploadModel.information.isPrivate = self.isPrivateDefault
                    self.uploadModel.information.isLocked = self.isLockedDefault
                    self.isBusy = false
                }
            }
        }
    }
}

#if DEBUG
struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView()
    }
}
#endif
