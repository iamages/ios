import SwiftUI

struct AboutSettingsView: View {
    @Binding var isBusy: Bool
    
    @ViewBuilder
    private var credits: some View {
        ScrollView {
            Group {
                if let creditsUrl = Bundle.main.url(forResource: "CREDITS", withExtension: "md"),
                   let creditsData = try? Data(contentsOf: creditsUrl),
                   let creditsText = String(data: creditsData, encoding: .utf8),
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

    
    var body: some View {
        Section {
            HStack {
                if let icon: UIImage = UIImage(named: "AppIcon") {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .scaledToFit()
                } else {
                    Image(systemName: "app.fill")
                }
                VStack(alignment: .leading) {
                    Text("Iamages")
                        .bold()
                    Text(verbatim: "\(Bundle.main.version) (\(Bundle.main.build))")
                }
                .lineLimit(1)
            }
        } header: {
        } footer: {
            Text(Bundle.main.copyright)
        }
        
        Section("Links") {
            AboutLinksView()
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
