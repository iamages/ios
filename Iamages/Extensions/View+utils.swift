import SwiftUI
import WelcomeSheet

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

struct IntrospectingFeedListModifier: ViewModifier {
    @Binding var isThirdPanePresented: Bool
    
    func body(content: Content) -> some View {
        if self.isThirdPanePresented {
            content
                .background {
                    // Weird conditions because Mac Catalyst and iPad split view/slide over.
                    if UIDevice.current.userInterfaceIdiom == .pad || (UIDevice.current.userInterfaceIdiom == .pad && UIApplication.shared.connectedScenes.flatMap{($0 as? UIWindowScene)?.windows ?? []}.first{$0.isKeyWindow}?.frame == UIScreen.main.bounds) {
                        NavigationLink(destination: RemovedSuggestView(), isActive: self.$isThirdPanePresented) {
                            EmptyView()
                        }
                    }
                }
        } else {
            content
        }
    }
}

struct AppWelcomeSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .welcomeSheet(isPresented: self.$isPresented, isSlideToDismissDisabled: true, pages: [
                WelcomeSheetPage(
                    title: "Welcome to Iamages!",
                    rows: [
                        WelcomeSheetPageRow(
                            imageSystemName: "newspaper",
                            title: "Public feeds",
                            content: "View images uploaded by others."
                        ),
                        WelcomeSheetPageRow(
                            imageSystemName: "magnifyingglass",
                            title: "Search",
                            content: "Search for files, collections and users."
                        ),
                        WelcomeSheetPageRow(
                            imageSystemName: "square.and.arrow.up.on.square",
                            title: "Upload",
                            content: "Upload new files anonymously or to your user."
                        ),
                        WelcomeSheetPageRow(
                            imageSystemName: "person",
                            title: "You",
                            content: "View your files nad manage your account."
                        )
                    ],
                    mainButtonTitle: "Let's go!"
                )
            ])
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
    func listAndDetailViewFix(isThirdPanePresented: Binding<Bool>) -> some View {
        modifier(IntrospectingFeedListModifier(isThirdPanePresented: isThirdPanePresented))
    }
    func appWelcomeSheet(isPresented: Binding<Bool>) -> some View {
        modifier(AppWelcomeSheetModifier(isPresented: isPresented))
    }
}
