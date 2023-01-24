import SwiftUI

struct UploadImportErrorsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var errors: [IdentifiableLocalizedError]
    
    var body: some View {
        NavigationStack {
            Group {
                List(self.errors) { error in
                    VStack(alignment: .leading) {
                        Text(error.error.localizedDescription)
                            .bold()
                            .tint(.red)
                        if let recoverySuggestion: String = error.error.recoverySuggestion {
                            Text(recoverySuggestion)
                        }
                    }
                }
            }
            .navigationTitle("Import errors")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        self.errors = []
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        self.dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct UploadImportErrorsView_Previews: PreviewProvider {
    static var previews: some View {
        UploadImportErrorsView(
            errors: .constant([
                IdentifiableLocalizedError(error: FileImportErrors.unsupportedType("test.mov", "video/mov")),
                IdentifiableLocalizedError(error: FileImportErrors.tooLarge("test.jpg", 4000000))
            ])
        )
    }
}
#endif