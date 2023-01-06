import GRDB
import SwiftUI

extension EnvironmentValues {
    private struct DatabaseQueueKey: EnvironmentKey {
        /// The default dbQueue is an empty in-memory database
        static var defaultValue: DatabaseQueue { try! DatabaseQueue() }
    }

    var dbQueue: DatabaseQueue {
        get { self[DatabaseQueueKey.self] }
        set { self[DatabaseQueueKey.self] = newValue }
    }
}
