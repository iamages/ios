import SwiftUI

struct NewCollectionView: View {
    @EnvironmentObject private var globalViewModel: GlobalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCollection: NewIamagesCollection = NewIamagesCollection(
        isPrivate: false,
        description: ""
    )
    @State private var error: LocalizedAlertError?
    
    @FocusState private var isDescriptionFieldFocused: Bool
    @State private var isBusy: Bool = false
    @State private var isSuccessPresented: Bool = false
    
    private func create() async {
        do {
            try await self.globalViewModel.fetchData(
                "/collections/",
                method: .post,
                body: self.globalViewModel.jsone.encode(self.newCollection),
                contentType: .json,
                authStrategy: .required
            )
            self.isSuccessPresented = true
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
    @ViewBuilder
    private var success: some View {
        IconAndInformationView(
            icon: "checkmark",
            heading: "Collection created",
            subheading: "Add images to this collection by selecting them and using the toolbar button"
        )
        .padding()
        .navigationBarBackButtonHidden()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(3))) {
                self.dismiss()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Description") {
                    TextField("Description", text: self.$newCollection.description)
                        .focused(self.$isDescriptionFieldFocused)
                }
                Section("Ownership") {
                    Toggle("Private", isOn: self.$newCollection.isPrivate)
                }
            }
            .errorAlert(error: self.$error)
            .navigationTitle("New collection")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                self.isDescriptionFieldFocused = true
            }
            .navigationDestination(isPresented: self.$isSuccessPresented) {
                self.success
            }
            .toolbar {
                #if !targetEnvironment(macCatalyst)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .destructive) {
                        self.dismiss()
                    }
                    .keyboardShortcut(.escape)
                }
                #endif
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        Task {
                            await self.create()
                        }
                    }
                    .disabled(self.newCollection.description.isEmpty || self.newCollection.description.count > 255)
                }
            }
        }
        .interactiveDismissDisabled(self.isBusy)
        .navigationTitle("New collection")
        #if targetEnvironment(macCatalyst)
        .navigationSubtitle(self.newCollection.description)
        #endif
    }
}

#if DEBUG
struct NewCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        NewCollectionView()
            .environmentObject(GlobalViewModel())
    }
}
#endif
