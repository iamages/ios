struct Pagination: Codable {
    var query: String? = nil
    var lastID: String? = nil
    var limit: Int = 6
    
    enum CodingKeys: String, CodingKey {
        case query
        case lastID = "last_id"
        case limit
    }
}
