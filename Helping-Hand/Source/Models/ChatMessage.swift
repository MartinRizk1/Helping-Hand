import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var locationResults: [LocationResult]?
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), locationResults: [LocationResult]? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.locationResults = locationResults
    }
}
