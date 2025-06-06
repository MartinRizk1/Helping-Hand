import Foundation
import Combine

class PersistenceService {
    // Keys for UserDefaults
    private enum Keys {
        static let chatHistory = "chat_history"
        static let appOpenCount = "app_open_count"
        static let lastUsedDate = "last_used_date"
    }
    
    // MARK: - Chat History
    
    func saveChatHistory(_ messages: [ChatMessage]) {
        do {
            // Convert to data
            let encoder = JSONEncoder()
            let data = try encoder.encode(messages.map { ChatMessageDTO(from: $0) })
            
            // Save to UserDefaults
            UserDefaults.standard.set(data, forKey: Keys.chatHistory)
            print("Chat history saved: \(messages.count) messages")
        } catch {
            print("Failed to save chat history: \(error.localizedDescription)")
        }
    }
    
    func loadChatHistory() -> [ChatMessage] {
        guard let data = UserDefaults.standard.data(forKey: Keys.chatHistory) else {
            print("No chat history found")
            return []
        }
        
        do {
            // Decode from data
            let decoder = JSONDecoder()
            let dtos = try decoder.decode([ChatMessageDTO].self, from: data)
            
            // Convert DTOs to domain models
            return dtos.map { $0.toChatMessage() }
        } catch {
            print("Failed to load chat history: \(error.localizedDescription)")
            return []
        }
    }
    
    func clearChatHistory() {
        UserDefaults.standard.removeObject(forKey: Keys.chatHistory)
        print("Chat history cleared")
    }
    
    // MARK: - App Usage Statistics
    
    func incrementAppOpenCount() {
        let count = UserDefaults.standard.integer(forKey: Keys.appOpenCount)
        UserDefaults.standard.set(count + 1, forKey: Keys.appOpenCount)
        UserDefaults.standard.set(Date(), forKey: Keys.lastUsedDate)
    }
    
    func getAppOpenCount() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.appOpenCount)
    }
    
    func getLastUsedDate() -> Date? {
        return UserDefaults.standard.object(forKey: Keys.lastUsedDate) as? Date
    }
}

// Data Transfer Object for serialization
// This separates our persistence layer from our domain model
struct ChatMessageDTO: Codable {
    let content: String
    let isUser: Bool
    let timestamp: Date
    let locationResultIds: [String]?
    
    init(from message: ChatMessage) {
        self.content = message.content
        self.isUser = message.isUser
        self.timestamp = message.timestamp
        self.locationResultIds = message.locationResults?.map { $0.id.uuidString }
    }
    
    func toChatMessage() -> ChatMessage {
        // Note: We can't fully reconstruct location results from just IDs
        // In a real app, we would need a more sophisticated approach
        return ChatMessage(
            content: content,
            isUser: isUser,
            timestamp: timestamp,
            locationResults: nil
        )
    }
}
