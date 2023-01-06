import SwiftUI

struct AppWelcomeView: View {
    private enum WelcomeScreens {
        case tos
        case privacy
        #if targetEnvironment(macCatalyst)
        case mac
        #endif
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var path: [WelcomeScreens] = []
    
    private func infoBlock(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                Text(subtitle)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var summary: some View {
        List {
            self.infoBlock(
                icon: "photo.stack",
                title: "View your images",
                subtitle: "Browse the images you have uploaded, and search through them as well."
            )
            self.infoBlock(
                icon: "folder",
                title: "Group images together",
                subtitle: "Use collections to group your images into easily sharable and organized bundles."
            )
            self.infoBlock(
                icon: "square.and.arrow.up.on.square",
                title: "Upload new images",
                subtitle: "Add new memories to your cloud library with a generous 30MB per image size limit."
            )
        }
        .listStyle(.plain)
        .navigationTitle("Welcome to Iamages")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip", role: .destructive) {
                    self.dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Next") {
                    self.path.append(.tos)
                }
            }
        }
    }
    
    @ViewBuilder
    private var tos: some View {
        List {
            self.infoBlock(
                icon: "eyes",
                title: "Nothing illegal, please",
                subtitle: "Anything which may contradict the laws of your country of residence, or international laws should not be uploaded."
            )
            self.infoBlock(
                icon: "person.line.dotted.person",
                title: "Respect others",
                subtitle: "Only share images which you know others want to see. Think twice before sharing something which may hurt them."
            )
            self.infoBlock(
                icon: "scalemass",
                title: "Keep your sizes reasonable",
                subtitle: "There is a maximum limit of 30MB per image. We would love to hold even larger images, but this is to ensure the service can be fairly used by everyone."
            )
        }
        .listStyle(.plain)
        .navigationTitle("Some house rules")
        .toolbar {
            ToolbarItem {
                Button("Agree") {
                    self.path.append(.privacy)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Link("Terms of Service", destination: URL.apiRootUrl.appending(path: "/legal/tos"))
            }
        }
    }
    
    @ViewBuilder
    private var privacy: some View {
        List {
            self.infoBlock(
                icon: "hand.raised",
                title: "No data is sold",
                subtitle: "Nothing you upload is served to anyone but yourself, and the people you choose to share them with."
            )
            self.infoBlock(
                icon: "eye.slash",
                title: "Privatizing images",
                subtitle: "When you don't want others to see your files via a link, use the private toggle when uploading or editing."
            )
            self.infoBlock(
                icon: "lock.doc",
                title: "Locking images",
                subtitle: "Add another layer of security by encrypting your image in the cloud with your chosen key. You can still share a link for people to use."
            )
        }
        .listStyle(.plain)
        .navigationTitle("Privacy is important")
        .toolbar {
            ToolbarItem {
                #if targetEnvironment(macCatalyst)
                Button("Agree") {
                    self.path.append(.mac)
                }
                #else
                Button("Agree & finish") {
                    self.dismiss()
                }
                #endif
            }
            ToolbarItem(placement: .bottomBar) {
                Link("Privacy Policy", destination: URL.apiRootUrl.appending(path: "/legal/privacy"))
            }
        }
    }
    
    #if targetEnvironment(macCatalyst)
    @ViewBuilder
    private var mac: some View {
        List {
            self.infoBlock(
                icon: "menubar.arrow.up.rectangle",
                title: "Menubar commands",
                subtitle: "Some commands are in the menubar instead of cluttering your primary interface."
            )
            self.infoBlock(
                icon: "command",
                title: "Keyboard shortcuts",
                subtitle: "Many controls can be interacted with using common keyboard shortcuts."
            )
            self.infoBlock(
                icon: "macwindow.on.rectangle",
                title: "Multi-window support",
                subtitle: "View different images and collections across multiple windows."
            )
        }
        .listStyle(.plain)
        .navigationTitle("Mac-specific features")
        .toolbar {
            ToolbarItem {
                Button("Finish") {
                    self.dismiss()
                }
            }
        }
    }
    #endif
    
    var body: some View {
        NavigationStack(path: self.$path) {
            self.summary
                .navigationDestination(for: WelcomeScreens.self) { screen in
                    switch screen {
                    case .tos:
                        self.tos
                    case .privacy:
                        self.privacy
                    #if targetEnvironment(macCatalyst)
                    case .mac:
                        self.mac
                    #endif
                    }
                }
        }
        .interactiveDismissDisabled(
            self.path.contains(where: { element in
                #if targetEnvironment(macCatalyst)
                element == .mac
                #else
                element == .privacy
                #endif
            })
        )
    }
}

#if DEBUG
struct AppWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        AppWelcomeView()
    }
}
#endif

struct AppWelcomeSheetModifier: ViewModifier {
    @AppStorage("hasPresentedWelcome") private var hasPresentedWelcome: Bool = false
    
    @State private var isPresented: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !self.hasPresentedWelcome {
                    self.isPresented = true
                }
            }
            .sheet(isPresented: self.$isPresented, onDismiss: {
                self.hasPresentedWelcome = true
            }) {
                AppWelcomeView()
            }
    }
}
