import SwiftUI

struct UniversalDataImage: View {
    #if os(iOS)
    private let image: UIImage?
    #else
    private let image: NSImage?
    #endif
    
    init(data: Data) {
        #if os(iOS)
        var uiImage = UIImage(data: data)
        self.image = uiImage
        #else
        var nsImage = NSImage(data: data)
        self.image = nsImage
        #endif
    }
    
    @ViewBuilder
    private var error: some View {
        Image(systemName: "exclamationmark.octagon.fill")
            .font(.title2)
    }
    
    var body: some View {
        if let image {
            #if os(iOS)
            Image(uiImage: image)
                .resizable()
            #else
            Image(nsImage: image)
                .resizable()
            #endif
        } else {
            self.error
        }
    }
}

#if DEBUG
struct UniversalDataImage_Previews: PreviewProvider {
    static var previews: some View {
        UniversalDataImage(data: Data())
    }
}
#endif
