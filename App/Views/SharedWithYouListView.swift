import SwiftUI

struct SharedWithYouListView: View {
    @EnvironmentObject private var splitViewModel: SplitViewModel
    
    @StateObject private var swViewModel = SWViewModel()
    
    @ViewBuilder
    private var list: some View {
        List {
            ForEach(self.swViewModel.highlightCenter.highlights, id: \.self) { highlight in
                
            }
        }
        .navigationDestination(for: IamagesCollection.ID.self) { id in
            
        }
    }
    
    var body: some View {
        Group {
            if self.swViewModel.highlightCenter.highlights.isEmpty {
                IconAndInformationView(
                    icon: "shared.with.you",
                    heading: "Nothing Shared with You",
                    subheading: "Iamages embed links sent to you via Messages will appear here."
                )
            } else {
                self.list
            }
        }
        .navigationTitle("Shared with You")
    }
}

struct SharedWithYouListView_Previews: PreviewProvider {
    static var previews: some View {
        SharedWithYouListView()
            .environmentObject(SplitViewModel())
    }
}
