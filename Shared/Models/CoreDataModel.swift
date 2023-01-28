import CoreData

class CoreDataModel: ObservableObject {
    let container = NSPersistentContainer(name: "Iamages")

    init() {
        self.container.persistentStoreDescriptions = [
            NSPersistentStoreDescription(
                url: FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.me.jkelol111.Iamages"
                )!.appendingPathComponent("Iamages.sqlite", conformingTo: .database)
            )
        ]
        
        self.container.loadPersistentStores { description, error in
            if let error {
                fatalError("Couldn't load store '\(description.debugDescription)': \(error.localizedDescription)")
            }
        }
    }
}
