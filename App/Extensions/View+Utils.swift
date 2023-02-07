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
