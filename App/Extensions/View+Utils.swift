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

struct LockBetaWarningAlertModifier: ViewModifier {
    @Binding var isLocked: Bool
    let currentIsLocked: Bool

    @State private var isPresented: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: self.isLocked) { isLocked in
                if !currentIsLocked && self.isLocked {
                    self.isPresented = true
                }
            }
            .alert("Enable lock?", isPresented: self.$isPresented) {
                Button("Enable", role: .destructive) {
                    self.isPresented = false
                }
                Button("Disable", role: .cancel) {
                    self.isLocked = false
                    self.isPresented = false
                }
            } message: {
                Text("This feature is currently in beta. We are not responsible for any data loss sustained by continuing.")
            }
    }
}

extension View {
    func lockBetaWarningAlert(
        isLocked: Binding<Bool>,
        currentIsLocked: Bool
    ) -> some View {
        modifier(
            LockBetaWarningAlertModifier(
                isLocked: isLocked,
                currentIsLocked: currentIsLocked
            )
        )
    }
}
