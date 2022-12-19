import SwiftUI
import AlertToast

#if targetEnvironment(macCatalyst)
// Thanks to Stack Overflow!
struct HostingWindowFinder: UIViewRepresentable {
    var callback: (UIWindow?) -> ()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
    
    func hideMacTitlebar() -> some View {
        self.withHostingWindow { window in
            if let titlebar = window?.windowScene?.titlebar {
                titlebar.titleVisibility = .hidden
            }
        }
    }
}
#endif

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

struct ErrorToast: ViewModifier {
    @Binding var error: LocalizedAlertError?
    
    func body(content: Content) -> some View {
        content
            .toast(isPresenting: .constant(error != nil), duration: 10, tapToDismiss: false) {
                AlertToast(
                    displayMode: .banner(.pop),
                    type: .error(.red),
                    title: self.error?.localizedDescription,
                    subTitle: self.error?.recoverySuggestion
                )
            } onTap: {
                self.error = nil
            }
    }
}

extension View {
    func errorToast(error: Binding<LocalizedAlertError?>) -> some View {
        modifier(ErrorToast(error: error))
    }
}

struct ConfirmCancelDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var isSheetPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Leave without saving?",
                isPresented: self.$isPresented,
                titleVisibility: .visible
            ) {
                Button("Leave", role: .destructive) {
                    self.isSheetPresented = false
                }
            } message: {
                Text("The changes you have made will not be saved.")
            }
    }
}

extension View {
    func confirmCancelDialog(
        isPresented: Binding<Bool>,
        isSheetPresented: Binding<Bool>
    ) -> some View {
        modifier(
            ConfirmCancelDialogModifier(
                isPresented: isPresented,
                isSheetPresented: isSheetPresented
            )
        )
    }
}
