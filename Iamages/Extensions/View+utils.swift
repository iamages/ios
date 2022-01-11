#if targetEnvironment(macCatalyst)
import SwiftUI

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
}
#endif

struct CustomBindingAlertModifier: ViewModifier {
    let title: String
    @Binding var message: String?
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .alert(self.title, isPresented: self.$isPresented, actions: {}, message: {
                Text(message ?? "Unknown message.")
            })
    }
}

struct CustomFixedAlertModifier: ViewModifier {
    let title: String
    let message: String
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .alert(self.title, isPresented: self.$isPresented, actions: {}, message: {
                Text(message)
            })
    }
}

struct CustomSheetModifier<V>: ViewModifier where V: View {
    @EnvironmentObject var dataObservable: APIDataObservable

    var isPresented: Binding<Bool>
    let view: () -> V
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.isPresented, onDismiss: {
                self.dataObservable.isModalPresented = false
            }) {
                self.view()
                    .onAppear {
                        self.dataObservable.isModalPresented = true
                    }
            }
    }
}

extension View {
    func customBindingAlert(title: String, message: Binding<String?>, isPresented: Binding<Bool>) -> some View {
        modifier(CustomBindingAlertModifier(title: title, message: message, isPresented: isPresented))
    }
    func customFixedAlert(title: String, message: String, isPresented: Binding<Bool>) -> some View {
        modifier(CustomFixedAlertModifier(title: title, message: message, isPresented: isPresented))
    }
    func customSheet<V>(isPresented: Binding<Bool>, view: @escaping () -> V) -> some View where V: View {
        modifier(CustomSheetModifier(isPresented: isPresented, view: view))
    }
}
