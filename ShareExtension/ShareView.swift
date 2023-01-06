import SwiftUI
import KeychainAccess

struct ShareView: View {
    private enum Field {
        case description
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.extensionContext) private var extensionContext
    
    @StateObject private var model = UploadViewModel()

    @FocusState private var focusedField: Field?
    @State private var isLoggedIn: Bool = false
    @State private var error: LocalizedAlertError?
    
    private func dismiss() {
        self.extensionContext!.completeRequest(returningItems: nil)
    }
    
    private func upload() async {
        do {
            try await self.model.upload()
            self.dismiss()
        } catch {
            self.model.isUploading = false
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Description", text: self.$model.information.description, axis: .vertical)
                            .lineLimit(2)
                            .focused(self.$focusedField, equals: .description)
                        Spacer()
                        Group {
                            if let data = self.model.file?.data {
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
                    Toggle("Private", isOn: self.$model.information.isPrivate)
                        .disabled(!self.isLoggedIn)
                    Toggle("Locked", isOn: self.$model.information.isLocked)
                    if self.model.information.isLocked {
                        SecureField("Lock key", text: self.$model.information.lockKey)
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
                        .disabled(self.model.isUploading)
                        .tint(self.model.information.description.isEmpty ? .none : .red)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Upload") {
                        Task {
                            await self.upload()
                        }
                    }
                    .disabled(self.model.file == nil || self.model.isUploading)
                }
                ToolbarItem(placement: .principal) {
                    if self.model.isUploading {
                        ProgressView(value: self.model.progress, total: 100.0)
                    }
                }
            }
        }
        .tint(.orange)
        .errorAlert(error: self.$error)
        .onChange(of: self.model.information.isLocked) { _ in
            self.model.information.lockKey = ""
        }
        .onAppear {
            self.focusedField = .description
            self.isLoggedIn = self.model.checkLoggedIn()
        }
        // Refresh isLoggedIn on focus, in case user logs in somewhere else.
        // Wish there was a better solution for this.
        .onChange(of: self.scenePhase) { phase in
            if phase == .active {
                self.isLoggedIn = self.model.checkLoggedIn()
                if !self.isLoggedIn {
                    self.model.information.isPrivate = false
                }
            }
        }
        .onAppear {
            guard let itemProvider = (self.extensionContext!.inputItems.first as? NSExtensionItem)?.attachments?.first,
                  let contentType = itemProvider.registeredContentTypes.first else {
                self.error = LocalizedAlertError(error: NoImageDataError())
                return
            }
            itemProvider.loadDataRepresentation(for: contentType) { data, error in
                DispatchQueue.main.async {
                    if let error {
                        self.error = LocalizedAlertError(error: error)
                        return
                    }
                    guard let data else {
                        self.error = LocalizedAlertError(error: error)
                        return
                    }
                    self.model.file = IamagesUploadFile(
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
