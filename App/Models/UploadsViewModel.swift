import SwiftUI

class UploadsViewModel: ObservableObject {
    @Published var selectedUploadContainer: UUID?
    @Published var uploadContainers: [IamagesUploadContainer] = []
    @Published var isBusy: Bool = false
    
    func deleteUpload(id: UUID) {
        guard let i = self.uploadContainers.firstIndex(where: { $0.id == id }) else {
            return
        }
        if self.selectedUploadContainer == id {
            withAnimation {
                self.selectedUploadContainer = nil
            }
        }
        withAnimation {
            self.uploadContainers.remove(at: i)
        }
    }
}
