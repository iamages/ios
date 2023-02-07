import SwiftUI

struct QuerySuggestionsView: View {
    @Binding var suggestions: [String]
    
    var body: some View {
        ForEach(self.suggestions, id: \.self) { suggestion in
            Text(suggestion).searchCompletion(suggestion)
        }
    }
}

#if DEBUG
struct QuerySuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuerySuggestionsView(suggestions: .constant(["First", "Second"]))
    }
}
#endif
