import Foundation
import Combine
import CoreLocation
import OpenAI

class AIService {
    private let openAI: OpenAI
    private let categoryKeywords: [String: [String]] = [
        "restaurant": ["restaurant", "food", "eat", "dining", "lunch", "dinner", "breakfast", "cafe"],
        "hotel": ["hotel", "motel", "stay", "accommodation", "lodging"],
        "shopping": ["shop", "mall", "store", "retail", "market"],
        "entertainment": ["movie", "theatre", "entertainment", "fun", "activity"],
        "health": ["hospital", "doctor", "clinic", "medical", "pharmacy"],
        "transportation": ["transport", "bus", "train", "taxi", "station"]
    ]
    
    init() {
        self.openAI = OpenAI(apiToken: APIConfig.openAIApiKey)
    }
    
    func processUserQuery(_ query: String, location: String?) -> AnyPublisher<(String, String?), Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                return
            }
            
            let lowercasedQuery = query.lowercased()
            var category: String?
            var locationContext = ""
            
            // Detect category from query
            for (key, keywords) in self.categoryKeywords {
                if keywords.contains(where: lowercasedQuery.contains) {
                    category = key
                    break
                }
            }
            
            if let location = location {
                locationContext = " near coordinates: \(location)"
            }
            
            // Prepare the chat prompt
            let systemMessage = "You are a helpful assistant that provides location-based recommendations. Keep responses concise and focused on helping users find places."
            let userPrompt = query + (location != nil ? locationContext : "")
            
            let query = ChatQuery(model: .gpt3_5Turbo, messages: [
                Chat(role: .system, content: systemMessage),
                Chat(role: .user, content: userPrompt)
            ])
            
            Task {
                do {
                    let result = try await self.openAI.chats(query: query)
                    if let response = result.choices.first?.message.content {
                        await MainActor.run {
                            promise(.success((response, category)))
                        }
                    } else {
                        await MainActor.run {
                            promise(.failure(NSError(domain: "AIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response from AI"])))
                        }
                    }
                } catch {
                    // Fallback to default responses if API fails
                    await MainActor.run {
                        let fallbackResponse = self.getFallbackResponse(for: category, query: lowercasedQuery)
                        promise(.success((fallbackResponse + locationContext, category)))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func getFallbackResponse(for category: String?, query: String) -> String {
        if let category = category {
            switch category {
            case "restaurant":
                return "I'll find some great dining options near you. I'll show you restaurants with good ratings and reviews."
            case "hotel":
                return "Let me search for comfortable accommodations in the area. I'll consider factors like location and ratings."
            case "shopping":
                return "I'll help you find shopping locations nearby. I'll show you popular retail destinations."
            case "entertainment":
                return "I'll locate entertainment venues in your area. I'll include ratings and current activities if available."
            case "health":
                return "I'll find healthcare facilities near you. I'll prioritize showing you the closest options."
            case "transportation":
                return "I'll help you find transportation options in your area. I'll show you the nearest stations and stops."
            default:
                return "I'll search for relevant places near you based on your request."
            }
        } else if query.contains("hi") || query.contains("hello") {
            return "Hello! I can help you find nearby places. Try asking about restaurants, hotels, shops, or other places you'd like to find."
        } else {
            return "I can help you find local places and services. Try asking about restaurants, hotels, shopping, entertainment, or other specific places nearby!"
        }
    }
    
    func generateLocationQuery(for category: String) -> String {
        switch category {
        case "restaurant":
            return "restaurants"
        case "hotel":
            return "hotels"
        case "shopping":
            return "shopping centers"
        case "entertainment":
            return "entertainment venues"
        case "health":
            return "healthcare facilities"
        case "transportation":
            return "transportation stations"
        default:
            return category
        }
    }
}
