enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
}

enum HTTPContentType: String {
    case text = "text/plain; charset=utf-8"
    case json = "application/json; charset=utf-8"
    case encodedForm = "application/x-www-form-urlencoded"
    case multipart = "multipart/form-data; boundary=iamages"
}
