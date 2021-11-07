import SwiftUI

struct AboutView: View {
    @Binding var isAboutSheetPresented: Bool
    
    var body: some View {
        NavigationView {
            HStack {
                Image(uiImage: Bundle.main.icon ?? UIImage())
                Spacer()
                VStack(alignment: .leading) {
                    Text("Iamages")
                        .font(.largeTitle)
                        .bold()
                    Text("version \(Bundle.main.version)")
                        .font(.title3)
                    HelpLinksView()
                }
            }.navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.isAboutSheetPresented = false
                    }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }.padding()
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(isAboutSheetPresented: .constant(true))
    }
}
