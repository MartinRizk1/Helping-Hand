import Foundation
import Combine
import CoreLocation
import OpenAI

class AIService {
    private let openAI: OpenAI
    private let categoryKeywords: [String: [String]] = [
        "restaurant": ["restaurant", "food", "eat", "dining", "lunch", "dinner", "breakfast", "cafe", "chinese", "italian", "mexican", "thai", "japanese", "pizza", "burger", "sushi", "tacos", "coffee"],
        "hotel": ["hotel", "motel", "stay", "accommodation", "lodging", "inn", "resort", "bed and breakfast"],
        "shopping": ["shop", "mall", "store", "retail", "market", "grocery", "supermarket", "pharmacy", "clothing"],
        "entertainment": ["movie", "theatre", "entertainment", "fun", "activity", "cinema", "bowling", "arcade", "bar", "nightclub", "museum", "park"],
        "health": ["doctor", "hospital", "clinic", "pharmacy", "medical", "health", "dentist", "urgent care"]
    ]
    
    private let cuisineKeywords: [String: String] = [
        "chinese": "Chinese restaurants",
        "italian": "Italian restaurants",
        "mexican": "Mexican restaurants",
        "thai": "Thai restaurants",
        "japanese": "Japanese restaurants",
        "pizza": "Pizza places",
        "burger": "Burger restaurants",
        "sushi": "Sushi restaurants",
        "tacos": "Taco shops",
        "coffee": "Coffee shops and cafes"
    ]
    
    init() {
        let apiKey = APIConfig.openAIKey
        if apiKey.isEmpty || apiKey == "your-openai-api-key-here" {
            print("⚠️ OpenAI API key not configured - using fallback responses")
        }
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func processUserQuery(_ query: String, location: String?) -> AnyPublisher<(String, String?), Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                return
            }
            
            let lowercasedQuery = query.lowercased()
            var category: String?
            var specificSearchTerm: String?
            var locationContext = ""
            
            // Detect specific cuisine types first
            for (cuisine, searchTerm) in self.cuisineKeywords {
                if lowercasedQuery.contains(cuisine) {
                    category = "restaurant"
                    specificSearchTerm = searchTerm
                    break
                }
            }
            
            // If no specific cuisine found, detect general category
            if category == nil {
                for (key, keywords) in self.categoryKeywords {
                    if keywords.contains(where: lowercasedQuery.contains) {
                        category = key
                        break
                    }
                }
            }
            
            // Enhanced location context
            if let location = location {
                let coords = location.components(separatedBy: ",")
                if coords.count == 2 {
                    locationContext = " I am currently located at coordinates \(location). Please provide recommendations for places within walking or short driving distance."
                }
            }
            
            // Create enhanced system message with location awareness
            let systemMessage = """
            You are an intelligent location-based assistant that helps users find nearby places and services. 
            
            Your capabilities:
            - Analyze user queries to understand their specific needs
            - Provide helpful, contextual responses about local businesses and services
            - Give practical advice about finding places nearby
            - Be conversational and friendly while remaining helpful
            
            Guidelines:
            - Keep responses concise but informative (2-3 sentences)
            - When location is available, acknowledge the user's current area
            - Suggest what types of places will be shown in search results
            - Be encouraging and helpful in tone
            - If asked about specific cuisines (like "Chinese food"), mention you'll find those specific restaurants
            """
            
            // Enhanced user prompt with context
            let userPrompt = "\(query)\(locationContext)"
            
            let chatQuery = ChatQuery(
                model: "gpt-4o-mini", // Using GPT-4o mini for better understanding
                messages: [
                    Chat(role: .system, content: systemMessage),
                    Chat(role: .user, content: userPrompt)
                ]
            )
            
            Task {
                do {
                    // Check if API key is properly configured
                    let apiKey = APIConfig.openAIKey
                    if apiKey.isEmpty || apiKey == "your-openai-api-key-here" {
                        throw NSError(domain: "AIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
                    }
                    
                    print("🤖 Sending request to ChatGPT...")
                    let result = try await self.openAI.chats(query: chatQuery)
                    
                    if let response = result.choices.first?.message.content {
                        print("✅ Received ChatGPT response: \(response)")
                        await MainActor.run {
                            // Return the AI response with the detected category or specific search term
                            let searchCategory = specificSearchTerm != nil ? "restaurant" : category
                            promise(.success((response, searchCategory)))
                        }
                    } else {
                        await MainActor.run {
                            promise(.failure(NSError(domain: "AIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response from AI"])))
                        }
                    }
                } catch {
                    print("❌ ChatGPT API error: \(error.localizedDescription)")
                    // Enhanced fallback responses with location context
                    await MainActor.run {
                        let fallbackResponse = self.getEnhancedFallbackResponse(
                            for: query, 
                            category: category, 
                            hasLocation: location != nil
                        )
                        promise(.success((fallbackResponse, category)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getEnhancedFallbackResponse(for query: String, category: String?, hasLocation: Bool) -> String {
        let locationSuffix = hasLocation ? " based on your current location" : ""
        let prefix = hasLocation ? "Great! I can help you find " : "I can help you find "
        
        if let category = category {
            switch category {
            case "restaurant":
                return "\(prefix)restaurants and dining options\(locationSuffix). I'll search for great places to eat nearby!"
            case "hotel":
                return "\(prefix)hotels and accommodations\(locationSuffix). I'll find comfortable places to stay."
            case "shopping":
                return "\(prefix)shopping centers and stores\(locationSuffix). I'll locate the best shopping options nearby."
            case "entertainment":
                return "\(prefix)entertainment venues and activities\(locationSuffix). I'll find fun things to do in your area."
            case "health":
                return "\(prefix)healthcare facilities and medical services\(locationSuffix). I'll help you find medical care nearby."
            default:
                return "\(prefix)relevant places near you\(locationSuffix). I'll find what you're looking for!"
            }
        } else if query.contains("hi") || query.contains("hello") {
            return "Hello! I'm here to help you discover amazing places nearby. Try asking about restaurants, specific cuisines like 'Chinese food', hotels, shopping, or any other places you'd like to find!"
        } else {
            return "I can help you find local places and services\(locationSuffix). Try asking about restaurants, specific cuisines, hotels, shopping, entertainment, or other places you need!"
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
            return "medical facilities"
        default:
            return category
        }
    }
    
    func generateSpecificLocationQuery(for userQuery: String) -> String? {
        let lowercased = userQuery.lowercased()
        
        // Check for specific cuisines
        for (cuisine, searchTerm) in cuisineKeywords {
            if lowercased.contains(cuisine) {
                return searchTerm.lowercased()
            }
        }
        
        // Check for specific terms
        if lowercased.contains("coffee") { return "coffee shops" }
        if lowercased.contains("gas") { return "gas stations" }
        if lowercased.contains("pharmacy") { return "pharmacies" }
        if lowercased.contains("grocery") { return "grocery stores" }
        if lowercased.contains("bank") { return "banks" }
        
        return nil
    }
}
