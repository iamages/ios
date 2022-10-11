import SwiftUI

struct ErrorAlert: ViewModifier {
    @Binding var error: LocalizedAlertError?
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: .constant(error != nil), error: self.error, actions: { _ in
                // iOS 16.0: OS-provided OK button no longer sets error to nil automatically.
                // We have to set it to nil ourselves with this 'custom' button.
                Button("OK", role: .cancel) {
                    self.error = nil
                }
            }) { error in
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                }
            }
    }
}

extension View {
    func errorAlert(error: Binding<LocalizedAlertError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}
