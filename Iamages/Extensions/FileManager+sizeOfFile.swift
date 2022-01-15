import Foundation

extension FileManager {
    func sizeOfFile(atPath path: String) -> Int? {
        guard let attributes = try? self.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.size] as? Int
    }
}
