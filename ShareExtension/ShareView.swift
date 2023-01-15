import SwiftUI
import KeychainAccess

struct ShareView: View {
    private enum Field {
        case description
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.extensionContext) private var extensionContext
    
    @StateObject private var uploadModel = UploadViewModel()
    @StateObject private var coreDataModel = CoreDataModel()

    @FocusState private var focusedField: Field?
    @State private var isLoggedIn: Bool = false
    
    private func dismiss() {
        self.extensionContext!.completeRequest(returningItems: nil)
    }
    
    private func upload() async {
        await self.uploadModel.upload()
        if self.uploadModel.error == nil && !self.uploadModel.isUploading {
            self.dismiss()
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Description", text: self.$uploadModel.information.description, axis: .vertical)
                            .lineLimit(2)
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
                    Toggle("Locked", isOn: self.$uploadModel.information.isLocked)
                    if self.uploadModel.information.isLocked {
                        SecureField("Lock key", text: self.$uploadModel.information.lockKey)
                    }
                } header: {
                    Text("Ownership")
                } footer: {
                    if !self.isLoggedIn {
                        Text("Log in to an account in the app to privatize your photos.")
                    }
                }
            }
            .navigationTitle("Share to Iamages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: self.dismiss)
                        .keyboardShortcut(.escape)
                        .disabled(self.uploadModel.isUploading)
                        .tint(self.uploadModel.information.description.isEmpty ? .none : .red)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Upload") {
                        Task {
                            await self.upload()
                        }
                    }
                    .disabled(self.uploadModel.file == nil || self.uploadModel.isUploading)
                }
                ToolbarItem(placement: .principal) {
                    if self.uploadModel.isUploading {
                        ProgressView(value: self.uploadModel.progress, total: 100.0)
                    }
                }
            }
        }
        .tint(.orange)
        .errorAlert(error: self.$uploadModel.error)
        .onChange(of: self.uploadModel.information.isLocked) { _ in
            self.uploadModel.information.lockKey = ""
        }
        .onAppear {
            self.uploadModel.viewContext = self.coreDataModel.container.viewContext
            self.focusedField = .description
            self.isLoggedIn = self.uploadModel.checkLoggedIn()
        }
        // Refresh isLoggedIn on focus, in case user logs in somewhere else.
        // Wish there was a better solution for this.
        .onChange(of: self.scenePhase) { phase in
            if phase == .active {
                self.isLoggedIn = self.uploadModel.checkLoggedIn()
                if !self.isLoggedIn {
                    self.uploadModel.information.isPrivate = false
                }
            }
        }
        .onAppear {
            guard let itemProvider = (self.extensionContext!.inputItems.first as? NSExtensionItem)?.attachments?.first,
                  let contentType = itemProvider.registeredContentTypes.first else {
                self.uploadModel.error = LocalizedAlertError(error: NoImageDataError())
                return
            }
            itemProvider.loadDataRepresentation(for: contentType) { data, error in
                DispatchQueue.main.async {
                    if let error {
                        self.uploadModel.error = LocalizedAlertError(error: error)
                        return
                    }
                    guard let data else {
                        self.uploadModel.error = LocalizedAlertError(error: error)
                        return
                    }
                    self.uploadModel.file = IamagesUploadFile(
                        data: data,
                        type: contentType.preferredMIMEType!
                    )
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
