import SwiftUI

struct ImagesGridView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var isLoginSheetPresented: Bool = false
    
    @ViewBuilder
    private var notLoggedIn: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.fill.questionmark")
                .font(.largeTitle)
            Text("Login required")
                .font(.title2)
                .bold()
            Button("Login/signup") {
                self.isLoginSheetPresented = true
            }
            .buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder
    private var imageGrid: some View {
        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
            
        }
    }
    
    var body: some View {
        Group {
            if self.viewModel.userInformation == nil {
                self.notLoggedIn
            } else {
                self.imageGrid
            }
        }
        .navigationTitle("Images")
        .sheet(isPresented: self.$isLoginSheetPresented) {
            LoginSheetView(isPresented: self.$isLoginSheetPresented)
        }
    }
}

#if DEBUG
struct ImagesListView_Previews: PreviewProvider {
    static var previews: some View {
        ImagesGridView()
            .environmentObject(ViewModel())
    }
}
#endif
