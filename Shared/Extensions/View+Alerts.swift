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

struct ConfirmCancelDialogModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Leave without saving?",
                isPresented: self.$isPresented,
                titleVisibility: .visible
            ) {
                Button("Leave", role: .destructive) {
                    self.dismiss()
                }
            } message: {
                Text("The changes you have made will not be saved.")
            }
    }
}

extension View {
    func confirmCancelDialog(
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            ConfirmCancelDialogModifier(
                isPresented: isPresented
            )
        )
    }
}
