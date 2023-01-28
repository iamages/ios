import SwiftUI

struct AboutSettingsView: View {
    @Binding var isBusy: Bool
    
    @ViewBuilder
    private var credits: some View {
        ScrollView {
            Group {
                if let creditsUrl = Bundle.main.url(forResource: "CREDITS", withExtension: "md"),
                   let creditsText = try? String(contentsOf: creditsUrl, encoding: .utf8),
                   let creditsMarkdown = try? AttributedString(
                        markdown: creditsText,
                        options: AttributedString.MarkdownParsingOptions(
                            interpretedSyntax: .inlineOnlyPreservingWhitespace
                        )
                   ) {
                    Text(creditsMarkdown)
                } else {
                    Text("We could not retrieve credits at the moment. Try again later.")
                }
            }
            .padding(.all, 6)
        }
        .navigationTitle("Credits")
        .onAppear {
            self.isBusy = true
        }
        .onDisappear {
            self.isBusy = false
        }
    }
    
    @ViewBuilder
    private var license: some View {
        ScrollView {
            Group {
                if let licenseUrl = Bundle.main.url(forResource: "LICENSE", withExtension: "txt"),
                   let licenseString = try? String(contentsOf: licenseUrl, encoding: .utf8)
                {
                    Text(licenseString)
                } else {
                    Text("We could not retrieve license at the moment. Try again later.")
                }
            }
            .padding(.all, 6)
        }
        .navigationTitle("License")
        .onAppear {
            self.isBusy = true
        }
        .onDisappear {
            self.isBusy = false
        }
    }

    
    var body: some View {
        Section {
            HStack {
                Group {
                    if let icon: UIImage = UIImage(named: "AppIcon") {
                        Image(uiImage: icon)
                            .resizable()
                            
                    } else {
                        Image(systemName: "app.fill")
                            .resizable()
                    }
                }
                .frame(width: 64, height: 64)
                .scaledToFit()
                #if !targetEnvironment(macCatalyst)
                .cornerRadius(256 / 6.4)
                #endif

                VStack(alignment: .leading) {
                    Text("Iamages")
                        .bold()
                    Text(verbatim: "\(Bundle.main.version) (\(Bundle.main.build))")
                }
            }
        } header: {
        } footer: {
            Text(Bundle.main.copyright)
        }
        
        Section("Links") {
            AboutLinksView()
            NavigationLink("License") {
                self.license
            }
            NavigationLink("Credits") {
                self.credits
            }
        }
    }
}

#if DEBUG
struct AboutSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSettingsView(isBusy: .constant(false))
    }
}
#endif
