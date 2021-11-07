import Foundation

class APICommunication {
    private var apiRoot: String = "http://localhost:9999/iamages/api/v3"
    
    private func makeRequest(_ endpoint: String, method: String, body: AnyHashable?) async {
        
    }
    
    func get_feed_latest () async {
        await makeRequest("/feed/latest", method: "GET", body: nil)
    }
    
    func get_feed_popular () async {
        
    }
    
    func get_feed_random () async {
        
    }
}
