import SwiftUI

struct NotLoggedInView: View {
    @EnvironmentObject private var viewModel: GlobalViewModel
    
    @State private var isLoginSheetPresented: Bool = false

    var body: some View {
        IconAndInformationView(
            icon: "person.fill.questionmark",
            heading: "Login required",
            additionalViews: AnyView(
                Button("Login/signup") {
                    self.isLoginSheetPresented = true
                }
                .buttonStyle(.bordered)
            )
        )
        .sheet(isPresented: self.$isLoginSheetPresented) {
            LoginSheetView()
        }
    }
}

#if DEBUG
struct NotLoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        NotLoggedInView()
    }
}
#endif
