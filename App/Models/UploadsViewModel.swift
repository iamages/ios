import SwiftUI

class UploadsViewModel: ObservableObject {
    @Published var selectedUploadContainer: UUID?
    @Published var uploadContainers: [IamagesUploadContainer] = []
    @Published var isBusy: Bool = false
    @Published var collection: IamagesCollection?
    
    func deleteUpload(id: UUID) {
        if let i = self.uploadContainers.firstIndex(where: { $0.id == id }) {
            withAnimation {
                if self.selectedUploadContainer == id {
                    self.selectedUploadContainer = nil
                }
                self.uploadContainers.remove(at: i)
            }
        }
    }
}
